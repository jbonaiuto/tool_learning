import os
import sys

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from tridesclous import DataIO
from tridesclous.iotools import ArrayCollection
from tridesclous.peakdetector import peakdetector_engines

arrays = ['F1', 'F5hand', 'F5mouth', '46v-12r', '45a', 'F2']
n_channels_per_array=32
_dtype_peak = [('index', 'int64'), ('segment', 'int64'),]

def extract_multiunit_spikes(subject, recording_date):
    preprocess_dir = os.path.join('/data/tool_learning/spike_sorting/', subject, recording_date, 'preprocess')
    dataio = DataIO(dirname=os.path.join(preprocess_dir))

    peak_detector_params = dict(peak_sign='-', relative_threshold=5, peak_span=0.0002)
    PeakDetector_class = peakdetector_engines['numpy']
    for array_idx in range(len(arrays)):
        array = arrays[array_idx]
        output_dir = os.path.join('/data/tool_learning/spike_sorting/', subject, recording_date,
                                  'array_%d' % array_idx)
        if not os.path.exists(output_dir):
            os.mkdir(output_dir)

        nb_channel=dataio.nb_channel(chan_grp=array_idx)
        peakdetector = PeakDetector_class(dataio.sample_rate, nb_channel, 32768, 'float32')

        peakdetector.change_params(**peak_detector_params)

        for ch_idx in range(n_channels_per_array):
            ch_arrays = ArrayCollection()
            ch_arrays.initialize_array('all_peaks', 'ram', _dtype_peak, (-1,))

            for seg_num in range(dataio.nb_segment):

                peakdetector.change_params(**peak_detector_params)  # this reset the fifo index

                iterator = dataio.iter_over_chunk(seg_num=seg_num, chan_grp=array_idx, chunksize=32768, i_stop=None,
                                                  signal_type='processed')
                for pos, preprocessed_chunk in iterator:
                    preprocessed_chunk=np.expand_dims(preprocessed_chunk[:,ch_idx],axis=1)
                    n_peaks, chunk_peaks = peakdetector.process_data(pos, preprocessed_chunk)

                    if chunk_peaks is not None:
                        peaks = np.zeros(chunk_peaks.size, dtype=_dtype_peak)
                        peaks['index'] = chunk_peaks
                        peaks['segment'][:] = seg_num
                        ch_arrays.append_chunk('all_peaks', peaks)

            print('Exporting %s - ch %d' % (array,ch_idx))
            data = {'array': [], 'electrode': [], 'segment': [], 'time': []}

            ch_peaks=ch_arrays.get('all_peaks')
            for chunk in ch_peaks:
                for (index,segment) in chunk:
                    data['array'].append(array)
                    data['electrode'].append(ch_idx)
                    data['segment'].append(segment)
                    data['time'].append(index)
            df = pd.DataFrame(data, columns=['array', 'electrode', 'segment', 'time'])
            df.to_csv(os.path.join(output_dir, '%s_%d_multiunit.csv' % (array, ch_idx)), index=False)

if __name__=='__main__':
    subject=sys.argv[1]
    recording_date=sys.argv[2]

    data_dir = os.path.join('/media/ferrarilab/2C042E4D35A4CAFF/tool_learning/data/recordings/rhd2000/', subject, recording_date)
    print(data_dir)
    if os.path.exists(data_dir):
        if os.path.exists(data_dir):

            extract_multiunit_spikes(subject, recording_date)


