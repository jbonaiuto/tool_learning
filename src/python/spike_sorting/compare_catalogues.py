import sys
from datetime import datetime
from shutil import copyfile

from jinja2 import Environment, FileSystemLoader
from tridesclous import DataIO, CatalogueConstructor, Peeler
import numpy as np
from tridesclous import metrics
import matplotlib.pyplot as plt
import os

from spike_sorting.plot import heatmap, annotate_heatmap, plot_clusters_summary
from spike_sorting.run_peeler import export_spikes

arrays = ['F1', 'F5hand', 'F5mouth', '46v-12r', '45a', 'F2']
n_channels_per_array=32

_cluster_merge_template = """
Cluster {new_cluster_label}, Cell {new_cell_label}
Mapped to cluster {old_cluster_label}, Cell {old_cell_label}
Similarity : {similarity}

"""
def run_compare_catalogues(subject, date, similarity_threshold=0.7):
    bin_min = 0
    bin_max = 100
    bin_size = 1.
    bins = np.arange(bin_min, bin_max, bin_size)

    x = os.listdir(os.path.join('/data/tool_learning/spike_sorting/', subject))
    sorted_files = []
    for y in x:
        if os.path.isdir(os.path.join('/data/tool_learning/spike_sorting/', subject, y)):
            try:
                datetime.strptime(y, '%d.%m.%y')
                sorted_files.append(y)
            except:
                pass
    sorted_dates = [datetime.strptime(x, '%d.%m.%y') for x in sorted_files]
    sorted_files = [x for _, x in sorted(zip(sorted_dates, sorted_files))]
    sorted_dates = sorted(sorted_dates)

    new_date = datetime.strptime(date, '%d.%m.%y')

    channel_results = []

    for array_idx in range(len(arrays)):
        new_output_dir = os.path.join('/data/tool_learning/spike_sorting/', subject, date, 'array_%d' % array_idx)

        plot_output_dir = os.path.join('/data/tool_learning/spike_sorting/', subject ,date, 'array_%d' % array_idx, 'figures', 'catalogue_comparison')
        if not os.path.exists(plot_output_dir):
            os.mkdir(plot_output_dir)

        for ch_grp in range(n_channels_per_array):
            channel_result = {'array': array_idx, 'channel': ch_grp, 'merged': [], 'unmerged': []}

            # load catalogue for this channel
            new_dataio = DataIO(dirname=new_output_dir, ch_grp=ch_grp)
            catalogueconstructor = CatalogueConstructor(dataio=new_dataio,chan_grp=ch_grp)
            time_range = range(catalogueconstructor.info['waveform_extractor_params']['n_left'],
                               catalogueconstructor.info['waveform_extractor_params']['n_right'])

            # refresh
            if catalogueconstructor.centroids_median is None:
                catalogueconstructor.compute_all_centroid()
            catalogueconstructor.refresh_colors()

            # cell labels and cluster waveforms for this day
            nn_idx=np.where(catalogueconstructor.clusters['cluster_label']>-1)[0]
            new_cell_labels = catalogueconstructor.clusters['cell_label'][nn_idx]
            new_cluster_labels = catalogueconstructor.clusters['cluster_label'][nn_idx]
            new_wfs = catalogueconstructor.centroids_median[nn_idx, :, :]
            new_wfs_reshaped = new_wfs.reshape(new_wfs.shape[0], -1)
            new_wfs_stds = catalogueconstructor.centroids_std[nn_idx, :, :]
            new_wfs_stds_reshaped = new_wfs_stds.reshape(new_wfs_stds.shape[0], -1)
            new_isis=np.zeros((0,len(bins)-1))
            for cluster_label in new_cluster_labels:
                isis = None
                for seg_num in range(new_dataio.nb_segment):
                    spikes = new_dataio.get_spikes(seg_num=seg_num, chan_grp=ch_grp, )
                    spikes = spikes[spikes['cluster_label'] == cluster_label]
                    spike_indexes = spikes['index']

                    isi = np.diff(spike_indexes) / (new_dataio.sample_rate / 1000.)

                    count_, bins = np.histogram(isi, bins=bins)
                    if isis is None:
                        isis = count_
                    else:
                        isis += count_
                new_isis = np.concatenate((new_isis, np.reshape(isis,(1,len(bins)-1))))

            # Load cell labels and waveforms for all previous days
            all_old_cluster_labels=[]
            all_old_cell_labels=[]
            all_old_wfs=np.zeros((0,50))
            all_old_wfs_stds = np.zeros((0, 50))
            all_old_isis=np.zeros((0,len(bins)-1))

            for old_date,old_file in zip(sorted_dates,sorted_files):
                if old_date<new_date:
                    old_output_dir = os.path.join('/data/tool_learning/spike_sorting/', subject, old_file, 'array_%d' % array_idx)
                    old_dataio = DataIO(dirname=old_output_dir, ch_grp=ch_grp)

                    old_catalogueconstructor = CatalogueConstructor(dataio=old_dataio, chan_grp=ch_grp, load_persistent_arrays=False)
                    old_catalogueconstructor.arrays.load_if_exists('clusters')
                    old_catalogueconstructor.arrays.load_if_exists('centroids_median')
                    old_catalogueconstructor.arrays.load_if_exists('centroids_std')


                    if old_catalogueconstructor.centroids_median is None:
                        old_catalogueconstructor.compute_all_centroid()

                    old_cluster_labels = old_catalogueconstructor.clusters['cluster_label']
                    old_cell_labels=old_catalogueconstructor.clusters['cell_label']
                    old_wfs = old_catalogueconstructor.centroids_median[:, :, :]
                    old_wfs_reshaped = old_wfs.reshape(old_wfs.shape[0], -1)
                    old_wfs_stds = old_catalogueconstructor.centroids_std[:, :, :]
                    old_wfs_stds_reshaped = old_wfs_stds.reshape(old_wfs_stds.shape[0], -1)
                    to_include=np.where(np.bitwise_and(np.isin(old_cell_labels,all_old_cell_labels)==False, old_cluster_labels>-1))[0]

                    all_old_wfs=np.concatenate((all_old_wfs,old_wfs_reshaped[to_include,:]))
                    all_old_wfs_stds = np.concatenate((all_old_wfs_stds, old_wfs_stds_reshaped[to_include, :]))
                    all_old_cell_labels.extend(old_cell_labels[to_include])
                    all_old_cluster_labels.extend(old_cluster_labels[to_include])

                    old_isis = np.zeros((0, len(bins) - 1))
                    for cluster_label in old_cluster_labels:
                        isis = None
                        for seg_num in range(old_dataio.nb_segment):
                            spikes = old_dataio.get_spikes(seg_num=seg_num, chan_grp=ch_grp, )
                            spikes = spikes[spikes['cluster_label'] == cluster_label]
                            spike_indexes = spikes['index']

                            isi = np.diff(spike_indexes) / (old_dataio.sample_rate / 1000.)

                            count_, bins = np.histogram(isi, bins=bins)
                            if isis is None:
                                isis = count_
                            else:
                                isis += count_
                        old_isis = np.concatenate((new_isis, np.reshape(isis,(1,len(bins)-1))))
                    all_old_isis = np.concatenate((all_old_isis, old_isis))

            # Compute cluster similarity
            wfs=np.concatenate((new_wfs_reshaped,all_old_wfs))
            cluster_similarity = metrics.cosine_similarity_with_max(wfs)
            new_old_cluster_similarity=cluster_similarity[0:new_wfs_reshaped.shape[0],new_wfs_reshaped.shape[0]:]

            # Plot cluster similarity
            fig, ax = plt.subplots(ncols=1, nrows=1)
            im, cbar = heatmap(new_old_cluster_similarity, ['%d' % x for x in all_old_cluster_labels],
                               ['%d' % x for x in new_cell_labels], ax=ax, cbarlabel='cluster similarity')
            texts = annotate_heatmap(im, valfmt='{x:.2f}', textcolors=['white', 'black'])
            plt.xlabel('Old cells')
            plt.ylabel('New cells')
            fname='chan_%d_similarity.png' % ch_grp
            fig.savefig(os.path.join(plot_output_dir, fname))
            channel_result['similarity']=os.path.join('array_%d' % array_idx, 'figures','catalogue_comparison',fname)
            plt.close(fig)

            # Go through each cluster in current day
            for new_cluster_idx in range(new_wfs_reshaped.shape[0]):
                # Find most similar cluster from previous days
                most_similar = np.argmax(new_old_cluster_similarity[new_cluster_idx,:])
                # If both are not trash clusters
                if new_cell_labels[new_cluster_idx]>=0 and all_old_cell_labels[most_similar]>=0:
                    # Merge if similarity greater than threshold
                    similarity=new_old_cluster_similarity[new_cluster_idx,most_similar]
                    if similarity>=similarity_threshold:
                        print('relabeling unit %d-%d as unit %d-%d' % (ch_grp, new_cell_labels[new_cluster_idx], ch_grp,
                                                                       all_old_cell_labels[most_similar]))
                        fig, axs = plt.subplots(ncols=2, nrows=2)
                        axs[0, 0].remove()
                        # centroids
                        ax = axs[0, 1]
                        ax.plot(time_range, all_old_wfs[most_similar, :], 'b', label='old')
                        ax.fill_between(time_range, all_old_wfs[most_similar,:] - all_old_wfs_stds[most_similar,:],
                                                    all_old_wfs[most_similar,:] + all_old_wfs_stds[most_similar,:],
                                        alpha=0.2, edgecolor='b', facecolor='b')
                        ax.plot(time_range, new_wfs_reshaped[new_cluster_idx, :], 'r', label='new')
                        ax.fill_between(time_range, new_wfs_reshaped[new_cluster_idx, :] - new_wfs_stds_reshaped[new_cluster_idx, :],
                                                    new_wfs_reshaped[new_cluster_idx, :] + new_wfs_stds_reshaped[new_cluster_idx, :],
                                        alpha=0.2, edgecolor='r', facecolor='r')
                        plt.legend(loc='best')

                        ax= axs[1,0]
                        ax.plot(bins[:-1], all_old_isis[most_similar,:], color='b', label='old')
                        ax.plot(bins[:-1], new_isis[new_cluster_idx, :], color='r', label='old')
                        ax.legend(loc='best', prop={'size': 6})
                        ax.set_title('ISI (ms)')

                        d = dict(new_cluster_label=new_cluster_labels[new_cluster_idx],
                                 new_cell_label=new_cell_labels[new_cluster_idx],
                                 old_cluster_label=old_cluster_labels[most_similar],
                                 old_cell_label=old_cell_labels[most_similar],
                                 similarity=similarity,
                        )

                        text = _cluster_merge_template.format(**d)
                        ax.figure.text(.05, .75, text, va='center')  # , ha='center')

                        fig.tight_layout()

                        fname='%d_merge_%d-%d.png' % (ch_grp,new_cell_labels[new_cluster_idx],all_old_cell_labels[most_similar])
                        fig.savefig(os.path.join(plot_output_dir, fname))
                        channel_result['merged'].append(os.path.join('array_%d' % array_idx, 'figures', 'catalogue_comparison',fname))
                        plt.close(fig)

                        new_cell_labels[new_cluster_idx]=all_old_cell_labels[most_similar]
                    # Otherwise, add new cluster
                    else:
                        new_label = np.max(all_old_cell_labels) + 1
                        print('adding new unit %d-%d' % (ch_grp, new_label))
                        all_old_cell_labels.append(new_label)
                        new_cell_labels[new_cluster_idx] = new_label

                        fig, axs = plt.subplots(ncols=2, nrows=2)
                        axs[0, 0].remove()
                        # centroids
                        ax = axs[0, 1]
                        ax.plot(time_range,new_wfs_reshaped[new_cluster_idx, :], 'r', label='new: %d' % new_cell_labels[new_cluster_idx])
                        ax.fill_between(time_range,
                                        new_wfs_reshaped[new_cluster_idx, :] - new_wfs_stds_reshaped[new_cluster_idx, :],
                                        new_wfs_reshaped[new_cluster_idx, :] + new_wfs_stds_reshaped[new_cluster_idx, :],
                                        alpha=0.2, edgecolor='r', facecolor='r')
                        for i in range(new_old_cluster_similarity.shape[1]):
                            if all_old_cell_labels[i]>=0:
                                ln=ax.plot(time_range, all_old_wfs[i, :], '--', label='old: %d=%.2f' % (all_old_cell_labels[i], new_old_cluster_similarity[new_cluster_idx,i]))
                                ax.fill_between(time_range,
                                                all_old_wfs[i, :] - all_old_wfs_stds[i, :],
                                                all_old_wfs[i, :] + all_old_wfs_stds[i, :],
                                                alpha=0.2, edgecolor=ln[0].get_color(), facecolor=ln[0].get_color())
                        ax.legend(loc='best', prop={'size': 6})

                        ax = axs[1, 0]
                        ax.plot(bins[:-1], new_isis[new_cluster_idx, :], color='r', label='new: %d' % new_cell_labels[new_cluster_idx])
                        for i in range(new_old_cluster_similarity.shape[1]):
                            if all_old_cell_labels[i]>=0:
                                ax.plot(bins[:-1], all_old_isis[i, :], '--', label='old: %d=%.2f' % (all_old_cell_labels[i], new_old_cluster_similarity[new_cluster_idx,i]))
                        ax.legend(loc='best', prop={'size': 6})
                        ax.set_title('ISI (ms)')

                        ax=axs[1,1]
                        im, cbar = heatmap(new_old_cluster_similarity[new_old_cluster_similarity,:], ['%d' % x for x in all_old_cluster_labels],
                                           ['%d' % new_cell_labels[new_cluster_idx]], ax=ax, cbarlabel='cluster similarity')
                        texts = annotate_heatmap(im, valfmt='{x:.2f}', textcolors=['white', 'black'])
                        plt.xlabel('Old cells')

                        fname='%d_nonmerge_%d.png' % (ch_grp, new_cell_labels[new_cluster_idx])
                        fig.savefig(os.path.join(plot_output_dir, fname))
                        channel_result['unmerged'].append(os.path.join('array_%d' % array_idx, 'figures','catalogue_comparison',fname))
                        plt.close(fig)

            catalogueconstructor.clusters['cell_label'][nn_idx]=new_cell_labels

            # Merge clusters with same labels
            cluster_removed = True
            while cluster_removed:
                for cell_label in catalogueconstructor.clusters['cell_label']:
                    cluster_idx=np.where(catalogueconstructor.clusters['cell_label']==cell_label)[0]
                    if len(cluster_idx)>1:
                        cluster_label1=catalogueconstructor.cluster_labels[cluster_idx[0]]
                        cluster_label2 = catalogueconstructor.cluster_labels[cluster_idx[1]]

                        print('auto_merge', cell_label, 'with', cell_label)
                        mask = catalogueconstructor.all_peaks['cluster_label'] == cluster_label2
                        catalogueconstructor.all_peaks['cluster_label'][mask] = cluster_label1
                        catalogueconstructor.remove_one_cluster(cluster_label2)
                        break
                    else:
                        cluster_removed = False

            catalogueconstructor.make_catalogue_for_peeler()

            # Run peeler
            peeler = Peeler(new_dataio)
            peeler.change_params(catalogue=catalogueconstructor.catalogue,
                                 chunksize=32768,
                                 use_sparse_template=False,
                                 sparse_threshold_mad=1.5,
                                 use_opencl_with_sparse=False)

            peeler.run()
            export_spikes(new_output_dir, array_idx, ch_grp)

            fig=plot_clusters_summary(new_dataio, catalogueconstructor, ch_grp)
            fname='%d_final_clusters.png' % ch_grp
            fig.savefig(os.path.join(plot_output_dir, fname))
            plt.close(fig)
            channel_result['final']=os.path.join('array_%d' % array_idx, 'figures','catalogue_comparison',fname)

            channel_results.append(channel_result)


    template_dir = '/home/ferrarilab/tool_learning/src/templates'
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template('spike_sorting_merge_template.html')
    template_output = template.render(subject=subject, recording_date=date, channel_results=channel_results)

    out_filename = os.path.join('/data/tool_learning/spike_sorting/', subject, date, 'spike_sorting_merge_report.html')
    with open(out_filename, 'w') as fh:
        fh.write(template_output)

    copyfile(os.path.join(template_dir, 'style.css'), os.path.join('/data/tool_learning/spike_sorting/', subject, date, 'style.css'))


if __name__=='__main__':
    subject = sys.argv[1]
    date = sys.argv[2]
    run_compare_catalogues(subject, date)