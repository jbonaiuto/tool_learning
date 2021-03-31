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

        # Create directories for output
        preproc_dir=os.path.join(cfg['preprocessed_data_dir'], subj_name, date)
        if not os.path.exists(preproc_dir):
            os.mkdir(preproc_dir)
        out_dir = os.path.join(preproc_dir, 'spikes')
        if not os.path.exists(out_dir):
            os.mkdir(out_dir)

        # Find intan dir
        for x in cfg['intan_data_dirs']:
            if os.path.exists(os.path.join(x, subj_name, date)):
                intan_data_dir = os.path.join(x, subj_name, date)
                break

        # Read and sort intan files
        data_file_names = []
        for x in os.listdir(intan_data_dir):
            if os.path.splitext(x)[1] == '.rhd':
                print(x)
                data_file_names.append(x)
        data_file_times = []
        for idx, fname in enumerate(data_file_names):
            fparts = fname.split('_')
            filedate = datetime.strptime('%s %s' % (fparts[-2], fparts[-1].split('.')[0]), '%y%m%d %H%M%S')
            data_file_times.append(filedate)
        data_file_names = [x for _, x in sorted(zip(data_file_times, data_file_names))]

        seg_idx=[]
        seg_trial_start_idx=[]
        seg_trial_end_idx=[]
        seg_times=[]
        srate = cfg['intan_srate']

        cutoff_seg_idx=None
        cutoff_seg_start_idx=None
        cutoff_seg_end_idx=None
        cutoff_seg_times=None

        # Process intan files in same way as process_trial_info
        for s_idx, intan_file in enumerate(sorted(data_file_names)):
            (bas,ext)=os.path.splitext(intan_file)
            rec_fname=os.path.join(cfg['preprocessed_data_dir'], subj_name, date,'rhd2000','%s.json' % bas)
            rec_data = json.load(open(rec_fname))
            rec_signal = np.array(rec_data['rec_signal'])

            time = np.linspace(1 / srate, rec_signal.size / srate, rec_signal.size)

            # Find trial start and end points
            trial_start = np.where(np.diff(rec_signal) == 1)[0]+1
            trial_end = np.where(np.diff(rec_signal) == -1)[0]

            # Start of next trial at end
            if len(trial_start) > 1 and len(trial_end) > 0 and trial_start[-1] > trial_end[-1]:
                if cutoff_seg_idx is not None:
                    print('cutoff without end of trial')
                cutoff_seg_idx=s_idx
                cutoff_seg_start_idx=trial_start[-1]
                cutoff_seg_end_idx=len(rec_signal)-1
                cutoff_seg_times=time
                trial_start = trial_start[0:-1]

            # Start of last trial at beginning
            if len(trial_start) > 0 and len(trial_end) > 1 and trial_end[0] < trial_start[0]:
                if cutoff_seg_idx is None:
                    print('end of trial without start')
                else:
                    seg_idx.append([cutoff_seg_idx,s_idx])
                    seg_trial_start_idx.append([cutoff_seg_start_idx,0])
                    seg_trial_end_idx.append([cutoff_seg_end_idx,trial_end[0]])
                    seg_times.append([cutoff_seg_times, time])
                    cutoff_seg_idx = None
                    cutoff_seg_start_idx = None
                    cutoff_seg_end_idx = None
                    cutoff_seg_times = None
                trial_end = trial_end[1:]

            if len(trial_start) > 0 and len(trial_end) > 0:
                if len(trial_start) > len(trial_end):
                    print('more trial start')
                    trial_start = trial_start[0:-1]
                elif len(trial_start) < len(trial_end):
                    print('more trial end')
                    trial_end = trial_end[1:]

            if len(trial_start) > 0 and len(trial_end) > 0:
                # Number of time steps between each up and down state switch
                dur_steps = trial_end - trial_start

                nz_steps = np.where(dur_steps > 1)[0]
                if len(nz_steps) > 0:
                    if len(nz_steps) > 1:
                        print('too many nz steps')
                    for nz_idx in nz_steps:
                        seg_idx.append([s_idx])
                        seg_trial_start_idx.append([trial_start[nz_idx]])
                        seg_trial_end_idx.append([trial_end[nz_idx]])
                        seg_times.append([time])
                else:
                    print('no nz steps')
                    seg_idx.append([s_idx])
                    seg_trial_start_idx.append([])
                    seg_trial_end_idx.append([])
                    seg_times.append([])


            # If there is a trial start and no trial end - files are split into two if longer than 60s
            elif len(trial_start) > 0 and len(trial_end) == 0:
                # Recording goes until end of file
                dur_step = len(rec_signal) - trial_start[0]
                # Ignore single time step blups
                if dur_step > 1:
                    if cutoff_seg_idx is not None:
                        print('cutoff without end of trial')
                    cutoff_seg_idx = s_idx
                    cutoff_seg_start_idx = trial_start[-1]
                    cutoff_seg_end_idx = len(rec_signal)-1
                    cutoff_seg_times = time
                    # if dur_ms < 10000:
                    # self.trial_durations.append(dur_ms)
                    # self.tasks.append(task)
                    # self.files.append(file)
                    # self.postcutoff_trial_files.append(len(self.files)-1)
                else:
                    print('blip')
            # If there is a trial end and no trial start- files are split into two if longer than 60s
            elif len(trial_start) == 0 and len(trial_end) > 0:
                # Recording starts at beginning of file
                dur_step = trial_end[0]
                # Ignore single time step blips
                if dur_step > 1:
                    if cutoff_seg_idx is None:
                        print('end of trial without start')
                        seg_idx.append([s_idx])
                        seg_trial_start_idx.append([])
                        seg_trial_end_idx.append([])
                        seg_times.append([])
                    else:
                        seg_idx.append([cutoff_seg_idx, s_idx])
                        seg_trial_start_idx.append([cutoff_seg_start_idx, 0])
                        seg_trial_end_idx.append([cutoff_seg_end_idx, trial_end[0]])
                        seg_times.append([cutoff_seg_times, time])
                        cutoff_seg_idx = None
                        cutoff_seg_start_idx = None
                        cutoff_seg_end_idx = None
                        cutoff_seg_times = None
                    # if dur_ms < 10000:
                    # self.trial_durations.append(dur_ms)
                    # self.tasks.append(task)
                    # self.files.append(file)
                    # self.precutoff_trial_files.append(len(self.files) - 1)
                else:
                    print('blip')
            else:
                print('no start/stop times')
                # if dur_ms < 10000:
                seg_idx.append([s_idx])
                seg_trial_start_idx.append([])
                seg_trial_end_idx.append([])
                seg_times.append([])


        # Import spikes
        for array_idx, region in enumerate(cfg['arrays']):
            print(region)
            fnames = glob(os.path.join(spike_data_dir, 'array_%d' % array_idx, '%s*.csv' % region))
            for fname in fnames:
                electrode_df = pd.read_csv(fname)
                new_data={'array':[], 'electrode':[], 'cell':[], 'trial':[], 'time':[]}

                for t_idx, (idx, trial_start_idx, trial_end_idx, times) in enumerate(zip(seg_idx, seg_trial_start_idx, seg_trial_end_idx, seg_times)):
                    if len(trial_start_idx)>0:
                        spike_times = []
                        spike_cells = []
    
                        time_offset=0
                        for sub_idx, (x_idx, x_start_idx, x_end_idx, x_times) in enumerate(zip(idx, trial_start_idx, trial_end_idx, times)):
                            seg_start_time=x_times[int(x_start_idx)]
                            seg_rows=np.where(electrode_df.segment==x_idx)[0]
                            seg_spike_idx = np.int64(electrode_df.time[seg_rows])
                            seg_cells = np.int64(electrode_df.cell[seg_rows])
                            if len(seg_rows)==1:
                                if seg_spike_idx>=x_start_idx and seg_spike_idx<=x_end_idx:
                                    trial_spike_times=(x_times[seg_spike_idx]-seg_start_time)+time_offset
                                    spike_times.append(trial_spike_times)
                                    spike_cells.append(seg_cells)
                            else:
                                trial_rows = np.where((seg_spike_idx >= x_start_idx) &
                                                      (seg_spike_idx <= x_end_idx))[0]
                                trial_spike_times = (x_times[seg_spike_idx[trial_rows]] - seg_start_time)+time_offset
                                spike_times.extend(trial_spike_times)
                                spike_cells.extend(seg_cells[trial_rows])
                            time_offset=time_offset+(x_times[-1]-seg_start_time)
                                    
                        for spike_time, spike_cell in zip(spike_times,spike_cells):
                            new_data['array'].append(array_idx)
                            new_data['electrode'].append(electrode_df.electrode[seg_rows[0]])
                            new_data['cell'].append(spike_cell)
                            new_data['trial'].append(t_idx)
                            new_data['time'].append(spike_time)



                # trial_idx=0
                #
                # for seg_idx in np.unique(electrode_df.segment):
                #     trial_start_idx=seg_trial_start_idx[seg_idx]
                #     trial_end_idx=seg_trial_end_idx[seg_idx]
                #     trial_start_time=seg_times[seg_idx][int(trial_start_idx)]
                #
                #     seg_rows = np.where(electrode_df.segment == seg_idx)[0]
                #     seg_spike_idx = np.int64(electrode_df.time[seg_rows])
                #     spike_times=[]
                #     if len(seg_rows)==1:
                #         if seg_spike_idx>=trial_start_idx and seg_spike_idx<=trial_end_idx:
                #             trial_spike_times=seg_times[seg_idx][seg_spike_idx]
                #             spike_times=trial_spike_times-trial_start_time
                #             new_data['array'].append(electrode_df.array[seg_rows[0]])
                #             new_data['electrode'].append(electrode_df.electrode[seg_rows[0]])
                #             new_data['cell'].append(electrode_df.cell[seg_rows[0]])
                #             new_data['trial'].append(trial_idx)
                #             new_data['time'].append(spike_times)
                #     else:
                #         trial_rows=np.where((seg_spike_idx>=trial_start_idx) &
                #                             (seg_spike_idx<=trial_end_idx))[0]
                #         trial_spike_times=seg_times[seg_idx][seg_spike_idx[trial_rows]]
                #
                #         spike_times=trial_spike_times-trial_start_time
                #         new_data['array'].extend(electrode_df.array[seg_rows[trial_rows]])
                #         new_data['electrode'].extend(electrode_df.electrode[seg_rows[trial_rows]])
                #         new_data['cell'].extend(electrode_df.cell[seg_rows[trial_rows]])
                #         new_data['trial'].extend((trial_idx*np.ones(len(trial_rows))).tolist())
                #         new_data['time'].extend(spike_times)
                #     trial_idx=trial_idx+1
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
