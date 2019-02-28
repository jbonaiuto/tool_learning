import matplotlib
matplotlib.use('Agg')
import os
import shutil
import sys
import time
from datetime import datetime

import pyqtgraph as pg
import matplotlib.pyplot as plt
plt.ioff()
import numpy as np
import transplant

import tridesclous as tdc
from neo.rawio import IntanRawIO, RawBinarySignalRawIO
from tridesclous import DataIO, CatalogueConstructor, median_mad, CatalogueWindow

# This is for selecting a GPU
from tridesclous.tools import get_pairs_over_threshold

for e in tdc.get_cl_device_list():
    print(e)
tdc.set_default_cl_device(platform_index=0, device_index=0)

def compute_catalogue(dataio, chan_grp, total_duration, out_path, voltage_threshold=3, cluster_merge_threshold=0.7, preprocess=True,
                      extract_waveforms=True, extract_features=True, find_clusters=True, postprocess=True):

    # time limits of waveform around threshold crossing
    n_left=-10
    n_right=25

    ## Preprocess data
    catalogueconstructor = CatalogueConstructor(dataio=dataio, chan_grp=chan_grp)

    if preprocess:
        catalogueconstructor.set_preprocessor_params(chunksize=32768,
                                                     # signal preprocessor
                                                     highpass_freq=0,
                                                     lowpass_freq=5000,
                                                     smooth_size=0,
                                                     # Remove common reference (needed when there is an artifact on all channels
                                                     common_ref_removal=False,
                                                     lostfront_chunksize=0,
                                                     signalpreprocessor_engine='opencl',

                                                     # peak detector
                                                     peakdetector_engine='opencl',
                                                     peak_sign='-',
                                                     # Threshold units are in MAD
                                                     # magnitude 1 = 1 mad = 1 robust sd = 68% of the noise
                                                     # magnitude 2 = 2 mad = 2 robust sd = 95 % of the noise
                                                     # magnitude 3 = 3 mad = 3 robust sd = 99.7% of the noise
                                                     relative_threshold=voltage_threshold,
                                                     # Min distance between extrema (in seconds)
                                                     peak_span=0.0002
                                                     )

        # Estimate the median and mad of noise on a small chunk of filtered signals
        # This compute medians and mad of each channel.
        # TODO: check how much this changes if we use different segments
        noise_duration = min(10., total_duration, dataio.get_segment_length(seg_num=0) / dataio.sample_rate * .99)
        t1 = time.perf_counter()
        catalogueconstructor.estimate_signals_noise(seg_num=0, duration=noise_duration)
        t2 = time.perf_counter()
        print('estimate_signals_noise', t2 - t1)
        print(catalogueconstructor.signals_medians)
        print(catalogueconstructor.signals_mads)

        # Run the main loop: signal preprocessing + peak detection
        t1 = time.perf_counter()
        catalogueconstructor.run_signalprocessor(duration=total_duration)
        t2 = time.perf_counter()
        print('run_signalprocessor', t2 - t1)
        print(catalogueconstructor)

    if extract_waveforms:
        ## Extract waveforms PCA cluster
        # Take some waveforms from the signals
        t1 = time.perf_counter()
        catalogueconstructor.extract_some_waveforms(n_left=n_left, n_right=n_right, mode='all', align_waveform=True)
        t2 = time.perf_counter()
        print('extract_some_waveforms', t2 - t1)
        print(catalogueconstructor.some_waveforms.shape)
        print(catalogueconstructor)

        # Plot extracted waveforms
        fig=plt.figure()
        plt.plot(np.transpose(np.squeeze(catalogueconstructor.some_waveforms[:,:,0])))
        plt.title('Extracted waveforms')
        fig.savefig(os.path.join(out_path, 'extracted_waveforms.png'))

        # new_n_left, new_n_right = catalogueconstructor.find_good_limits(mad_threshold = 1.1,)
        # print('n_left', new_n_left, 'n_right', new_n_right)
        # if not (new_n_left is None or new_n_right is None):
        #     n_left=new_n_left
        #     n_right=new_n_right
        #
        # # Plot extracted waveforms
        # fig = plt.figure()
        # plt.plot(np.transpose(np.squeeze(catalogueconstructor.some_waveforms[:, :, 0])))
        # plt.title('Extracted waveforms')
        # fig.savefig(os.path.join(out_path, 'extracted_waveforms_autowin.png'))

        # Clean waveforms
        # try to detect bad waveforms to not include them in features aand clustering.Strange waveforms are tag with -9 (alien)
        t1 = time.perf_counter()
        catalogueconstructor.clean_waveforms(alien_value_threshold=100.)
        t2 = time.perf_counter()
        print('clean_waveforms', t2 - t1)
        print(catalogueconstructor)

        # Plot cleaned waveforms
        fig=plt.figure()
        plt.plot(np.transpose(np.squeeze(catalogueconstructor.some_waveforms[:, :, 0])))
        plt.title('Cleaned waveforms')
        fig.savefig(os.path.join(out_path, 'cleaned_waveforms.png'))

    if extract_features:
        # extract_some_noise
        t1 = time.perf_counter()
        n_snippet=dataio.nb_segment*2
        catalogueconstructor.extract_some_noise(nb_snippet=n_snippet)
        t2 = time.perf_counter()
        print('extract_some_noise', t2 - t1)
        median, mad = median_mad(catalogueconstructor.some_noise_snippet, axis=0)
        print(median)
        print(mad)

        t1 = time.perf_counter()
        # Had to modify incremental PCA to choose right batch size
        catalogueconstructor.extract_some_features(method='pca_by_channel', n_components_by_channel=5)
        t2 = time.perf_counter()
        print('project', t2 - t1)
        print(catalogueconstructor)

    if find_clusters:
        t1 = time.perf_counter()
        catalogueconstructor.find_clusters(method='gmm', n_clusters=10)
        t2 = time.perf_counter()
        print('find_clusters', t2 - t1)
        print(catalogueconstructor)

    if postprocess:
        if catalogueconstructor.centroids_median is None:
            catalogueconstructor.compute_all_centroid()

        # Remove clusters with positive peaks
        cluster_removed = True
        fig=plt.figure()
        while cluster_removed:

            labels = catalogueconstructor.cluster_labels
            for idx,label in enumerate(labels):
                unit_label=catalogueconstructor.clusters['cell_label'][idx]
                max_channel=catalogueconstructor.clusters['max_on_channel'][idx]
                max_val=np.max(catalogueconstructor.centroids_median[idx,:,max_channel])
                min_val=np.min(catalogueconstructor.centroids_median[idx,:,max_channel])
                if label>=0 and max_val>np.abs(min_val):
                    print('Removing unit %d - extrema on peak electrode is positive' % unit_label)

                    color = catalogueconstructor.colors.get(label, 'k')
                    plt.plot(catalogueconstructor.centroids_median[idx, :, max_channel], color=color, label=unit_label)
                    plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                                     catalogueconstructor.centroids_median[idx, :,max_channel] - catalogueconstructor.centroids_std[idx, :, max_channel],
                                     catalogueconstructor.centroids_median[idx, :,max_channel] + catalogueconstructor.centroids_std[idx, :, max_channel],
                                     alpha=0.2, edgecolor=color, facecolor=color)

                    catalogueconstructor.remove_one_cluster(label)
                    cluster_removed = True
                    break
                else:
                    cluster_removed = False
        plt.legend(loc='best')
        plt.title('Positive peak clusters')
        fig.savefig(os.path.join(out_path, 'postprocess1_positive_peak_clusters.png'))

        labels = catalogueconstructor.cluster_labels
        fig=plt.figure()
        for idx, label in enumerate(labels):
            unit_label=catalogueconstructor.clusters['cell_label'][idx]
            max_channel = catalogueconstructor.clusters['max_on_channel'][idx]
            color = catalogueconstructor.colors.get(label, 'k')
            plt.plot(catalogueconstructor.centroids_median[idx, :, max_channel], color=color, label=unit_label)
            plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                             catalogueconstructor.centroids_median[idx, :, max_channel] - catalogueconstructor.centroids_std[idx,:, max_channel],
                             catalogueconstructor.centroids_median[idx, :, max_channel] + catalogueconstructor.centroids_std[idx,:, max_channel],
                             alpha=0.2, edgecolor=color, facecolor=color)
        plt.legend(loc='best')
        plt.title('Non-positive peak clusters')
        fig.savefig(os.path.join(out_path, 'postprocess1_good_clusters.png'))

        # Remove mis-aligned clusters
        cluster_removed=True
        fig=plt.figure()
        while cluster_removed:
            labels = catalogueconstructor.cluster_labels
            for idx, label in enumerate(labels):
                unit_label = catalogueconstructor.clusters['cell_label'][idx]
                max_channel = catalogueconstructor.clusters['max_on_channel'][idx]
                min_val = np.min(catalogueconstructor.centroids_median[idx, :, max_channel])
                min_idx=np.where(catalogueconstructor.centroids_median[idx, :, max_channel]==min_val)
                if label>=0 and (min_idx<np.abs(n_left)-5 or min_idx>np.abs(n_left)+5):
                    print('Removing unit %d - mis-aligned' % unit_label)

                    color = catalogueconstructor.colors.get(label, 'k')
                    plt.plot(catalogueconstructor.centroids_median[idx, :, 0], color=color, label=unit_label)
                    plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                                     catalogueconstructor.centroids_median[idx, :,0] - catalogueconstructor.centroids_std[idx, :, 0],
                                     catalogueconstructor.centroids_median[idx, :,0] + catalogueconstructor.centroids_std[idx, :, 0],
                                     alpha=0.2, edgecolor=color, facecolor=color)

                    catalogueconstructor.remove_one_cluster(label)
                    cluster_removed = True
                    break
                else:
                    cluster_removed = False
        plt.legend(loc='best')
        plt.title('Mis-aligned clusters')
        fig.savefig(os.path.join(out_path, 'postprocess2_misaligned_clusters.png'))

        labels = catalogueconstructor.cluster_labels
        fig=plt.figure()
        for idx, label in enumerate(labels):
            unit_label = catalogueconstructor.clusters['cell_label'][idx]
            max_channel = catalogueconstructor.clusters['max_on_channel'][idx]
            color = catalogueconstructor.colors.get(label, 'k')
            plt.plot(catalogueconstructor.centroids_median[idx, :, max_channel], color=color, label=unit_label)
            plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                             catalogueconstructor.centroids_median[idx, :, max_channel] - catalogueconstructor.centroids_std[idx,:, max_channel],
                             catalogueconstructor.centroids_median[idx, :, max_channel] + catalogueconstructor.centroids_std[idx,:, max_channel],
                             alpha=0.2, edgecolor=color, facecolor=color)
        plt.legend(loc='best')
        plt.title('Well aligned clusters')
        fig.savefig(os.path.join(out_path, 'postprocess2_good_clusters.png'))

        # Auto-merge clusters
        cluster_removed=True
        while cluster_removed:
            catalogueconstructor.compute_cluster_similarity()

            pairs = get_pairs_over_threshold(catalogueconstructor.cluster_similarity, catalogueconstructor.cluster_labels,
                                             cluster_merge_threshold)
            if len(pairs)>0:
                (k1,k2)=pairs[0]

                idx1=np.where(catalogueconstructor.cluster_labels==k1)[0][0]
                idx2=np.where(catalogueconstructor.cluster_labels==k2)[0][0]
                similarity=catalogueconstructor.cluster_similarity[idx1, idx2]

                unit_label1 = catalogueconstructor.clusters['cell_label'][idx1]
                max_channel1 = catalogueconstructor.clusters['max_on_channel'][idx1]
                unit_label2 = catalogueconstructor.clusters['cell_label'][idx2]
                max_channel2 = catalogueconstructor.clusters['max_on_channel'][idx2]

                fig = plt.figure()
                color1 = catalogueconstructor.colors.get(k1, 'k')
                color2 = catalogueconstructor.colors.get(k2, 'k')
                plt.plot(catalogueconstructor.centroids_median[idx1, :, max_channel1],color=color1, label=unit_label1)
                plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                                 catalogueconstructor.centroids_median[idx1, :, max_channel1]-catalogueconstructor.centroids_std[idx1,:,max_channel1],
                                 catalogueconstructor.centroids_median[idx1, :, max_channel1]+catalogueconstructor.centroids_std[idx1,:,max_channel1],
                                 alpha=0.2, edgecolor=color1, facecolor=color1)
                plt.plot(catalogueconstructor.centroids_median[idx2, :, max_channel2], color=color2, label=unit_label2)
                plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                                 catalogueconstructor.centroids_median[idx2, :, max_channel2]-catalogueconstructor.centroids_std[idx2, :, max_channel2],
                                 catalogueconstructor.centroids_median[idx2, :, max_channel2]+catalogueconstructor.centroids_std[idx2, :, max_channel2],
                                 alpha=0.2, edgecolor=color2, facecolor=color2)
                plt.title('Merge %d with %d, similarity=%.4f' % (unit_label1,unit_label2,similarity))
                plt.legend(loc='best')
                fig.savefig(os.path.join(out_path, 'postprocess3_merge_%d_%d.png' % (unit_label1, unit_label2)))

                print('auto_merge', unit_label1, 'with', unit_label2)
                mask = catalogueconstructor.all_peaks['cluster_label'] == k2
                catalogueconstructor.all_peaks['cluster_label'][mask] = k1
                catalogueconstructor.remove_one_cluster(k2)
            else:
                cluster_removed=False

        labels = catalogueconstructor.cluster_labels
        fig = plt.figure()
        for idx, label in enumerate(labels):
            unit_label = catalogueconstructor.clusters['cell_label'][idx]
            max_channel = catalogueconstructor.clusters['max_on_channel'][idx]
            color = catalogueconstructor.colors.get(label, 'k')
            plt.plot(catalogueconstructor.centroids_median[idx, :, max_channel], color=color, label=unit_label)
            plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                             catalogueconstructor.centroids_median[idx, :,
                             max_channel] - catalogueconstructor.centroids_std[idx, :, max_channel],
                             catalogueconstructor.centroids_median[idx, :,
                             max_channel] + catalogueconstructor.centroids_std[idx, :, max_channel],
                             alpha=0.2, edgecolor=color, facecolor=color)
        plt.legend(loc='best')
        plt.title('Final clusters')
        fig.savefig(os.path.join(out_path, 'postprocess3_final_clusters.png'))

        plt.close('all')

        # Remove small clusters
        catalogueconstructor.trash_small_cluster(n=5)

        # order cluster by waveforms rms
        catalogueconstructor.order_clusters(by='waveforms_rms')

        # put label 0 to trash
    #    mask = catalogueconstructor.all_peaks['cluster_label'] == 0
    #    catalogueconstructor.all_peaks['cluster_label'][mask] = -1
    #    catalogueconstructor.on_new_cluster()

    # save the catalogue
    catalogueconstructor.make_catalogue_for_peeler()


def open_cataloguewindow(dataio, chan_grp):
    catalogueconstructor = CatalogueConstructor(dataio=dataio, chan_grp=chan_grp)

    app = pg.mkQApp()
    win = CatalogueWindow(catalogueconstructor)
    win.show()

    app.exec_()


def run_compute_catalogue(subject, recording_date, display_catalogue=False):
    arrays = ['F1', 'F5hand', 'F5mouth', '46v/12r', '45a', 'F2']
    data_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/data/recordings/rhd2000/', subject, recording_date)
    print(data_dir)
    if os.path.exists(data_dir):
        # Compute total duration (want to use all data for clustering)
        total_duration = 0.0
        data_file_names = []
        for x in os.listdir(data_dir):
            if os.path.splitext(x)[1] == '.raw':
                data_file_names.append(os.path.join(data_dir, x))
                data = RawBinarySignalRawIO(os.path.join(data_dir, x),dtype='float32',sampling_rate=30000,nb_channel=192)
                data.parse_header()
                # Add duration of this trial to total duration
                total_duration+=data.get_signal_size(0,0,[0])*1/data.get_signal_sampling_rate([0])

        data_file_times = []
        for idx, evt_file in enumerate(data_file_names):
            fname = os.path.split(evt_file)[-1]
            fparts = fname.split('_')
            filedate = datetime.strptime('%s %s' % (fparts[4], fparts[5].split('.')[0]), '%y%m%d %H%M%S')
            data_file_times.append(filedate)
        data_file_names = [x for _, x in sorted(zip(data_file_times, data_file_names))]

        if os.path.exists(data_dir) and len(data_file_names) > 0:
            output_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/data/spike_sorting/', subject, recording_date)

            # create a DataIO
            if os.path.exists(output_dir):
                # remove is already exists
                shutil.rmtree(output_dir)

            # F1
            # voltage threshold = 3
            # clustering threshold=0.8
            # F5hand
            # voltage threshold = 3
            # clustering threshold=0.8
            # F5mouth
            # voltage threshold = 3
            # clustering threshold=0.8
            # 46v/12r
            # voltage threshold = 2.5?
            # clustering threshold=0.8
            # 45a
            # voltage threshold = 2.5?
            # clustering threshold=0.8
            # F2
            # probably have to look at more recent date

            ## Setup DataIO
            dataio = DataIO(dirname=output_dir)
            dataio.set_data_source(type='RawData', filenames=data_file_names, dtype='float32', sample_rate=30000,total_channel=192)

            # Setup channel groups - one for each channel
            for ch_grp in range(32*6):
                 dataio.add_one_channel_group(channels=[ch_grp], chan_grp=ch_grp)

            print(dataio)

            for ch_grp in range(32 * 6):
                print(ch_grp)
                dataio = DataIO(dirname=output_dir, ch_grp=ch_grp)

                # Compute catalogue for channel
                compute_catalogue(dataio, ch_grp, total_duration, os.path.join(output_dir,'channel_group_%d' % ch_grp))

                if display_catalogue:
                    open_cataloguewindow(dataio, ch_grp)


if __name__=='__main__':
    subject=sys.argv[1]
    recording_date=sys.argv[2]
    display_catalogue=sys.argv[3] in ['true', 'True','1']
    preprocess=True
    if len(sys.argv)>4:
        preprocess=sys.argv[4] in ['true','True','1']

    start_time = time.time()
    if preprocess:
        matlab = transplant.Matlab()
        matlab.addpath('/home/bonaiuto/Projects/tool_learning/src/matlab')
        matlab.preprocessSpikeData(subject, recording_date)
        matlab.exit()

    run_compute_catalogue(subject, recording_date, display_catalogue=display_catalogue)
    elapsed_time = time.time() - start_time
    print(elapsed_time)