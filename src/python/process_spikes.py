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

        # Find intan diractory
        for x in cfg['intan_data_dirs']:
            if os.path.exists(os.path.join(x, subj_name, date)):
                intan_data_dir = os.path.join(x, subj_name, date)
                break
        # Read intan files
        rhd_rec_out_dir = os.path.join(preproc_dir, 'rhd2000')
        intan_set= intan.IntanRecordingSet(subj_name, date, intan_data_dir, rhd_rec_out_dir, data_files, plot_rec=False)

        # Import spikes
        for array_idx, region in enumerate(cfg['arrays']):
            print(region)

            # Get list of spike files for this array
            fnames = glob(os.path.join(spike_data_dir, 'array_%d' % array_idx, '%s*.csv' % region))

            # For each electrode
            for fname in fnames:

                # Read spike file
                electrode_df = pd.read_csv(fname)

                # Create new data structure
                new_data={'array':[], 'electrode':[], 'cell':[], 'trial':[], 'time':[]}

                # For each trial
                for t_idx in range(len(intan_set.trial_files)):

                    # List of segments corresponding to this trial
                    seg_idxs=intan_set.trial_seg_idxs[t_idx]
                    # Start trial index for each segment
                    seg_start_idxs=intan_set.trial_start_idxs[t_idx]
                    # End trial index for each segment
                    seg_end_idxs=intan_set.trial_end_idxs[t_idx]
                    # Timestamps for each segment
                    seg_times=intan_set.trial_times[t_idx]

                    # If there are any segments that correspond to this trial (can happen that there is no match found)
                    if len(seg_idxs)>0:

                        # Time of each spike in the trial
                        spike_times=[]
                        # Cell for each spike in the trial
                        spike_cells=[]

                        # Time offset in case of multiple segments - offsets the timestamps in the second segment by the
                        # last timestamp of the first
                        time_offset=0

                        # For each segment
                        for sub_idx in range(len(seg_idxs)):

                            # Segment index, start trial index, end trial index, and timestamps
                            sub_seg_idx=seg_idxs[sub_idx]
                            sub_start_idx=seg_start_idxs[sub_idx]
                            sub_end_idx=seg_end_idxs[sub_idx]
                            sub_times=seg_times[sub_idx]

                            # Get timestamp of trial start time
                            sub_start_time=sub_times[int(sub_start_idx)]
                            # Get all rows for this segment
                            sub_seg_rows=np.where(electrode_df.segment==sub_seg_idx)[0]
                            # Get time index of each spike in this segment
                            sub_seg_spike_idx=np.int64(electrode_df.time[sub_seg_rows])
                            # Get cell for each spike in this segment
                            sub_seg_cells=np.int64(electrode_df.cell[sub_seg_rows])

                            # Use only rows for spikes that occur between trial start and trial end
                            trial_rows=np.where((sub_seg_spike_idx>=sub_start_idx) &
                                                (sub_seg_spike_idx<=sub_end_idx))[0]
                            # Compute spike times relative to trial start, adding offset from previous segment
                            trial_spike_times = (sub_times[sub_seg_spike_idx[trial_rows]] - sub_start_time) + time_offset
                            # Cells for spikes that occur in this trial
                            trial_cells=sub_seg_cells[trial_rows]

                            # Save spike times and cells
                            spike_times.extend(trial_spike_times)
                            spike_cells.extend(trial_cells)

                            # Update offset - last timestamp relative to trial start time
                            time_offset=time_offset+(sub_times[-1]-sub_start_time)

                        # Add spikes and cells to new data structure
                        for spike_time, spike_cell in zip(spike_times,spike_cells):
                            new_data['array'].append(array_idx)
                            new_data['electrode'].append(electrode_df.electrode[0])
                            new_data['cell'].append(spike_cell)
                            new_data['trial'].append(t_idx)
                            new_data['time'].append(spike_time)

                # Save new data structure
                df = pd.DataFrame(new_data, columns=['array', 'electrode', 'cell', 'trial', 'time'])
                df.to_csv(os.path.join(out_dir,os.path.split(fname)[1]),index=False)


def rerun(subject, date_start_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_now = datetime.now()

    current_date = date_start
    while current_date <= date_now:
        date_str = datetime.strftime(current_date, '%d.%m.%y')
        base_path = os.path.join(cfg['preprocessed_data_dir'], subject, date_str)
        json_fname=os.path.join(base_path, 'intan_files.json')
        if os.path.exists(json_fname):
            with open(json_fname, 'r') as infile:
                data_files = json.load(infile)
            run_process_spikes(subject, date_str, data_files)

        current_date = current_date + timedelta(days=1)
        date_now = datetime.now()

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]

    recording_path = None
    for x in cfg['intan_data_dirs']:
        if os.path.exists(os.path.join(x, subject, recording_date)):
            base_path = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, recording_date)
            json_fname = os.path.join(base_path, 'intan_files.json')
            if os.path.exists(json_fname):
                with open(json_fname, 'r') as infile:
                    data_files = json.load(infile)
                run_process_spikes(subject, recording_date, data_files)
    #rerun(subject, recording_date)
