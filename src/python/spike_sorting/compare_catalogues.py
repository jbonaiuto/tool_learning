import sys
from datetime import datetime
from shutil import copyfile

from jinja2 import Environment, FileSystemLoader
from tridesclous import DataIO, CatalogueConstructor
import numpy as np
from tridesclous import metrics
import matplotlib.pyplot as plt
import os

arrays = ['F1', 'F5hand', 'F5mouth', '46v-12r', '45a', 'F2']
bin_min = 0
bin_max = 100
bin_size = 1.

def run_compare_catalogues(subject, date, similarity_threshold=0.7):
    new_output_dir = '/home/bonaiuto/Projects/tool_learning/data/spike_sorting/%s/%s' % (subject, date)
    plot_output_dir='/home/bonaiuto/Projects/tool_learning/data/spike_sorting/%s/%s/catalogue_comparison' % (subject, date)
    if not os.path.exists(plot_output_dir):
        os.mkdir(plot_output_dir)

    x=os.listdir('/home/bonaiuto/Projects/tool_learning/data/spike_sorting/%s' % (subject))
    sorted_files=[]
    for y in x:
        if os.path.isdir(os.path.join('/home/bonaiuto/Projects/tool_learning/data/spike_sorting/%s' % (subject),y)):
            try:
                datetime.strptime(y, '%d.%m.%y')
                sorted_files.append(y)
            except:
                pass
    sorted_dates=[datetime.strptime(x,'%d.%m.%y') for x in sorted_files]
    sorted_files = [x for _, x in sorted(zip(sorted_dates, sorted_files))]
    sorted_dates=sorted(sorted_dates)

    new_date = datetime.strptime(date, '%d.%m.%y')

    channel_results = []

    for ch_grp in range(32*6):
        array = arrays[int(np.floor(ch_grp / 32))]

        channel_result = {'array': array, 'channel': ch_grp, 'merged': [], 'unmerged': []}

        # load catalogue for this channel
        new_dataio = DataIO(dirname=new_output_dir, ch_grp=ch_grp)
        catalogueconstructor = CatalogueConstructor(dataio=new_dataio,chan_grp=ch_grp)

        # refresh
        if catalogueconstructor.centroids_median is None:
            catalogueconstructor.compute_all_centroid()
        catalogueconstructor.refresh_colors()

        # cell labels and cluster waveforms for this day
        new_cell_labels = catalogueconstructor.clusters['cell_label']
        new_wfs = catalogueconstructor.centroids_median[:, :, :]
        new_wfs_reshaped = new_wfs.reshape(new_wfs.shape[0], -1)

        # Load cell labels and waveforms for all previous days
        all_old_cell_labels=[]
        all_old_wfs=np.zeros((0,35))
        for old_date,old_file in zip(sorted_dates,sorted_files):
            if old_date<new_date:
                old_output_dir = '/home/bonaiuto/Projects/tool_learning/data/spike_sorting/%s/%s' % (subject, old_file)
                old_dataio = DataIO(dirname=old_output_dir, ch_grp=ch_grp)

                old_catalogueconstructor = CatalogueConstructor(dataio=old_dataio, chan_grp=ch_grp, load_persistent_arrays=False)
                old_catalogueconstructor.arrays.load_if_exists('clusters')
                old_catalogueconstructor.arrays.load_if_exists('centroids_median')


                if old_catalogueconstructor.centroids_median is None:
                    old_catalogueconstructor.compute_all_centroid()

                old_cell_labels=old_catalogueconstructor.clusters['cell_label']
                old_wfs = old_catalogueconstructor.centroids_median[:, :, :]
                old_wfs_reshaped = old_wfs.reshape(old_wfs.shape[0], -1)
                to_include=np.where(np.isin(old_cell_labels,all_old_cell_labels)==False)[0]

                all_old_wfs=np.concatenate((all_old_wfs,old_wfs_reshaped[to_include,:]))
                all_old_cell_labels.extend(old_cell_labels[to_include])

        # Compute cluster similarity
        wfs=np.concatenate((new_wfs_reshaped,all_old_wfs))
        cluster_similarity = metrics.cosine_similarity_with_max(wfs)
        new_old_cluster_similarity=cluster_similarity[0:new_wfs_reshaped.shape[0],new_wfs_reshaped.shape[0]:]

        # Plot cluster similarity
        fig = plt.figure()
        plt.imshow(new_old_cluster_similarity)
        plt.xlabel('Old cells')
        plt.ylabel('New cells')
        plt.colorbar()
        fname='%d_similarity.png' % ch_grp
        fig.savefig(os.path.join(plot_output_dir, fname))
        channel_result['similarity']=os.path.join('catalogue_comparison',fname)
        plt.close('all')

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
                    fig = plt.figure()
                    plt.plot(all_old_wfs[most_similar, :], 'b', label='old')
                    plt.plot(new_wfs_reshaped[new_cluster_idx, :], 'r', label='new')
                    plt.title('%s: %d - %d, similarity=%.3f' % (date, new_cell_labels[new_cluster_idx],
                                                                all_old_cell_labels[most_similar],
                                                                new_old_cluster_similarity[new_cluster_idx, most_similar]))
                    plt.legend(loc='best')
                    fname='%d_merge_%d-%d.png' % (ch_grp,new_cell_labels[new_cluster_idx],all_old_cell_labels[most_similar])
                    fig.savefig(os.path.join(plot_output_dir, fname))
                    channel_result['merged'].append(os.path.join('catalogue_comparison',fname))
                    plt.close('all')

                    new_cell_labels[new_cluster_idx]=all_old_cell_labels[most_similar]
                # Otherwise, add new cluster
                else:
                    new_label = np.max(all_old_cell_labels) + 1
                    print('adding new unit %d-%d' % (ch_grp, new_label))
                    all_old_cell_labels.append(new_label)
                    new_cell_labels[new_cluster_idx] = new_label

                    fig = plt.figure()
                    plt.plot(new_wfs_reshaped[new_cluster_idx, :], 'r', label='new: %d' % new_cell_labels[new_cluster_idx])
                    for i in range(new_old_cluster_similarity.shape[1]):
                        plt.plot(all_old_wfs[i, :], '--', label='old: %d=%.2f' % (all_old_cell_labels[i], new_old_cluster_similarity[new_cluster_idx,i]))
                    plt.legend(loc='best')
                    fname='%d_nonmerge_%d.png' % (ch_grp, new_cell_labels[new_cluster_idx])
                    fig.savefig(os.path.join(plot_output_dir, fname))
                    channel_result['unmerged'].append(os.path.join('catalogue_comparison',fname))
                    plt.close('all')

        catalogueconstructor.clusters['cell_label']=new_cell_labels

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

        labels = catalogueconstructor.cluster_labels
        fig = plt.figure()
        for idx, label in enumerate(labels):
            cell_label = catalogueconstructor.clusters['cell_label'][idx]
            max_channel = catalogueconstructor.clusters['max_on_channel'][idx]
            color = catalogueconstructor.colors.get(label, 'k')
            plt.plot(catalogueconstructor.centroids_median[idx, :, max_channel], color=color, label=cell_label)
            plt.fill_between(range(catalogueconstructor.centroids_median.shape[1]),
                             catalogueconstructor.centroids_median[idx, :,
                             max_channel] - catalogueconstructor.centroids_std[idx, :, max_channel],
                             catalogueconstructor.centroids_median[idx, :,
                             max_channel] + catalogueconstructor.centroids_std[idx, :, max_channel],
                             alpha=0.2, edgecolor=color, facecolor=color)
        plt.legend(loc='best')
        plt.title('Final clusters')
        fname='%d_final_clusters.png' % ch_grp
        fig.savefig(os.path.join(plot_output_dir, fname))
        channel_result['final']=os.path.join('catalogue_comparison',fname)
        channel_results.append(channel_result)
        plt.close('all')

        catalogueconstructor.make_catalogue_for_peeler()

    template_dir = '/home/bonaiuto/Projects/tool_learning/src/templates'
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template('spike_sorting_merge_template.html')
    template_output = template.render(subject=subject, recording_date=date, channel_results=channel_results)

    out_filename = os.path.join(new_output_dir, 'spike_sorting_merge_report.html')
    with open(out_filename, 'w') as fh:
        fh.write(template_output)

    copyfile(os.path.join(template_dir, 'style.css'), os.path.join(new_output_dir, 'style.css'))


if __name__=='__main__':
    subject = sys.argv[1]
    date = sys.argv[2]
    run_compare_catalogues(subject, date)