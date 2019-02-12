import os
import shutil
import sys
import time
from datetime import datetime

import pyqtgraph as pg
import matplotlib.pyplot as plt
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

def merge_clusters(dataio, chan_grp, out_path, cluster_merge_threshold):

    catalogueconstructor = CatalogueConstructor(dataio=dataio, chan_grp=chan_grp)

    if catalogueconstructor.centroids_median is None:
        catalogueconstructor.compute_all_centroid()

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

            max_channel1 = catalogueconstructor.clusters[idx1][2]
            max_channel2 = catalogueconstructor.clusters[idx2][2]

            fig = plt.figure()
            color1 = catalogueconstructor.colors.get(k1, 'k')
            color2 = catalogueconstructor.colors.get(k2, 'k')
            plt.plot(catalogueconstructor.centroids_median[idx1, :, max_channel1],color=color1)
            plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                             catalogueconstructor.centroids_median[idx1, :, max_channel1]-catalogueconstructor.centroids_std[idx1,:,max_channel1],
                             catalogueconstructor.centroids_median[idx1, :, max_channel1]+catalogueconstructor.centroids_std[idx1,:,max_channel1],
                             alpha=0.2, edgecolor=color1, facecolor=color1)
            plt.plot(catalogueconstructor.centroids_median[idx2, :, max_channel2], color=color2)
            plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                             catalogueconstructor.centroids_median[idx2, :, max_channel2]-catalogueconstructor.centroids_std[idx2, :, max_channel2],
                             catalogueconstructor.centroids_median[idx2, :, max_channel2]+catalogueconstructor.centroids_std[idx2, :, max_channel2],
                             alpha=0.2, edgecolor=color2, facecolor=color2)
            plt.title('Merge %d with %d, similarity=%.4f' % (k1,k2,similarity))
            fig.savefig(os.path.join(out_path, 'postprocess3_merge_%d_%d.png' % (k1, k2)))

            print('auto_merge', k1, 'with', k2)
            mask = catalogueconstructor.all_peaks['cluster_label'] == k2
            catalogueconstructor.all_peaks['cluster_label'][mask] = k1
            catalogueconstructor.remove_one_cluster(k2)
        else:
            cluster_removed=False

    labels = catalogueconstructor.cluster_labels
    fig = plt.figure()
    for idx, label in enumerate(labels):
        max_channel = catalogueconstructor.clusters[idx][2]
        color = catalogueconstructor.colors.get(idx, 'k')
        plt.plot(catalogueconstructor.centroids_median[idx, :, max_channel], color=color)
        plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                         catalogueconstructor.centroids_median[idx, :,
                         max_channel] - catalogueconstructor.centroids_std[idx, :, max_channel],
                         catalogueconstructor.centroids_median[idx, :,
                         max_channel] + catalogueconstructor.centroids_std[idx, :, max_channel],
                         alpha=0.2, edgecolor=color, facecolor=color)
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

    #tdc.summary_noise(dataio=dataio, chan_grp=chan_grp)
    #tdc.summary_catalogue_clusters(dataio=dataio, chan_grp=chan_grp)
    #plt.show()


def run_merge_clusters(subject, recording_date, ch_grp, threshold):
    data_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/recordings/rhd2000/', subject, recording_date)
    print(data_dir)
    if os.path.exists(data_dir):
        # Compute total duration (want to use all data for clustering)
        data_file_names = []
        for x in os.listdir(data_dir):
            if os.path.splitext(x)[1] == '.raw':
                data_file_names.append(os.path.join(data_dir, x))

        data_file_times = []
        for idx, evt_file in enumerate(data_file_names):
            fname = os.path.split(evt_file)[-1]
            fparts = fname.split('_')
            filedate = datetime.strptime('%s %s' % (fparts[4], fparts[5].split('.')[0]), '%y%m%d %H%M%S')
            data_file_times.append(filedate)
        data_file_names = [x for _, x in sorted(zip(data_file_times, data_file_names))]

        if os.path.exists(data_dir) and len(data_file_names) > 0:
            output_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/spike_sorting/', subject, recording_date)

            ## Setup DataIO
            dataio = DataIO(dirname=output_dir)
            #dataio.set_data_source(type='RawData', filenames=data_file_names, dtype='float32', sample_rate=30000,total_channel=192)

            merge_clusters(dataio, ch_grp, output_dir, threshold)


if __name__=='__main__':
    subject=sys.argv[1]
    recording_date=sys.argv[2]
    ch_grp=int(sys.argv[3])
    threshold=float(sys.argv[4])

    run_merge_clusters(subject, recording_date, ch_grp, threshold)