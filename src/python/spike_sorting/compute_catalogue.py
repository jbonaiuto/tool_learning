import json
import os
import matplotlib
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

from config import read_config

cfg = read_config()

# This is for selecting a GPU
# for e in tdc.get_cl_device_list():
#     print(e)
# tdc.set_default_cl_device(platform_index=0, device_index=0)


def preprocess_array(array_idx, output_dir, total_duration):
    dataio = DataIO(dirname=output_dir, ch_grp=array_idx)
    fullchain_kargs = {
        'duration': total_duration,
        'preprocessor': {
            'highpass_freq': 250.,
            'lowpass_freq': 3000.,
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


def compute_array_catalogue(array_idx, preprocess_dir, subject, recording_date, data_files,
                            cluster_merge_threshold):
    # If data exists for this array
    if os.path.exists(os.path.join(preprocess_dir, 'channel_group_%d' % array_idx, 'catalogue_constructor')):
        output_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, recording_date, 'array_%d' % array_idx)
        if os.path.exists(output_dir):
            # remove is already exists
            shutil.rmtree(output_dir)
        # Compute total duration (want to use all data for clustering)
        data_file_names = []
        for seg in range(len(data_files)):
            data_file_names.append(
                os.path.join(preprocess_dir, 'channel_group_%d' % array_idx, 'segment_%d' % seg,
                             'processed_signals.raw'))

        dataio = DataIO(dirname=output_dir)
        dataio.set_data_source(type='RawData', filenames=data_file_names, dtype='float32',
                               sample_rate=cfg['intan_srate'],
                               total_channel=cfg['n_channels_per_array'])
        dataio.datasource.bit_to_microVolt = 0.195
        for ch_grp in range(cfg['n_channels_per_array']):
            dataio.add_one_channel_group(channels=[ch_grp], chan_grp=ch_grp)

        total_duration = np.sum([x['duration'] for x in data_files])

        figure_out_dir = os.path.join(output_dir, 'figures')
        os.mkdir(figure_out_dir)
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
                'auto_merge_threshold': 2.,
                'print_debug': False
                # 'max_loop': 1000,
                # 'nb_min': 20,
                # 'break_nb_remain': 30,
                # 'kde_bandwith': 0.01,
                # 'auto_merge_threshold': cluster_merge_threshold,
                # 'print_debug': False

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
            fig.clf()
            plt.close()

            t1 = time.perf_counter()
            # ~ duration = d['duration'] if d['limit_duration'] else None
            # ~ d['clean_waveforms']
            cc.clean_waveforms(**fullchain_kargs['clean_waveforms'])
            t2 = time.perf_counter()
            print('clean_waveforms', t2 - t1)

            fname = 'chan_%d_clean_waveforms.png' % ch_grp
            fig = plot_waveforms(np.squeeze(cc.some_waveforms).T)
            fig.savefig(os.path.join(figure_out_dir, fname))
            fig.clf()
            plt.close()

            # ~ t1 = time.perf_counter()
            # ~ n_left, n_right = cc.find_good_limits(mad_threshold = 1.1,)
            # ~ t2 = time.perf_counter()
            # ~ print('find_good_limits', t2-t1)

            t1 = time.perf_counter()
            cc.extract_some_noise(**fullchain_kargs['noise_snippet'])
            t2 = time.perf_counter()
            print('extract_some_noise', t2 - t1)

            # Plot noise
            fname = 'chan_%d_noise.png' % ch_grp
            fig = plot_noise(cc)
            fig.savefig(os.path.join(figure_out_dir, fname))
            fig.clf()
            plt.close()

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

            # order cluster by waveforms rms
            cc.order_clusters(by='waveforms_rms')

            fname = 'chan_%d_init_clusters.png' % ch_grp
            cluster_labels = cc.clusters['cluster_label']
            fig = plot_cluster_waveforms(cc, cluster_labels)
            fig.savefig(os.path.join(figure_out_dir, fname))
            fig.clf()
            plt.close()

            # save the catalogue
            cc.make_catalogue_for_peeler()

            gc.collect()


# p = Pool(ncpus=4)

def preprocess_data(subject, recording_date, data_files):
    output_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, recording_date, 'preprocess')
    if os.path.exists(output_dir):
        # remove is already exists
        shutil.rmtree(output_dir)

    ## Setup DataIO
    dataio = DataIO(dirname=output_dir)
    dataio.set_data_source(type='Intan', filenames=[x['fname'] for x in data_files])

    # Setup channel groups
    arrays_recorded = []
    grp_idx = 0
    for array_idx in range(len(cfg['arrays'])):
        first_chan = ''
        if array_idx == 0:
            first_chan = 'A-000'
        elif array_idx == 1:
            first_chan = 'A-032'
        elif array_idx == 2:
            first_chan = 'B-000'
        elif array_idx == 3:
            first_chan = 'B-032'
        elif array_idx == 4:
            first_chan = 'C-000'
        elif array_idx == 5:
            first_chan = 'C-032'
        found = False
        for i in range(len(dataio.datasource.sig_channels)):
            if dataio.datasource.sig_channels[i][0] == first_chan:
                found = True
                break

        chan_range = []
        if found:
            chan_range = range(grp_idx * cfg['n_channels_per_array'], (grp_idx + 1) * cfg['n_channels_per_array'])
            grp_idx = grp_idx + 1
            arrays_recorded.append(array_idx)
        dataio.add_one_channel_group(channels=chan_range, chan_grp=array_idx)

    print(dataio)

    total_duration = np.sum([x['duration'] for x in data_files])
    for array_idx in arrays_recorded:
        print(array_idx)
        preprocess_array(array_idx, output_dir, total_duration)


def compute_catalogue(subject, recording_date, data_files, cluster_merge_threshold=0.8):
    preprocess_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, recording_date, 'preprocess')
    if os.path.exists(preprocess_dir):

        for array_idx in range(len(cfg['arrays'])):
            compute_array_catalogue(array_idx, preprocess_dir, subject, recording_date, data_files,
                                    cluster_merge_threshold)


def open_cataloguewindow(dataio, chan_grp):
    catalogueconstructor = CatalogueConstructor(dataio=dataio, chan_grp=chan_grp)

    app = pg.mkQApp()
    win = CatalogueWindow(catalogueconstructor)
    win.show()

    app.exec_()


def read_and_sort_data_files(data_dir, recording_date):
    data_files = []
    data_datetimes = []

    for x in os.listdir(data_dir):
        (path, root) = os.path.split(x)
        (prefix, ext) = os.path.splitext(root)

        if ext == '.rhd':
            print(x)
            try:
                file_info = {}
                file_info['fname'] = os.path.join(data_dir, x)
                data = IntanRawIO(file_info['fname'])
                data.parse_header()
                file_info['duration'] = data.get_signal_size(0, 0, [0]) * 1 / data.get_signal_sampling_rate([0])

                assert (datetime.strptime(prefix.split('_')[-2], '%y%m%d') == datetime.strptime(recording_date, '%d.%m.%y'))
                data_datetimes.append(datetime.strptime(prefix.split('_')[-1], '%H%M%S'))
                task = '_'.join(prefix.split('_')[1:-2])
                if task == 'visual_task_stage_1-2':
                    task = 'visual_task_stage1-2'
                file_info['task'] = task
                data_files.append(file_info)
            except:
                print('Error reading %s' % x)
    data_files = [x for _, x in sorted(zip(data_datetimes, data_files))]
    return data_files


if __name__ == '__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    display_catalogue = sys.argv[3] in ['true', 'True', '1']
    preprocess = True
    if len(sys.argv) > 4:
        preprocess = sys.argv[4] in ['true', 'True', '1']

    data_dir = None
    for x in cfg['intan_data_dirs']:
        if os.path.exists(os.path.join(x, subject, recording_date)):
            data_dir = os.path.join(x, subject, recording_date)

    print(data_dir)
    if data_dir is not None and os.path.exists(data_dir):

        base_path = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, recording_date)
        if not os.path.exists(base_path):
            os.mkdir(base_path)

        json_fname = os.path.join(base_path, 'intan_files.json')

        if os.path.exists(json_fname):
            with open(json_fname, 'r') as infile:
                data_files = json.load(infile)
        else:
            # Compute total duration (want to use all data for clustering)
            data_files = read_and_sort_data_files(data_dir, recording_date)

            if len(data_files) > 0:
                with open(json_fname, 'w') as outfile:
                    json.dump(data_files, outfile)

        if len(data_files) > 0:
            if preprocess:
                print('Preprocessing')
                preprocess_data(subject, recording_date, data_files)
            compute_catalogue(subject, recording_date, data_files)
