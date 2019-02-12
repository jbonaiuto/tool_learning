import sys
from datetime import datetime

from tridesclous import DataIO, CatalogueConstructor, Peeler
import numpy as np
from tridesclous import metrics
import matplotlib.pyplot as plt
import os
import glob

from run_peeler import run_peeler

max_electrode_only=True

def compare_catalogues(subject, date, similarity_threshold=0.7):
    new_output_dir = '/home/bonaiuto/Projects/tool_learning/spike_sorting/%s/%s' % (subject, date)
    plot_output_dir='/home/bonaiuto/Projects/tool_learning/spike_sorting/%s/%s/catalogue_comparison' % (subject, date)
    if not os.path.exists(plot_output_dir):
        os.mkdir(plot_output_dir)

    x=os.listdir('/home/bonaiuto/Projects/tool_learning/spike_sorting/%s' % (subject))
    sorted_files=[]
    for y in x:
        if os.path.isdir(os.path.join('/home/bonaiuto/Projects/tool_learning/spike_sorting/%s' % (subject),y)):
            sorted_files.append(y)
    sorted_dates=[datetime.strptime(x,'%d.%m.%y') for x in sorted_files]
    sorted_files = [x for _, x in sorted(zip(sorted_dates, sorted_files))]
    sorted_dates=sorted(sorted_dates)

    new_date = datetime.strptime(date, '%d.%m.%y')

    for ch_grp in range(32*6):
        new_dataio = DataIO(dirname=new_output_dir, ch_grp=ch_grp)
        catalogueconstructor = CatalogueConstructor(dataio=new_dataio,chan_grp=ch_grp)

        if catalogueconstructor.centroids_median is None:
            catalogueconstructor.compute_all_centroid()

        new_cell_labels = catalogueconstructor.clusters['cell_label']
        new_wfs = catalogueconstructor.centroids_median[:, :, :]
        new_wfs_reshaped = new_wfs.reshape(new_wfs.shape[0], -1)

        all_old_cell_labels=[]
        all_old_wfs=np.zeros((0,50))
        for old_date,old_file in zip(sorted_dates,sorted_files):
            if old_date<new_date:
                old_output_dir = '/home/bonaiuto/Projects/tool_learning/spike_sorting/%s/%s' % (subject, old_file)
                old_dataio = DataIO(dirname=old_output_dir, ch_grp=ch_grp)

                old_catalogueconstructor = CatalogueConstructor(dataio=old_dataio, chan_grp=ch_grp)

                if old_catalogueconstructor.centroids_median is None:
                    old_catalogueconstructor.compute_all_centroid()

                old_cell_labels=old_catalogueconstructor.clusters['cell_label']
                old_wfs = old_catalogueconstructor.centroids_median[:, :, :]
                old_wfs_reshaped = old_wfs.reshape(old_wfs.shape[0], -1)
                to_include=np.where(np.isin(old_cell_labels,all_old_cell_labels)==False)[0]

                all_old_wfs=np.concatenate((all_old_wfs,old_wfs_reshaped[to_include,:]))
                all_old_cell_labels.extend(old_cell_labels[to_include])

        wfs=np.concatenate((new_wfs_reshaped,all_old_wfs))
        cluster_similarity = metrics.cosine_similarity_with_max(wfs)
        new_old_cluster_similarity=cluster_similarity[0:new_wfs_reshaped.shape[0],new_wfs_reshaped.shape[0]:]

        fig = plt.figure()
        plt.imshow(new_old_cluster_similarity)
        plt.xlabel('Old cells')
        plt.ylabel('New cells')
        plt.colorbar()
        fig.savefig(os.path.join(plot_output_dir, '%d_similarity.png' % ch_grp))

        for new_cluster_idx in range(new_wfs_reshaped.shape[0]):
            most_similar = np.argmax(new_old_cluster_similarity[new_cluster_idx,:])
            if new_cell_labels[new_cluster_idx]>=0 and all_old_cell_labels[most_similar]>=0 and \
                    not(new_cell_labels[new_cluster_idx]==all_old_cell_labels[most_similar]):
                similarity=new_old_cluster_similarity[new_cluster_idx,most_similar]
                if similarity>=similarity_threshold:
                    print('relabeling unit %d-%d as unit %d-%d' % (ch_grp, new_cell_labels[new_cluster_idx], ch_grp,
                                                                   all_old_cell_labels[most_similar]))
                    fig = plt.figure()
                    plt.plot(all_old_wfs[most_similar, :], 'b')
                    plt.plot(new_wfs_reshaped[new_cluster_idx, :], 'r')
                    plt.title('%s: %d - %d, similarity=%.3f' % (date, new_cell_labels[new_cluster_idx],
                                                                all_old_cell_labels[most_similar],
                                                                new_old_cluster_similarity[new_cluster_idx, most_similar]))
                    fig.savefig(os.path.join(plot_output_dir, '%d_merge_%d-%d.png' % (ch_grp,new_cell_labels[new_cluster_idx],all_old_cell_labels[most_similar])))

                    new_cell_labels[new_cluster_idx]=all_old_cell_labels[most_similar]
                else:
                    fig = plt.figure()
                    plt.plot(new_wfs_reshaped[new_cluster_idx, :], 'r')
                    for i in range(len(all_old_cell_labels)):
                        plt.plot(all_old_wfs[i, :], '--', label='%d=%.2f' % (all_old_cell_labels[i],new_old_cluster_similarity[new_cluster_idx,i]))
                    plt.legend(loc='best')
                    fig.savefig(os.path.join(plot_output_dir, '%d_nonmerge_%d.png' % (ch_grp, new_cell_labels[new_cluster_idx])))


        for new_cluster_idx in range(new_wfs.shape[0]):
            most_similar = np.argmax(new_old_cluster_similarity[new_cluster_idx,:])
            if new_cell_labels[new_cluster_idx] >= 0 and all_old_cell_labels[most_similar] >= 0:
                similarity = new_old_cluster_similarity[new_cluster_idx,most_similar]
                if similarity < similarity_threshold:
                    print('adding new unit %d-%d' % (ch_grp, np.max(old_cell_labels)+1))
                    new_cell_labels[new_cluster_idx]=np.max(old_cell_labels)+1

        catalogueconstructor.clusters['cell_label']=new_cell_labels

        catalogueconstructor.make_catalogue_for_peeler()

        for fl in glob.glob(os.path.join(new_output_dir, '*spikes.csv')):
            # Do what you want with the file
            os.remove(fl)
        run_peeler(new_output_dir, chan_grp=ch_grp)


if __name__=='__main__':
    subject = sys.argv[1]
    date = sys.argv[2]
    compare_catalogues(subject, date)