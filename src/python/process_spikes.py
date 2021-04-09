import json
import os
from glob import glob
from datetime import datetime, timedelta
import pandas as pd
import numpy as np
import scipy.io
import sys
import intan

from config import read_config

cfg = read_config()


def run_process_spikes(subj_name, date, data_files):
    spike_data_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subj_name, date)

    if os.path.exists(spike_data_dir):

        # Create directories for output
        preproc_dir=os.path.join(cfg['preprocessed_data_dir'], subj_name, date)
        if not os.path.exists(preproc_dir):
            os.mkdir(preproc_dir)
        out_dir = os.path.join(preproc_dir, 'spikes')
        if not os.path.exists(out_dir):
            os.mkdir(out_dir)

        for x in cfg['intan_data_dirs']:
            if os.path.exists(os.path.join(x, subj_name, date)):
                intan_data_dir = os.path.join(x, subj_name, date)
                break
        rhd_rec_out_dir = os.path.join(preproc_dir, 'rhd2000')
        intan_set= intan.IntanRecordingSet(subj_name, date, intan_data_dir, rhd_rec_out_dir, data_files, plot_rec=False)

        # Import spikes
        for array_idx, region in enumerate(cfg['arrays']):
            print(region)
            fnames = glob(os.path.join(spike_data_dir, 'array_%d' % array_idx, '%s*.csv' % region))
            for fname in fnames:
                electrode_df = pd.read_csv(fname)
                new_data={'array':[], 'electrode':[], 'cell':[], 'trial':[], 'time':[]}

                for t_idx in range(len(intan_set.trial_files)):
                    seg_idxs=intan_set.trial_seg_idxs[t_idx]
                    seg_start_idxs=intan_set.trial_start_idxs[t_idx]
                    seg_end_idxs=intan_set.trial_end_idxs[t_idx]
                    seg_times=intan_set.trial_times[t_idx]

                    if len(seg_idxs)>0:
                        spike_times=[]
                        spike_cells=[]

                        time_offset=0
                        for sub_idx in range(len(seg_idxs)):
                            sub_seg_idx=seg_idxs[sub_idx]
                            sub_start_idx=seg_start_idxs[sub_idx]
                            sub_end_idx=seg_end_idxs[sub_idx]
                            sub_times=seg_times[sub_idx]

                            sub_start_time=sub_times[int(sub_start_idx)]
                            sub_seg_rows=np.where(electrode_df.segment==sub_seg_idx)[0]
                            sub_seg_spike_idx=np.int64(electrode_df.time[sub_seg_rows])
                            sub_seg_cells=np.int64(electrode_df.cell[sub_seg_rows])

                            trial_rows=np.where((sub_seg_spike_idx>=sub_start_idx) &
                                                (sub_seg_spike_idx<=sub_end_idx))[0]
                            trial_spike_times = (sub_times[sub_seg_spike_idx[trial_rows]] - sub_start_time) + time_offset

                            spike_times.extend(trial_spike_times)
                            spike_cells.extend(sub_seg_cells[trial_rows])
                            time_offset=time_offset+(sub_times[-1]-sub_start_time)

                        for spike_time, spike_cell in zip(spike_times,spike_cells):
                            new_data['array'].append(array_idx)
                            new_data['electrode'].append(electrode_df.electrode[0])
                            new_data['cell'].append(spike_cell)
                            new_data['trial'].append(t_idx)
                            new_data['time'].append(spike_time)

                # for t_idx, (idx, trial_start_idx, trial_end_idx, times) in enumerate(zip(seg_idx, seg_trial_start_idx, seg_trial_end_idx, seg_times)):
                #     if len(trial_start_idx)>0:
                #         spike_times = []
                #         spike_cells = []
                #
                #         time_offset=0
                #         for sub_idx, (x_idx, x_start_idx, x_end_idx, x_times) in enumerate(zip(idx, trial_start_idx, trial_end_idx, times)):
                #             seg_start_time=x_times[int(x_start_idx)]
                #             seg_rows=np.where(electrode_df.segment==x_idx)[0]
                #             seg_spike_idx = np.int64(electrode_df.time[seg_rows])
                #             seg_cells = np.int64(electrode_df.cell[seg_rows])
                #             if len(seg_rows)==1:
                #                 if seg_spike_idx>=x_start_idx and seg_spike_idx<=x_end_idx:
                #                     trial_spike_times=(x_times[seg_spike_idx]-seg_start_time)+time_offset
                #                     spike_times.append(trial_spike_times)
                #                     spike_cells.append(seg_cells)
                #             else:
                #                 trial_rows = np.where((seg_spike_idx >= x_start_idx) &
                #                                       (seg_spike_idx <= x_end_idx))[0]
                #                 trial_spike_times = (x_times[seg_spike_idx[trial_rows]] - seg_start_time)+time_offset
                #                 spike_times.extend(trial_spike_times)
                #                 spike_cells.extend(seg_cells[trial_rows])
                #             time_offset=time_offset+(x_times[-1]-seg_start_time)
                #
                #         for spike_time, spike_cell in zip(spike_times,spike_cells):
                #             new_data['array'].append(array_idx)
                #             new_data['electrode'].append(electrode_df.electrode[seg_rows[0]])
                #             new_data['cell'].append(spike_cell)
                #             new_data['trial'].append(t_idx)
                #             new_data['time'].append(spike_time)



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
        preproc_dir = os.path.join(cfg['preprocessed_data_dir'], subject, date_str)
        json_fname=os.path.join(preproc_dir, 'intan_files.json')
        if os.path.exists(json_fname):
            with open(json_fname, 'r') as infile:
                data_files = json.load(infile)
            run_process_spikes(subject, date_str, data_files)

        current_date = current_date + timedelta(days=1)
        date_now = datetime.now()

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    #run_process_spikes(subject, recording_date)
    rerun(subject, recording_date)
