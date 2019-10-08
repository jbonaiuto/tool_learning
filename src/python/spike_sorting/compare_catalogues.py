import sys
from datetime import datetime
from shutil import copyfile

from jinja2 import Environment, FileSystemLoader
from tridesclous import DataIO, CatalogueConstructor, Peeler
import numpy as np
from tridesclous import metrics
import matplotlib.pyplot as plt
import os

from config import read_config
from spike_sorting.plot import heatmap, annotate_heatmap, plot_clusters_summary

cfg = read_config()

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

    # Get previous days to compare to
    sorted_dates, sorted_files = read_previous_sorts(subject)

    new_date = datetime.strptime(date, '%d.%m.%y')

    # Results for report
    channel_results = []

    for array_idx in range(len(cfg['arrays'])):
        new_output_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, date, 'array_%d' % array_idx)

        # Create directory for plots
        plot_output_dir = os.path.join(new_output_dir, 'figures', 'catalogue_comparison')
        if not os.path.exists(plot_output_dir):
            os.mkdir(plot_output_dir)

        for ch_grp in range(cfg['n_channels_per_array']):
            channel_result = {'array': cfg['arrays'][array_idx], 'channel': ch_grp, 'merged': [], 'unmerged': [], 'final': ''}

            # load catalogue for this channel
            new_dataio = DataIO(dirname=new_output_dir, ch_grp=ch_grp)
            catalogueconstructor = CatalogueConstructor(dataio=new_dataio,chan_grp=ch_grp)

            # Waveform time range
            time_range = range(catalogueconstructor.info['waveform_extractor_params']['n_left'],
                               catalogueconstructor.info['waveform_extractor_params']['n_right'])

            # refresh
            if catalogueconstructor.centroids_median is None:
                catalogueconstructor.compute_all_centroid()
            catalogueconstructor.refresh_colors()

            # cell labels and cluster waveforms for this day
            nn_idx=np.where(catalogueconstructor.clusters['cell_label']>-1)[0]

            # If there are any clusters for this day
            if len(nn_idx)>0:

                new_cluster_labels, new_cell_labels, new_wfs, new_wfs_stds, new_isis = get_cluster_info(catalogueconstructor,
                                                                                          new_dataio, ch_grp, bins,
                                                                                          nn_idx)

                # Load cell labels and waveforms for all previous days
                all_old_cluster_labels=[]
                all_old_cell_labels=[]
                all_old_wfs=np.zeros((0,50))
                all_old_wfs_stds = np.zeros((0, 50))
                all_old_isis=np.zeros((0,len(bins)-1))

                for old_date,old_file in zip(sorted_dates,sorted_files):
                    if old_date<new_date:
                        old_output_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, old_file, 'array_%d' % array_idx)
                        old_dataio = DataIO(dirname=old_output_dir, ch_grp=ch_grp, reload_data_source=False)

                        old_catalogueconstructor = CatalogueConstructor(dataio=old_dataio, chan_grp=ch_grp, load_persistent_arrays=False)
                        old_catalogueconstructor.arrays.load_if_exists('clusters')
                        old_catalogueconstructor.arrays.load_if_exists('centroids_median')
                        old_catalogueconstructor.arrays.load_if_exists('centroids_std')


                        if old_catalogueconstructor.centroids_median is None:
                            old_catalogueconstructor.compute_all_centroid()

                        old_cell_labels=old_catalogueconstructor.clusters['cell_label']
                        to_include = np.where(np.bitwise_and(np.isin(old_cell_labels, all_old_cell_labels) == False,
                                                             old_cell_labels > -1))[0]

                        if len(to_include):
                            old_cluster_labels, old_cell_labels, old_wfs, old_wfs_stds, old_isis = get_cluster_info(
                                old_catalogueconstructor,
                                old_dataio, ch_grp, bins,
                                to_include)


                            all_old_wfs=np.concatenate((all_old_wfs,old_wfs))
                            all_old_wfs_stds = np.concatenate((all_old_wfs_stds, old_wfs_stds))
                            all_old_cell_labels.extend(old_cell_labels)
                            all_old_cluster_labels.extend(old_cluster_labels)
                            all_old_isis = np.concatenate((all_old_isis, old_isis))

                if len(all_old_cell_labels):
                    # Compute cluster similarity
                    wfs=np.concatenate((new_wfs,all_old_wfs))
                    cluster_similarity = metrics.cosine_similarity_with_max(wfs)
                    new_old_cluster_similarity=cluster_similarity[0:new_wfs.shape[0],new_wfs.shape[0]:]

                    # Plot cluster similarity
                    fname = 'chan_%d_similarity.png' % ch_grp
                    plot_new_old_cluster_similarity(all_old_cluster_labels, all_old_cell_labels, new_cluster_labels, new_cell_labels, new_old_cluster_similarity,
                                                    plot_output_dir, fname)
                    channel_result['similarity']=os.path.join('array_%d' % array_idx, 'figures','catalogue_comparison',fname)

                    # Go through each cluster in current day
                    for new_cluster_idx in range(new_wfs.shape[0]):
                        # Find most similar cluster from previous days
                        most_similar = np.argmax(new_old_cluster_similarity[new_cluster_idx,:])

                        # Merge if similarity greater than threshold
                        similarity=new_old_cluster_similarity[new_cluster_idx,most_similar]
                        if similarity>=similarity_threshold:
                            print('relabeling unit %d-%d as unit %d-%d' % (ch_grp, new_cell_labels[new_cluster_idx], ch_grp,
                                                                           all_old_cell_labels[most_similar]))
                            fname = 'chan_%d_merge_%d-%d.png' % (ch_grp, new_cell_labels[new_cluster_idx], all_old_cell_labels[most_similar])

                            plot_cluster_merge(all_old_cell_labels[most_similar], all_old_cluster_labels[most_similar],
                                               all_old_isis[most_similar, :], all_old_wfs[most_similar, :],
                                               all_old_wfs_stds[most_similar, :], new_cell_labels[new_cluster_idx],
                                               new_cluster_labels[new_cluster_idx], new_isis[new_cluster_idx, :],
                                               new_wfs[new_cluster_idx, :], new_wfs_stds[new_cluster_idx, :], similarity,
                                               time_range, bins, plot_output_dir, fname)
                            channel_result['merged'].append(os.path.join('array_%d' % array_idx, 'figures', 'catalogue_comparison',fname))


                            new_cell_labels[new_cluster_idx]=all_old_cell_labels[most_similar]
                        # Otherwise, add new cluster
                        else:
                            new_label = np.max(all_old_cell_labels) + 1
                            print('adding new unit %d-%d' % (ch_grp, new_label))
                            all_old_cell_labels.append(new_label)
                            new_cell_labels[new_cluster_idx] = new_label

                            fname = 'chan_%d_nonmerge_%d.png' % (ch_grp, new_cell_labels[new_cluster_idx])

                            plot_cluster_new(all_old_cluster_labels, all_old_cell_labels, all_old_isis, all_old_wfs, all_old_wfs_stds,
                                             new_cluster_labels[new_cluster_idx], new_cell_labels[new_cluster_idx], new_isis[new_cluster_idx, :],
                                             new_wfs[new_cluster_idx, :], new_wfs_stds[new_cluster_idx, :],
                                             new_old_cluster_similarity[new_cluster_idx:new_cluster_idx+1, :], time_range, bins, plot_output_dir, fname)
                            channel_result['unmerged'].append(os.path.join('array_%d' % array_idx, 'figures','catalogue_comparison',fname))


                    catalogueconstructor.clusters['cell_label'][nn_idx]=new_cell_labels

                # Merge clusters with same labels
                cluster_removed = True
                while cluster_removed:
                    for cell_label in catalogueconstructor.clusters['cell_label']:
                        cluster_idx=np.where(catalogueconstructor.clusters['cell_label']==cell_label)[0]
                        if len(cluster_idx)>1:
                            cluster_label1=catalogueconstructor.cluster_labels[cluster_idx[0]]
                            cluster_label2 = catalogueconstructor.cluster_labels[cluster_idx[1]]

                            print('auto_merge', cluster_label2, 'with', cluster_label1)
                            mask = catalogueconstructor.all_peaks['cluster_label'] == cluster_label2
                            catalogueconstructor.all_peaks['cluster_label'][mask] = cluster_label1
                            catalogueconstructor.remove_one_cluster(cluster_label2)
                            break
                        else:
                            cluster_removed = False

                catalogueconstructor.make_catalogue_for_peeler()

                fig=plot_clusters_summary(new_dataio, catalogueconstructor, ch_grp)
                fname='chan_%d_final_clusters.png' % ch_grp
                fig.savefig(os.path.join(plot_output_dir, fname))
                fig.clf()
                plt.close()
                channel_result['final']=os.path.join('array_%d' % array_idx, 'figures','catalogue_comparison',fname)

            channel_results.append(channel_result)


    env = Environment(loader=FileSystemLoader(cfg['template_dir']))
    template = env.get_template('spike_sorting_merge_template.html')
    template_output = template.render(subject=subject, recording_date=date, channel_results=channel_results)

    out_filename = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, date, 'spike_sorting_merge_report.html')
    with open(out_filename, 'w') as fh:
        fh.write(template_output)

    copyfile(os.path.join(cfg['template_dir'], 'style.css'), os.path.join(cfg['single_unit_spike_sorting_dir'], subject, date, 'style.css'))


def plot_cluster_new(all_old_cluster_labels, all_old_cell_labels, all_old_isis, all_old_wfs, all_old_wfs_stds,
                     new_cluster_label, new_cell_label, new_isis, new_wfs, new_wfs_stds, new_old_cluster_similarity, time_range, bins, plot_output_dir,
                     fname):
    fig, axs = plt.subplots(ncols=2, nrows=2)
    axs[0, 0].remove()
    # centroids
    ax = axs[0, 1]
    ax.plot(time_range, new_wfs, 'r', label='new: %d:%d' % (new_cluster_label,new_cell_label))
    ax.fill_between(time_range, new_wfs - new_wfs_stds, new_wfs + new_wfs_stds, alpha=0.2, edgecolor='r', facecolor='r')
    for i in range(new_old_cluster_similarity.shape[1]):
        ln = ax.plot(time_range, all_old_wfs[i, :], '--', label='old: %d:%d=%.2f' % (
        all_old_cluster_labels[i], all_old_cell_labels[i], new_old_cluster_similarity[0,i]))
        ax.fill_between(time_range, all_old_wfs[i, :] - all_old_wfs_stds[i, :], all_old_wfs[i, :] + all_old_wfs_stds[i, :],
                        alpha=0.2, edgecolor=ln[0].get_color(), facecolor=ln[0].get_color())
    ax.legend(loc='best', prop={'size': 6})
    ax = axs[1, 0]
    ax.plot(bins[:-1], new_isis, color='r', label='new: %d:%d' % (new_cluster_label, new_cell_label))
    for i in range(new_old_cluster_similarity.shape[1]):
        ax.plot(bins[:-1], all_old_isis[i, :], '--', label='old: %d=%.2f' % (all_old_cell_labels[i], new_old_cluster_similarity[0,i]))
    ax.legend(loc='best', prop={'size': 6})
    ax.set_title('ISI (ms)')
    ax = axs[1, 1]
    if new_old_cluster_similarity.shape[1] > 0:
        im, cbar = heatmap(new_old_cluster_similarity,
                           ['%d:%d' % (new_cluster_label, new_cell_label)],
                           ['%d:%d' % (x,y) for x,y in zip(all_old_cluster_labels,all_old_cell_labels)], ax=ax, cbarlabel='cluster similarity')
        texts = annotate_heatmap(im, valfmt='{x:.2f}', textcolors=['white', 'black'])
    plt.xlabel('Old cells')
    fig.savefig(os.path.join(plot_output_dir, fname))
    fig.clf()
    plt.close()


def plot_cluster_merge(old_cell_label, old_cluster_label, old_isis, old_wfs, old_wfs_stds,
                       new_cell_label, new_cluster_label, new_isis, new_wfs, new_wfs_stds,
                       similarity, time_range, bins, plot_output_dir, fname):
    fig, axs = plt.subplots(ncols=2, nrows=2)
    axs[0, 0].remove()
    # centroids
    ax = axs[0, 1]
    ax.plot(time_range, old_wfs, 'b', label='old')
    ax.fill_between(time_range, old_wfs - old_wfs_stds, old_wfs + old_wfs_stds, alpha=0.2, edgecolor='b', facecolor='b')
    ax.plot(time_range, new_wfs, 'r', label='new')
    ax.fill_between(time_range, new_wfs - new_wfs_stds, new_wfs + new_wfs_stds, alpha=0.2, edgecolor='r', facecolor='r')
    plt.legend(loc='best')
    ax = axs[1, 0]
    ax.plot(bins[:-1], old_isis, color='b', label='old')
    ax.plot(bins[:-1], new_isis, color='r', label='new')
    ax.legend(loc='best', prop={'size': 6})
    ax.set_title('ISI (ms)')
    d = dict(new_cluster_label=new_cluster_label,
             new_cell_label=new_cell_label,
             old_cluster_label=old_cluster_label,
             old_cell_label=old_cell_label,
             similarity=similarity,
             )
    text = _cluster_merge_template.format(**d)
    ax.figure.text(.05, .75, text, va='center')  # , ha='center')
    fig.tight_layout()
    fig.savefig(os.path.join(plot_output_dir, fname))
    fig.clf()
    plt.close()


def plot_new_old_cluster_similarity(all_old_cluster_labels, all_old_cell_labels, new_cluster_labels, new_cell_labels, new_old_cluster_similarity, plot_output_dir,
                                    fname):
    fig, ax = plt.subplots(ncols=1, nrows=1)
    im, cbar = heatmap(new_old_cluster_similarity, ['%d:%d' % (x,y) for x,y in zip(new_cluster_labels, new_cell_labels)],
                       ['%d:%d' % (x,y) for x,y in zip(all_old_cluster_labels, all_old_cell_labels)], ax=ax, cbarlabel='cluster similarity')
    texts = annotate_heatmap(im, valfmt='{x:.2f}', textcolors=['white', 'black'])
    plt.xlabel('Old cells')
    plt.ylabel('New cells')
    fig.savefig(os.path.join(plot_output_dir, fname))
    fig.clf()
    plt.close()


def get_cluster_info(catalogueconstructor, new_dataio, ch_grp, bins, nn_idx):
    cell_labels = catalogueconstructor.clusters['cell_label'][nn_idx]
    cluster_labels = catalogueconstructor.clusters['cluster_label'][nn_idx]
    wfs = catalogueconstructor.centroids_median[nn_idx, :, :]
    wfs = wfs.reshape(wfs.shape[0], -1)
    wfs_stds = catalogueconstructor.centroids_std[nn_idx, :, :]
    wfs_stds = wfs_stds.reshape(wfs_stds.shape[0], -1)
    all_isis = np.zeros((0, len(bins) - 1))
    for cluster_label in cluster_labels:
        isis = compute_cluster_isis(bins, ch_grp, cluster_label, new_dataio)
        all_isis = np.concatenate((all_isis, np.reshape(isis, (1, len(bins) - 1))))
    return cluster_labels, cell_labels, wfs, wfs_stds, all_isis


def compute_cluster_isis(bins, ch_grp, cluster_label, new_dataio):
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
    return isis


def read_previous_sorts(subject):
    x = os.listdir(os.path.join(cfg['single_unit_spike_sorting_dir'], subject))
    sorted_files = []
    for y in x:
        if os.path.isdir(os.path.join(cfg['single_unit_spike_sorting_dir'], subject, y)):
            try:
                datetime.strptime(y, '%d.%m.%y')
                sorted_files.append(y)
            except:
                pass
    sorted_dates = [datetime.strptime(x, '%d.%m.%y') for x in sorted_files]
    sorted_files = [x for _, x in sorted(zip(sorted_dates, sorted_files))]
    sorted_dates = sorted(sorted_dates)
    return sorted_dates, sorted_files


if __name__=='__main__':
    subject = sys.argv[1]
    date = sys.argv[2]
    run_compare_catalogues(subject, date)