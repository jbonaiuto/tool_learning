import os
import matplotlib
import transplant
from tridesclous.tools import get_pairs_over_threshold

matplotlib.use('Agg')
import shutil
import sys
import time
from datetime import datetime

import pyqtgraph as pg
import matplotlib.pyplot as plt
plt.ioff()
import numpy as np
import gc

import tridesclous as tdc
from neo.rawio import IntanRawIO, RawBinarySignalRawIO
from tridesclous import DataIO, CatalogueConstructor, CatalogueWindow

from spike_sorting.plot import plot_noise, plot_waveforms, plot_cluster_waveforms

from pathos.multiprocessing import ProcessingPool as Pool

# This is for selecting a GPU
for e in tdc.get_cl_device_list():
    print(e)
tdc.set_default_cl_device(platform_index=0, device_index=0)

arrays = ['F1', 'F5hand', 'F5mouth', '46v/12r', '45a', 'F2']
n_channels_per_array=32

def preprocess_array(array_idx, output_dir, total_duration):
    dataio = DataIO(dirname=output_dir, ch_grp=array_idx)
    fullchain_kargs = {
        'duration': total_duration,
        'preprocessor': {
            'highpass_freq': 400.,
            'lowpass_freq': 5000.,
            'smooth_size': 0,
            'common_ref_removal': True,
            'chunksize': 32768,
            'lostfront_chunksize': 0,
            'signalpreprocessor_engine': 'numpy',
        }
    }
    cc = CatalogueConstructor(dataio=dataio, chan_grp=array_idx)
    p = {}
    p.update(fullchain_kargs['preprocessor'])
    cc.set_preprocessor_params(**p)
    # TODO offer noise esatimation duration somewhere
    noise_duration = min(10., fullchain_kargs['duration'],
                         dataio.get_segment_length(seg_num=0) / dataio.sample_rate * .99)
    # ~ print('noise_duration', noise_duration)
    t1 = time.perf_counter()
    cc.estimate_signals_noise(seg_num=0, duration=noise_duration)
    t2 = time.perf_counter()
    print('estimate_signals_noise', t2 - t1)
    t1 = time.perf_counter()
    cc.run_signalprocessor(duration=fullchain_kargs['duration'], detect_peak=False)
    t2 = time.perf_counter()
    print('run_signalprocessor', t2 - t1)


def compute_array_catalogue(array_idx, preprocess_dir, subject, recording_date, n_segments, total_duration,
                            cluster_merge_threshold):
    output_dir = os.path.join('/data/tool_learning/spike_sorting/', subject, recording_date, 'array_%d' % array_idx)
    if os.path.exists(output_dir):
        # remove is already exists
        shutil.rmtree(output_dir)
    # Compute total duration (want to use all data for clustering)
    data_file_names = []
    for seg in range(n_segments):
        data_file_names.append(
            os.path.join(preprocess_dir, 'channel_group_%d' % array_idx, 'segment_%d' % seg, 'processed_signals.raw'))
    dataio = DataIO(dirname=output_dir)
    dataio.set_data_source(type='RawData', filenames=data_file_names, dtype='float32', sample_rate=30000,
                           total_channel=32)
    dataio.datasource.bit_to_microVolt = 0.195
    for ch_grp in range(n_channels_per_array):
        dataio.add_one_channel_group(channels=[ch_grp], chan_grp=ch_grp)
    figure_out_dir = os.path.join(output_dir, 'figures')
    os.mkdir(figure_out_dir)
    for ch_grp in range(n_channels_per_array):
        print(ch_grp)
        cc = CatalogueConstructor(dataio=DataIO(dirname=output_dir, ch_grp=ch_grp), chan_grp=ch_grp)

        fullchain_kargs = {
            'duration': total_duration,
            'preprocessor': {
                'highpass_freq': None,
                'lowpass_freq': None,
                'smooth_size': 0,
                'common_ref_removal': False,
                'chunksize': 32768,
                'lostfront_chunksize': 0,
                'signalpreprocessor_engine': 'numpy',
            },
            'peak_detector': {
                'peakdetector_engine': 'numpy',
                'peak_sign': '-',
                'relative_threshold': 2.,
                'peak_span': 0.0002,
            },
            'noise_snippet': {
                'nb_snippet': 300,
            },
            'extract_waveforms': {
                'n_left': -20,
                'n_right': 30,
                'mode': 'all',
                'nb_max': 2000000,
                'align_waveform': False,
            },
            'clean_waveforms': {
                'alien_value_threshold': 100.,
            },
        }
        feat_method = 'pca_by_channel'
        feat_kargs = {'n_components_by_channel': 5}
        clust_method = 'sawchaincut'
        clust_kargs = {
            'max_loop': 1000,
            'nb_min': 20,
            'break_nb_remain': 30,
            'kde_bandwith': 0.01,
            'auto_merge_threshold': 0.01,
            'print_debug': False
        }

        p = {}
        p.update(fullchain_kargs['preprocessor'])
        p.update(fullchain_kargs['peak_detector'])
        cc.set_preprocessor_params(**p)

        noise_duration = min(10., fullchain_kargs['duration'],
                             dataio.get_segment_length(seg_num=0) / dataio.sample_rate * .99)
        # ~ print('noise_duration', noise_duration)
        t1 = time.perf_counter()
        cc.estimate_signals_noise(seg_num=0, duration=noise_duration)
        t2 = time.perf_counter()
        print('estimate_signals_noise', t2 - t1)

        t1 = time.perf_counter()
        cc.run_signalprocessor(duration=fullchain_kargs['duration'])
        t2 = time.perf_counter()
        print('run_signalprocessor', t2 - t1)

        t1 = time.perf_counter()
        cc.extract_some_waveforms(**fullchain_kargs['extract_waveforms'])
        t2 = time.perf_counter()
        print('extract_some_waveforms', t2 - t1)

        fname = 'chan_%d_init_waveforms.png' % ch_grp
        fig = plot_waveforms(np.squeeze(cc.some_waveforms).T)
        fig.savefig(os.path.join(figure_out_dir, fname))
        plt.close(fig)

        t1 = time.perf_counter()
        # ~ duration = d['duration'] if d['limit_duration'] else None
        # ~ d['clean_waveforms']
        cc.clean_waveforms(**fullchain_kargs['clean_waveforms'])
        t2 = time.perf_counter()
        print('clean_waveforms', t2 - t1)

        fname = 'chan_%d_clean_waveforms.png' % ch_grp
        fig = plot_waveforms(np.squeeze(cc.some_waveforms).T)
        fig.savefig(os.path.join(figure_out_dir, fname))
        plt.close(fig)

        # ~ t1 = time.perf_counter()
        # ~ n_left, n_right = cc.find_good_limits(mad_threshold = 1.1,)
        # ~ t2 = time.perf_counter()
        # ~ print('find_good_limits', t2-t1)

        t1 = time.perf_counter()
        cc.extract_some_noise(**fullchain_kargs['noise_snippet'])
        t2 = time.perf_counter()
        print('extract_some_noise', t2 - t1)

        # ~ print(cc)

        # Plot noise
        fname = 'chan_%d_noise.png' % ch_grp
        fig = plot_noise(cc)
        fig.savefig(os.path.join(figure_out_dir, fname))
        plt.close(fig)

        t1 = time.perf_counter()
        cc.extract_some_features(method=feat_method, **feat_kargs)
        t2 = time.perf_counter()
        print('project', t2 - t1)

        t1 = time.perf_counter()
        cc.find_clusters(method=clust_method, **clust_kargs)
        t2 = time.perf_counter()
        print('find_clusters', t2 - t1)

        # Remove empty clusters
        cc.trash_small_cluster(n=0)

        if cc.centroids_median is None:
            cc.compute_all_centroid()

        fname = 'chan_%d_init_clusters.png' % ch_grp
        cluster_labels = cc.clusters['cluster_label']
        fig = plot_cluster_waveforms(cc, cluster_labels)
        fig.savefig(os.path.join(figure_out_dir, fname))
        plt.close(fig)

        t1 = time.perf_counter()
        if len(np.where(cc.cluster_labels > -1)[0]):
            # Auto-merge clusters
            cluster_removed = True
            while cluster_removed:
                cc.compute_cluster_similarity()

                nn_cluster_labels = cc.cluster_labels[cc.cluster_labels > -1]

                pairs = get_pairs_over_threshold(cc.cluster_similarity, nn_cluster_labels,
                                                 cluster_merge_threshold)
                if len(pairs) > 0:
                    (k1, k2) = pairs[0]

                    idx1 = np.where(cc.cluster_labels == k1)[0][0]
                    idx2 = np.where(cc.cluster_labels == k2)[0][0]

                    cluster_label1 = cc.clusters['cluster_label'][idx1]
                    cluster_label2 = cc.clusters['cluster_label'][idx2]
                    similarity = cc.cluster_similarity[np.where(nn_cluster_labels == k1)[0][0],
                                                       np.where(nn_cluster_labels == k2)[0][0]]
                    title = 'Amplitude in MAD (STD) ratio, similarity=%.3f' % similarity

                    fname = 'chan_%d_merge_%d_%d.png' % (ch_grp, cluster_label1, cluster_label2)
                    fig.savefig(os.path.join(figure_out_dir, fname))
                    plt.close(fig)
                    fig = plot_cluster_waveforms(cc, [cluster_label1, cluster_label2], title=title)
                    fig.savefig(os.path.join(figure_out_dir, fname))
                    plt.close(fig)

                    print('auto_merge', cluster_label1, 'with', cluster_label2)
                    mask = cc.all_peaks['cluster_label'] == k2
                    cc.all_peaks['cluster_label'][mask] = k1
                    cc.remove_one_cluster(k2)
                else:
                    cluster_removed = False
        t2 = time.perf_counter()
        print('merge_clusters', t2 - t1)

        # order cluster by waveforms rms
        cc.order_clusters(by='waveforms_rms')

        # put label 0 to trash
        #    mask = catalogueconstructor.all_peaks['cluster_label'] == 0
        #    catalogueconstructor.all_peaks['cluster_label'][mask] = -1
        #    catalogueconstructor.on_new_cluster()

        # save the catalogue
        cc.make_catalogue_for_peeler()

        gc.collect()


# p = Pool(ncpus=4)

def preprocess_data(subject, recording_date):
    matlab = transplant.Matlab()
    matlab.addpath('/home/ferrarilab/tool_learning/src/matlab')
    matlab.preprocessSpikeData(subject, recording_date)
    matlab.exit()

    base_path=os.path.join('/data/tool_learning/spike_sorting/', subject, recording_date)
    if not os.path.exists(base_path):
        os.mkdir(base_path)
    output_dir = os.path.join('/data/tool_learning/spike_sorting/', subject, recording_date, 'preprocess')
    if os.path.exists(output_dir):
        # remove is already exists
        shutil.rmtree(output_dir)

    data_dir = os.path.join('/data/tool_learning/recordings/rhd2000/', subject, recording_date)
    (data_file_names, total_duration) = read_and_sort_data_files(data_dir, preprocessed=True)

    ## Setup DataIO
    dataio = DataIO(dirname=output_dir)
    # dataio.set_data_source(type='RawData', filenames=data_file_names, dtype='float32', sample_rate=30000, total_channel=192)
    dataio.set_data_source(type='Intan', filenames=data_file_names)

    # Setup channel groups
    for array_idx in range(len(arrays)):
        dataio.add_one_channel_group(channels=range(array_idx * n_channels_per_array, (array_idx + 1) * n_channels_per_array), chan_grp=array_idx)

    print(dataio)

    # arg1 = range(len(arrays))
    # arg2 = [output_dir for array_idx in range(len(arrays))]
    # arg3 = [total_duration for array_idx in range(len(arrays))]
    # p.map(preprocess_array, arg1, arg2, arg3)

    for array_idx in range(len(arrays)):
        print(array_idx)
        preprocess_array(array_idx, output_dir, total_duration)


def compute_catalogue(subject, recording_date, n_segments, total_duration, cluster_merge_threshold=0.7):

    preprocess_dir=os.path.join('/data/tool_learning/spike_sorting/', subject, recording_date,'preprocess')
    if os.path.exists(preprocess_dir):

        # arg1=range(len(arrays))
        # arg2=[preprocess_dir for array_idx in range(len(arrays))]
        # arg3 = [subject for array_idx in range(len(arrays))]
        # arg4 = [recording_date for array_idx in range(len(arrays))]
        # arg5 = [n_segments for array_idx in range(len(arrays))]
        # arg6 = [total_duration for array_idx in range(len(arrays))]
        # arg7 = [cluster_merge_threshold for array_idx in range(len(arrays))]
        # p.map(compute_array_catalogue, arg1, arg2, arg3, arg4, arg5, arg6, arg7)

        for array_idx in range(len(arrays)):
            compute_array_catalogue(array_idx, preprocess_dir, subject, recording_date, n_segments, total_duration,
                                    cluster_merge_threshold)


def open_cataloguewindow(dataio, chan_grp):
    catalogueconstructor = CatalogueConstructor(dataio=dataio, chan_grp=chan_grp)

    app = pg.mkQApp()
    win = CatalogueWindow(catalogueconstructor)
    win.show()

    app.exec_()


def read_and_sort_data_files(data_dir, preprocessed=False):
    total_duration = 0.0
    data_file_names = []
    for x in os.listdir(data_dir):
        if os.path.splitext(x)[1] == '.rhd':
            if not preprocessed or os.path.exists(os.path.join(data_dir, '%s_rec_signal.mat' % os.path.splitext(x)[0])):
                data_file_names.append(os.path.join(data_dir, x))
                # data = RawBinarySignalRawIO(os.path.join(data_dir, x),dtype='float32',sampling_rate=30000,nb_channel=192)
                data = IntanRawIO(os.path.join(data_dir, x))
                data.parse_header()
                # Add duration of this trial to total duration
                total_duration += data.get_signal_size(0, 0, [0]) * 1 / data.get_signal_sampling_rate([0])
    data_file_times = []
    for idx, evt_file in enumerate(data_file_names):
        fname = os.path.split(evt_file)[-1]
        fparts = fname.split('_')
        filedate = datetime.strptime('%s %s' % (fparts[4], fparts[5].split('.')[0]), '%y%m%d %H%M%S')
        data_file_times.append(filedate)
    data_file_names = [x for _, x in sorted(zip(data_file_times, data_file_names))]
    return (data_file_names,total_duration)


if __name__=='__main__':
    subject=sys.argv[1]
    recording_date=sys.argv[2]
    display_catalogue=sys.argv[3] in ['true', 'True','1']
    preprocess=True
    if len(sys.argv)>4:
        preprocess=sys.argv[4] in ['true','True','1']

    data_dir = os.path.join('/data/tool_learning/recordings/rhd2000/', subject, recording_date)
    print(data_dir)
    if os.path.exists(data_dir):
        # Compute total duration (want to use all data for clustering)
        (data_file_names,total_duration)=read_and_sort_data_files(data_dir, preprocessed=False)

        if os.path.exists(data_dir) and len(data_file_names) > 0:

            if preprocess:
                print('Preprocessing')
                preprocess_data(subject, recording_date)

            (data_file_names, total_duration) = read_and_sort_data_files(data_dir, preprocessed=True)

            compute_catalogue(subject, recording_date, len(data_file_names), total_duration)
