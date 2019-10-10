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
from neo.rawio import IntanRawIO
from tridesclous import DataIO, CatalogueConstructor, CatalogueWindow

# This is for selecting a GPU
for e in tdc.get_cl_device_list():
    print(e)
tdc.set_default_cl_device(platform_index=0, device_index=0)

from config import read_config

cfg = read_config()

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


def compute_array_catalogue(array_idx, preprocess_dir, subject, recording_date, n_segments, total_duration):
    output_dir = os.path.join(cfg['multi_unit_spike_sorting_dir'], subject, recording_date, 'multiunit', 'array_%d' % array_idx)
    if os.path.exists(output_dir):
        # remove is already exists
        shutil.rmtree(output_dir)
    # Compute total duration (want to use all data for clustering)
    data_file_names = []
    for seg in range(n_segments):
        data_file_names.append(
            os.path.join(preprocess_dir, 'channel_group_%d' % array_idx, 'segment_%d' % seg, 'processed_signals.raw'))
    dataio = DataIO(dirname=output_dir)
    dataio.set_data_source(type='RawData', filenames=data_file_names, dtype='float32', sample_rate=cfg['intan_srate'],
                           total_channel=cfg['n_channels_per_array'])
    dataio.datasource.bit_to_microVolt = 0.195
    for ch_grp in range(cfg['n_channels_per_array']):
        dataio.add_one_channel_group(channels=[ch_grp], chan_grp=ch_grp)
    for ch_grp in range(cfg['n_channels_per_array']):
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

        t1 = time.perf_counter()
        cc.clean_waveforms(**fullchain_kargs['clean_waveforms'])
        t2 = time.perf_counter()
        print('clean_waveforms', t2 - t1)

        t1 = time.perf_counter()
        cc.extract_some_noise(**fullchain_kargs['noise_snippet'])
        t2 = time.perf_counter()
        print('extract_some_noise', t2 - t1)

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

        if len(np.where(cc.cluster_labels > -1)[0]):
            # Auto-merge clusters
            cluster_removed = True
            while cluster_removed:
                cc.compute_cluster_similarity()

                nn_cluster_labels = cc.cluster_labels[cc.cluster_labels > -1]

                pairs = get_pairs_over_threshold(cc.cluster_similarity, nn_cluster_labels, 0)
                if len(pairs) > 0:
                    (k1, k2) = pairs[0]

                    idx1 = np.where(cc.cluster_labels == k1)[0][0]
                    idx2 = np.where(cc.cluster_labels == k2)[0][0]

                    cluster_label1 = cc.clusters['cluster_label'][idx1]
                    cluster_label2 = cc.clusters['cluster_label'][idx2]

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

        # save the catalogue
        cc.make_catalogue_for_peeler()

        gc.collect()


def preprocess_data(subject, recording_date):
    base_path=os.path.join(cfg['multi_unit_spike_sorting_dir'], subject, recording_date)
    if not os.path.exists(base_path):
        os.mkdir(base_path)
    output_dir = os.path.join(base_path, 'preprocess')
    if os.path.exists(output_dir):
        # remove is already exists
        shutil.rmtree(output_dir)

    data_dir = os.path.join(cfg['intan_data_dir'], subject, recording_date)
    (data_file_names, total_duration) = read_and_sort_data_files(data_dir)

    ## Setup DataIO
    dataio = DataIO(dirname=output_dir)
    # dataio.set_data_source(type='RawData', filenames=data_file_names, dtype='float32', sample_rate=30000, total_channel=192)
    dataio.set_data_source(type='Intan', filenames=data_file_names)

    # Setup channel groups
    for array_idx in range(len(cfg['arrays'])):
        dataio.add_one_channel_group(channels=range(array_idx * cfg['n_channels_per_array'], (array_idx + 1) * cfg['n_channels_per_array']), chan_grp=array_idx)

    print(dataio)

    for array_idx in range(len(cfg['arrays'])):
        print(array_idx)
        preprocess_array(array_idx, output_dir, total_duration)


def compute_catalogue(subject, recording_date, n_segments, total_duration):

    preprocess_dir=os.path.join(cfg['multi_unit_spike_sorting_dir'], subject, recording_date,'preprocess')
    if os.path.exists(preprocess_dir):

        output_dir = os.path.join(cfg['multi_unit_spike_sorting_dir'], subject, recording_date, 'multiunit')
        if not os.path.exists(output_dir):
            os.mkdir(output_dir)

        for array_idx in range(len(cfg['arrays'])):
            compute_array_catalogue(array_idx, preprocess_dir, subject, recording_date, n_segments, total_duration)


def open_cataloguewindow(dataio, chan_grp):
    catalogueconstructor = CatalogueConstructor(dataio=dataio, chan_grp=chan_grp)

    app = pg.mkQApp()
    win = CatalogueWindow(catalogueconstructor)
    win.show()

    app.exec_()


def read_and_sort_data_files(data_dir):
    total_duration = 0.0
    data_file_names = []
    for x in os.listdir(data_dir):
        if os.path.splitext(x)[1] == '.rhd':
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
        filedate = datetime.strptime('%s %s' % (fparts[-2], fparts[-1].split('.')[0]), '%y%m%d %H%M%S')
        data_file_times.append(filedate)
    data_file_names = [x for _, x in sorted(zip(data_file_times, data_file_names))]
    return (data_file_names,total_duration)


if __name__=='__main__':
    subject=sys.argv[1]
    recording_date=sys.argv[2]
    display_catalogue=sys.argv[3] in ['true', 'True','1']

    data_dir = os.path.join(cfg['intan_data_dir'], subject, recording_date)
    print(data_dir)
    if os.path.exists(data_dir):
        # Compute total duration (want to use all data for clustering)
        (data_file_names,total_duration)=read_and_sort_data_files(data_dir)

        if os.path.exists(data_dir) and len(data_file_names) > 0:

            preprocess_dir = os.path.join(cfg['multi_unit_spike_sorting_dir'], subject, recording_date, 'preprocess')
            if not os.path.exists(preprocess_dir):
                print('Preprocessing')
                preprocess_data(subject, recording_date)

            compute_catalogue(subject, recording_date, len(data_file_names), np.min([2000, total_duration]))
