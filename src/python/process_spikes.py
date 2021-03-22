import json
import os
from glob import glob
from datetime import datetime, timedelta
import pandas as pd
import numpy as np
import scipy.io
import sys

from config import read_config

cfg = read_config()


def run_process_spikes(subj_name, date):
    spike_data_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subj_name, date)

    if os.path.exists(spike_data_dir):
        preproc_dir=os.path.join(cfg['preprocessed_data_dir'], subj_name, date)
        if not os.path.exists(preproc_dir):
            os.mkdir(preproc_dir)
        out_dir = os.path.join(preproc_dir, 'spikes')
        if not os.path.exists(out_dir):
            os.mkdir(out_dir)

        trial_info=pd.read_csv(os.path.join(preproc_dir,'trial_info.csv'))
        print(date)

        seg_trial_start_idx=[]
        seg_trial_end_idx=[]
        seg_trial_start_evt_idx=[]
        seg_times=[]
        srate = cfg['intan_srate']

        for rec_idx in range(len(trial_info)):
            intan_file=trial_info['intan_file'][rec_idx]
            (bas,ext)=os.path.splitext(intan_file)
            rec_fname=os.path.join(cfg['preprocessed_data_dir'], subj_name, date,'rhd2000','%s.json' % bas)
            rec_data = json.load(open(rec_fname))
            rec_signal = np.array(rec_data['rec_signal'])

            time = np.linspace(1 / srate, rec_signal.size / srate, rec_signal.size)
            seg_times.append(time)

            # Find trial start and end points
            trial_start = np.where(np.diff(rec_signal) == 1)[0]
            trial_end = np.where(np.diff(rec_signal) == -1)[0]

            # If there is at least one start and stop time
            if len(trial_start) > 0 and len(trial_end) > 0:

                trial_start_idx = 0
                trial_end_idx = len(rec_signal) - 1
                trial_start_evt_idx = 0

                if len(trial_start)==2 and len(trial_end)==1 and trial_start[1]>trial_end[0]:
                    trial_start=[trial_start[0]]
                # Start of last trial at beginnig
                elif len(trial_end) == 2 and len(trial_start) == 1 and trial_end[0] < trial_start[0]:
                    trial_end = [trial_end[-1]]
                elif len(trial_start)>len(trial_end):
                    print('more trial start')
                    trial_start = trial_start[0:-1]
                elif len(trial_start) < len(trial_end):
                    print('more trial end')
                    trial_end = trial_end[1:]

                # Number of time steps between each up and down state switch
                dur_steps = trial_end - trial_start

                nz_steps=np.where(dur_steps>5)[0]
                if len(nz_steps)==1:
                    trial_start_idx=np.max([0, trial_start[0] - srate])
                    trial_end_idx=np.min([len(rec_signal) - 1, trial_end[0] + srate])
                    trial_start_evt_idx=trial_start[0]

                elif len(nz_steps)>1:
                    print('too many nz steps')
                    trial_start_idx=np.max([0, trial_start[0] - srate])
                    trial_end_idx=np.min([len(rec_signal) - 1, trial_end[-1] + srate])
                    trial_start_evt_idx=trial_start[0]
                else:
                    print('no nz steps')
                    ##trial_start_idx.append(0)
                    #trial_end_idx.append(len(rec_signal) - 1)
                    #trial_start_evt_idx.append(-1)

                seg_trial_start_idx.append(trial_start_idx)
                seg_trial_end_idx.append(trial_end_idx)
                seg_trial_start_evt_idx.append(trial_start_evt_idx)

            # If there is a trial start and no trial end
            elif len(trial_start) > 0 and len(trial_end) == 0:
                # Recording goes until end of file
                dur_step = len(rec_signal) - trial_start
                # Ignore single time step blups
                if dur_step > 5:
                    seg_trial_start_idx.append(np.max([0,trial_start[0]-srate]))
                    seg_trial_end_idx.append(len(rec_signal)-1)
                    seg_trial_start_evt_idx.append(trial_start[0])
                else:
                    print('blip')
            # If there is a trial end and no trial start
            elif len(trial_start) == 0 and len(trial_end) > 0:
                # Recording starts at beginning of file
                dur_step = trial_end
                # Ignore single time step blips
                if dur_step > 5:
                    seg_trial_start_idx.append(0)
                    seg_trial_end_idx.append(np.min([len(rec_signal)-1, trial_end[0]+srate]))
                    seg_trial_start_evt_idx.append(0)
                else:
                    print('blip')
            else:
                seg_trial_start_idx.append(0)
                seg_trial_end_idx.append(len(rec_signal)-1)
                seg_trial_start_evt_idx.append(0)

        # Import spikes
        for array_idx, region in enumerate(cfg['arrays']):
            print(region)
            fnames = glob(os.path.join(spike_data_dir, 'array_%d' % array_idx, '%s*.csv' % region))
            for fname in fnames:
                electrode_df = pd.read_csv(fname)
                new_data={'array':[], 'electrode':[], 'cell':[], 'trial':[], 'time':[]}

                trial_idx=0

                for seg_idx in np.unique(electrode_df.segment):
                    trial_start_idx=seg_trial_start_idx[seg_idx]
                    trial_end_idx=seg_trial_end_idx[seg_idx]
                    trial_start_evt_idx=seg_trial_start_evt_idx[seg_idx]
                    trial_start_time=seg_times[seg_idx][int(trial_start_evt_idx)]
                    
                    seg_rows = np.where(electrode_df.segment == seg_idx)[0]
                    seg_spike_idx = np.int64(electrode_df.time[seg_rows])
                    spike_times=[]
                    if len(seg_rows)==1:
                        if seg_spike_idx>=trial_start_idx and seg_spike_idx<=trial_end_idx:
                            trial_spike_times=seg_times[seg_idx][seg_spike_idx]
                            spike_times=trial_spike_times-trial_start_time
                            new_data['array'].append(electrode_df.array[seg_rows[0]])
                            new_data['electrode'].append(electrode_df.electrode[seg_rows[0]])
                            new_data['cell'].append(electrode_df.cell[seg_rows[0]])
                            new_data['trial'].append(trial_idx)
                            new_data['time'].append(spike_times)
                    else:                    
                        trial_rows=np.where((seg_spike_idx>=trial_start_idx) &
                                            (seg_spike_idx<=trial_end_idx))[0]
                        trial_spike_times=seg_times[seg_idx][seg_spike_idx[trial_rows]]
                    
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
        exists=False
        for intan_dir in cfg['intan_data_dirs']:
            recording_path = os.path.join(intan_dir, subject, date_str)
            if os.path.exists(recording_path):
                exists=True
                break
        if exists:
            run_process_spikes(subject, date_str)

        current_date = current_date + timedelta(days=1)
        date_now = datetime.now()

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    #run_process_spikes(subject, recording_date)
    rerun(subject, recording_date)
