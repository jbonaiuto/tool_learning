import os
from glob import glob
from datetime import datetime
import pandas as pd
import numpy as np
import scipy.io
import sys

arrays = ['F1', 'F5hand', 'F5mouth', '46v-12r', '45a', 'F2']

def run_process_spikes(subj_name, date):

    trial_info=pd.read_csv(os.path.join('/data/tool_learning/preprocessed_data/', subj_name, date,'trial_info.csv'))

    # Get times and recording start times
    trial_times = []
    trial_start_times = []
    srate = 30000.0
    rec_data_dir = os.path.join('/data/tool_learning/recordings/rhd2000', subj_name, date)
    rec_fnames = glob(os.path.join(rec_data_dir, '*rec_signal.mat'))
    rec_fdates = []
    for rec_fname in rec_fnames:
        fparts = os.path.splitext(rec_fname)[0].split('_')
        try:
            filedate = datetime.strptime('%s.%s' % (fparts[-4], fparts[-3]), '%d%m%y.%H%M%S')
            rec_fdates.append(filedate)
        except:
            pass
    rec_fnames = [x[1] for x in sorted(zip(rec_fdates, rec_fnames))]
    for rec_fname in rec_fnames:
        mat = scipy.io.matlab.loadmat(rec_fname)
        rec_signal = mat['rec_signal'][0, :]
        times = np.linspace(1 / srate, rec_signal.size / srate, rec_signal.size)
        recording_signal_diff = np.diff(rec_signal)
        trial_start_idx = np.where(recording_signal_diff == 1)[0][0]
        trial_start_time = times[trial_start_idx]
        trial_times.append(times)
        trial_start_times.append(trial_start_time)

    assert(len(trial_start_times)==len(trial_info.trial))

    out_dir = os.path.join('/data/tool_learning/preprocessed_data/', subj_name, date)
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)

    spike_data_dir = os.path.join('/data/tool_learning/spike_sorting', subj_name, date)

    # Import spikes
    for array_idx, region in enumerate(arrays):

        fnames = glob(os.path.join(spike_data_dir, 'array_%d' % array_idx, '%s*.csv' % region))
        for fname in fnames:
            electrode_df = pd.read_csv(fname)
            for trial_idx in np.unique(electrode_df.segment):
                trial_rows = np.where(electrode_df.segment == trial_idx)[0]
                trial_spike_idx = np.int64(electrode_df.time[trial_rows])
                trial_spike_times = (trial_times[trial_idx][trial_spike_idx] - trial_start_times[trial_idx])*1000.0
                electrode_df.time.update(pd.Series(trial_spike_times, index=trial_rows))
            electrode_df.rename(columns={"segment": "trial"},inplace=True)
            electrode_df.to_csv(os.path.join(out_dir,os.path.split(fname)[1]),index=False)

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    run_process_spikes(subject, recording_date)