import os
import sys
import time
import pyqtgraph as pg
import numpy as np
import tridesclous as tdc
import pandas as pd
from tridesclous import DataIO, Peeler, PeelerWindow

# This is for selecting a GPU
# for e in tdc.get_cl_device_list():
#     print(e)
# tdc.set_default_cl_device(platform_index=0, device_index=0)

arrays = ['F1', 'F5hand', 'F5mouth', '46v-12r', '45a', 'F2']

def run_peeler(dirname, chan_grp):
    dataio = DataIO(dirname=dirname, ch_grp=chan_grp)
    initial_catalogue = dataio.load_catalogue(chan_grp=chan_grp)

    peeler = Peeler(dataio)
    peeler.change_params(catalogue=initial_catalogue,
                         chunksize=32768,
                         use_sparse_template=False,
                         sparse_threshold_mad=1.5,
                         use_opencl_with_sparse=False)

    t1 = time.perf_counter()
    peeler.run()
    t2 = time.perf_counter()
    print('peeler.run', t2 - t1)

    # print()
    # for seg_num in range(dataio.nb_segment):
    #     spikes = dataio.get_spikes(seg_num)
    #     print('seg_num', seg_num, 'nb_spikes', spikes.size)


def open_PeelerWindow(dirname, chan_grp):
    dataio = DataIO(dirname=dirname)
    initial_catalogue = dataio.load_catalogue(chan_grp=chan_grp)

    app = pg.mkQApp()
    win = PeelerWindow(dataio=dataio, catalogue=initial_catalogue)
    win.show()
    app.exec_()


def export_spikes(dirname, chan_grp):
    print('Exporting ch %d' % chan_grp)
    data = {'array': [], 'electrode': [], 'unit': [], 'segment': [], 'time': []}
    array=arrays[int(np.floor(chan_grp/32))]


    dataio = DataIO(dirname=dirname, ch_grp=chan_grp)
    catalogue = dataio.load_catalogue(chan_grp=chan_grp)
    dataio._open_processed_data(ch_grp=chan_grp)

    clusters = catalogue['clusters']

    for seg_num in range(dataio.nb_segment):
        spikes = dataio.get_spikes(seg_num=seg_num, chan_grp=chan_grp)

        spike_labels = spikes['cluster_label'].copy()
        for l in clusters:
            mask = spike_labels == l['cluster_label']
            spike_labels[mask] = l['cell_label']
        spike_indexes = spikes['index']

        for (index,label) in zip(spike_indexes, spike_labels):
            data['array'].append(array)
            data['electrode'].append(chan_grp)
            data['cell'].append(label)
            data['segment'].append(seg_num)
            data['time'].append(index)
        dataio.flush_processed_signals(seg_num=seg_num, chan_grp=chan_grp)
    df=pd.DataFrame(data, columns=['array','electrode','cell','segment','time'])
    df.to_csv(os.path.join(dirname,'%s_%d_spikes.csv' % (array, chan_grp)), index=False)


if __name__ == '__main__':
    subject=sys.argv[1]
    recording_date=sys.argv[2]
    display_peeler = sys.argv[3] in ['true', 'True','1']

    output_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/data/spike_sorting/',subject,recording_date)
    if os.path.exists(output_dir):
        for ch_grp in range(32*6):
            run_peeler(output_dir, chan_grp=ch_grp)
            if display_peeler:
                open_PeelerWindow(output_dir, ch_grp)
            export_spikes(output_dir, ch_grp)


