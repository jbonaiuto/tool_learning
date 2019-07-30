import json
import os
from glob import glob
from datetime import datetime, timedelta
import pandas as pd
import numpy as np
import scipy.io
import sys

arrays = ['F1', 'F5hand', 'F5mouth', '46v-12r', '45a', 'F2']

def run_process_spikes(subj_name, date):

    out_dir = os.path.join('/data/tool_learning/preprocessed_data/', subj_name, date, 'spikes')
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)
    spike_data_dir = os.path.join('/data/tool_learning/spike_sorting', subj_name, date)

    rec_data_dir = os.path.join('/data/tool_learning/preprocessed_data/', subj_name, date,'rhd2000')
    rec_fnames = glob(os.path.join(rec_data_dir, '*.json'))
    rec_fdates = []
    for rec_fname in rec_fnames:
        fparts = os.path.splitext(rec_fname)[0].split('_')
        try:
            filedate = datetime.strptime('%s.%s' % (fparts[-2], fparts[-1]), '%d%m%y.%H%M%S')
            rec_fdates.append(filedate)
        except:
            pass
    rec_fnames = [x[1] for x in sorted(zip(rec_fdates, rec_fnames))]

    seg_trial_start_idx=[]
    seg_trial_end_idx=[]
    seg_trial_start_evt_idx=[]
    seg_times=[]
    srate = 30000.0

    for rec_fname in rec_fnames:
        rec_data = json.load(open(rec_fname))
        rec_signal = np.array(rec_data['rec_signal'])

        time = np.linspace(1 / srate, rec_signal.size / srate, rec_signal.size)
        seg_times.append(time)

        # Find trial start and end points
        trial_start = np.where(np.diff(rec_signal) == 1)[0]
        trial_end = np.where(np.diff(rec_signal) == -1)[0]

        # If there is at least one start and stop time
        if len(trial_start) > 0 and len(trial_end) > 0:

            add_extra=False
            extra_start_idx=[]
            extra_end_idx=[]
            extra_start_evt_idx=[]
            if len(trial_start) > len(trial_end):
                last_trial_start = trial_start[-1]
                # Recording goes until end of file
                dur_step = len(rec_signal) - last_trial_start
                # Ignore single time step blups
                if dur_step > 1:
                    add_extra=True
                    extra_start_idx=[np.max([0, last_trial_start - srate])]
                    extra_end_idx=[len(rec_signal) - 1]
                    extra_start_evt_idx=[last_trial_start]
                trial_start = trial_start[0:-1]
            elif len(trial_end) > len(trial_start):
                first_trial_end = trial_end[0]
                # Recording starts at beginning of file
                dur_step = first_trial_end
                # Ignore single time step blips
                if dur_step > 1:
                    seg_trial_start_idx.append([0])
                    seg_trial_end_idx.append([np.min([len(rec_signal) - 1, first_trial_end + srate])])
                    seg_trial_start_evt_idx.append([0])
                trial_end = trial_end[1:]

            # Number of time steps between each up and down state switch
            dur_steps = trial_end - trial_start

            trial_start_idx=[]
            trial_end_idx=[]
            trial_start_evt_idx=[]
            # For each trial in the file
            for idx,dur_step in enumerate(dur_steps):
                # Ignore single time step blups
                if dur_step > 1:
                    trial_start_idx.append(np.max([0, trial_start[idx]-srate]))
                    trial_end_idx.append(np.min([len(rec_signal)-1, trial_end[idx]+srate]))
                    trial_start_evt_idx.append(trial_start[idx])
            seg_trial_start_idx.append(trial_start_idx)
            seg_trial_end_idx.append(trial_end_idx)
            seg_trial_start_evt_idx.append(trial_start_evt_idx)

            if add_extra:
                seg_trial_start_idx.append(extra_start_idx)
                seg_trial_end_idx.append(extra_end_idx)
                seg_trial_start_evt_idx.append(extra_start_evt_idx)

        # If there is a trial start and no trial end
        elif len(trial_start) > 0 and len(trial_end) == 0:
            # Recording goes until end of file
            dur_step = len(rec_signal) - trial_start
            # Ignore single time step blups
            if dur_step > 1:
                seg_trial_start_idx.append([np.max([0,trial_start[0]-srate])])
                seg_trial_end_idx.append([len(rec_signal)-1])
                seg_trial_start_evt_idx.append([trial_start[0]])
        # If there is a trial end and no trial start
        elif len(trial_start) == 0 and len(trial_end) > 0:
            # Recording starts at beginning of file
            dur_step = trial_end
            # Ignore single time step blips
            if dur_step > 1:
                seg_trial_start_idx.append([0])
                seg_trial_end_idx.append([np.min([len(rec_signal)-1, trial_end[0]+srate])])
                seg_trial_start_evt_idx.append([0])

    # Import spikes
    for array_idx, region in enumerate(arrays):

        fnames = glob(os.path.join(spike_data_dir, 'array_%d' % array_idx, '%s*.csv' % region))
        for fname in fnames:
            electrode_df = pd.read_csv(fname)
            new_data={'array':[], 'electrode':[], 'cell':[], 'trial':[], 'time':[]}

            trial_idx=0

            for seg_idx in np.unique(electrode_df.segment):
                seg_rows = np.where(electrode_df.segment == seg_idx)[0]
                seg_spike_idx = np.int64(electrode_df.time[seg_rows])

                trial_start_idx=seg_trial_start_idx[seg_idx]
                trial_end_idx=seg_trial_end_idx[seg_idx]
                trial_start_evt_idx=seg_trial_start_evt_idx[seg_idx]

                for t_idx in range(len(trial_start_idx)):
                    trial_rows=np.where((seg_spike_idx>=trial_start_idx[t_idx]) &
                                        (seg_spike_idx<=trial_end_idx[t_idx]))[0]
                    trial_spike_times=seg_times[seg_idx][seg_spike_idx[trial_rows]]
                    trial_start_time=seg_times[seg_idx][int(trial_start_evt_idx[t_idx])]
                    spike_times=trial_spike_times-trial_start_time

                    new_data['array'].extend(electrode_df.array[seg_rows[trial_rows]])
                    new_data['electrode'].extend(electrode_df.electrode[seg_rows[trial_rows]])
                    new_data['cell'].extend(electrode_df.cell[seg_rows[trial_rows]])
                    new_data['trial'].extend((trial_idx*np.ones(len(trial_rows))).tolist())
                    new_data['time'].extend(spike_times)
                    trial_idx=trial_idx+1
            df = pd.DataFrame(new_data, columns=['array', 'electrode', 'cell', 'trial', 'time'])
            df.to_csv(os.path.join(out_dir,os.path.split(fname)[1]),index=False)


def rerun(subject, date_start_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_now = datetime.now()

    current_date = date_start
    while current_date <= date_now:
        date_str = datetime.strftime(current_date, '%d.%m.%y')
        recording_path = os.path.join('/media/ferrarilab/2C042E4D35A4CAFF/tool_learning/data/recordings/rhd2000', subject, date_str)
        if os.path.exists(recording_path):

            run_process_spikes(subject, date_str)

        current_date = current_date + timedelta(days=1)
        date_now = datetime.now()

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    run_process_spikes(subject, recording_date)
    #rerun(subject, recording_date)