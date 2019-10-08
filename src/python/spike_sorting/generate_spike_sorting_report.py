import glob
from shutil import copyfile

import os
import sys
import faulthandler

from jinja2 import Environment, FileSystemLoader

from spike_sorting.plot import plot_cluster_summary, plot_clusters_summary

faulthandler.enable()
import matplotlib.pyplot as plt
from tridesclous import DataIO, CatalogueConstructor

from config import read_config

cfg = read_config()

def generate_spike_sorting_report(subject, recording_date):

    data_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, recording_date)

    channel_results=[]

    for array_idx in range(len(cfg['arrays'])):
        array = cfg['arrays'][array_idx]
        print(array)

        array_data_dir=os.path.join(data_dir, 'array_%d' % array_idx)

        export_path = os.path.join(array_data_dir, 'figures')
        if not os.path.exists(export_path):
            os.makedirs(export_path)

        for chan_grp in range(cfg['n_channels_per_array']):
            print(chan_grp)

            dataio = DataIO(array_data_dir, ch_grp=chan_grp)
            dataio.datasource.bit_to_microVolt = 0.195
            catalogueconstructor = CatalogueConstructor(dataio=dataio, chan_grp=chan_grp)
            catalogueconstructor.refresh_colors()
            catalogue = dataio.load_catalogue(chan_grp=chan_grp)

            channel_result={'array': array, 'channel': chan_grp, 'init_waveforms': '', 'clean_waveforms': '',
                            'noise': '', 'init_clusters': '', 'merge_clusters':[], 'final_clusters':[],
                            'all_clusters':''}

            clusters = catalogue['clusters']

            cluster_labels = clusters['cluster_label']
            cell_labels = clusters['cell_label']

            channel_result['init_waveforms'] = os.path.join('array_%d' % array_idx, 'figures',
                                                            'chan_%d_init_waveforms.png' % chan_grp)
            channel_result['clean_waveforms'] = os.path.join('array_%d' % array_idx, 'figures',
                                                             'chan_%d_clean_waveforms.png' % chan_grp)
            channel_result['noise']=os.path.join('array_%d' % array_idx, 'figures', 'chan_%d_noise.png' % chan_grp)
            channel_result['init_clusters'] = os.path.join('array_%d' % array_idx, 'figures',
                                                            'chan_%d_init_clusters.png' % chan_grp)

            merge_files=glob.glob(os.path.join(export_path,'chan_%d_merge_*.png' % chan_grp))
            for merge_file in merge_files:
                [path,file]=os.path.split(merge_file)
                channel_result['merge_clusters'].append(os.path.join('array_%d' % array_idx, 'figures', file))

            for cluster_label in cluster_labels:
                fig = plot_cluster_summary(dataio, catalogue, chan_grp, cluster_label)
                fname = 'chan_%d_cluster_%d.png' % (chan_grp, cluster_label)
                fig.savefig(os.path.join(export_path, fname))
                fig.clf()
                plt.close()
                channel_result['final_clusters'].append(os.path.join('array_%d' % array_idx, 'figures', fname))

            fig = plot_clusters_summary(dataio, catalogueconstructor, chan_grp)
            fname = 'chan_%d_clusters.png' % chan_grp
            fig.savefig(os.path.join(export_path, fname))
            fig.clf()
            plt.close()
            channel_result['all_clusters'] = os.path.join('array_%d' % array_idx, 'figures', fname)

            channel_results.append(channel_result)

    env=Environment(loader=FileSystemLoader(cfg['template_dir']))
    template=env.get_template('spike_sorting_results_template.html')
    template_output=template.render(subject=subject, recording_date=recording_date, channel_results=channel_results)

    out_filename=os.path.join(data_dir, 'spike_sorting_report.html')
    with open(out_filename,'w') as fh:
        fh.write(template_output)

    copyfile(os.path.join(cfg['template_dir'],'style.css'),os.path.join(data_dir,'style.css'))


if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]

    generate_spike_sorting_report(subject, recording_date)
