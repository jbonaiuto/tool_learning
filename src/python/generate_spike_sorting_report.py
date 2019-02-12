import glob

import numpy as np
import os
import sys
import faulthandler;

from jinja2 import Environment, FileSystemLoader

faulthandler.enable()
import matplotlib.pyplot as plt
from tridesclous import DataIO, CatalogueConstructor, generate_report

arrays = ['F1', 'F5hand', 'F5mouth', '46v-12r', '45a', 'F2']

def generate_spike_sorting_report(subject, recording_date):

    data_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/spike_sorting/', subject, recording_date)

    channel_results=[]
    cluster_results = []

    total_unit_idx=0
    last_array=''
    array_unit_idx=0

    for chan_grp in range(32*6):
        array = arrays[int(np.floor(chan_grp / 32))]
        if not array==last_array:
            array_unit_idx=0
        last_array=array

        channel_result={'array': array, 'channel': chan_grp, 'merge_clusters':[]}
        ch_dir=os.path.join(data_dir,'channel_group_%d' % chan_grp)
        merge_files=glob.glob(os.path.join(ch_dir,'postprocess3_merge_*.png'))
        for merge_file in merge_files:
            [file,ext]=os.path.splitext(merge_file)
            [path,file]=os.path.split(file)
            fileparts=file.split('_')
            channel1=int(fileparts[2])
            channel2 = int(fileparts[3])
            channel_result['merge_clusters'].append((channel1,channel2))

        out_path=os.path.join(data_dir,array)
        if not os.path.exists(out_path):
            os.mkdir(out_path)

        dataio=DataIO(data_dir, ch_grp=chan_grp)
        catalogueconstructor = CatalogueConstructor(dataio=dataio, chan_grp=chan_grp)
        sr = dataio.sample_rate

        if catalogueconstructor.centroids_median is None:
             catalogueconstructor.compute_all_centroid()
        catalogueconstructor.refresh_colors()
        labels = catalogueconstructor.cluster_labels

        bin_min = 0
        bin_max = 100
        bin_size = 1.

        for idx, label in enumerate(labels):
            cluster_result = {'array': array, 'channel': chan_grp, 'cluster': label}
            cluster_result['total_number']=total_unit_idx
            cluster_result['array_number']=array_unit_idx
            total_unit_idx=total_unit_idx+1
            array_unit_idx=array_unit_idx+1

            fig = plt.figure()
            ax=plt.subplot(2,1,1)
            max_channel = catalogueconstructor.clusters[idx][2]
            color = catalogueconstructor.colors.get(idx, 'k')
            time_range=range(catalogueconstructor.info['waveform_extractor_params']['n_left'],
            catalogueconstructor.info['waveform_extractor_params']['n_right'])
            plt.plot(time_range,catalogueconstructor.centroids_median[idx, :, max_channel], color=color)
            plt.fill_between(time_range,
            catalogueconstructor.centroids_median[idx, :,max_channel] - catalogueconstructor.centroids_std[idx, :, max_channel],
                             catalogueconstructor.centroids_median[idx, :,max_channel] + catalogueconstructor.centroids_std[idx, :, max_channel],
            alpha=0.2, edgecolor=color, facecolor=color)
            plt.xlabel('Time step')
            plt.ylabel('Centroid median')
            plt.title('Array %s, Channel, %d, Cluster %d' % (array, chan_grp, label))

            ax = plt.subplot(2, 1, 2)
            bins = np.arange(bin_min, bin_max, bin_size)

            count = None
            for seg_num in range(dataio.nb_segment):
                spikes = dataio.get_spikes(seg_num=seg_num, chan_grp=chan_grp, )
                spikes = spikes[spikes['cluster_label'] == label]
                spike_indexes = spikes['index']

                isi = np.diff(spike_indexes) / (sr / 1000.)

                count_, bins = np.histogram(isi, bins=bins)
                if count is None:
                    count = count_
                else:
                    count += count_

            ax.plot(bins[:-1], count, color=color)
            plt.xlabel('ISI')
            plt.ylabel('Count')
            fname='channel_%d_cluster_%d.png' % (chan_grp,label)
            fig.savefig(os.path.join(out_path, fname))
            cluster_result['img'] = os.path.join(array,fname)

            cluster_results.append(cluster_result)

        channel_results.append(channel_result)

    env=Environment(loader=FileSystemLoader('../templates'))
    template=env.get_template('spike_sorting_results_template.html')
    template_output=template.render(subject=subject, recording_date=recording_date, channel_results=channel_results,
                                    cluster_results=cluster_results)

    out_filename=os.path.join(data_dir, 'spike_sorting_report.html')
    with open(out_filename,'w') as fh:
        fh.write(template_output)


if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]

    generate_spike_sorting_report(subject, recording_date)
