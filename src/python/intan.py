import glob
import json
import os
from datetime import datetime

import numpy as np
from matplotlib import pyplot as plt

import rhd
from config import read_config

cfg = read_config()

condition_pulse_codes={
    3:'visual_grasp_right',
    5:'visual_rake_pull_right',
    7:'visual_rake_push_right',
    9:'visual_pliers_right',
    11:'visual_stick_right',
    13:'visual_grasp_left',
    15:'visual_rake_pull_left',
    17:'visual_rake_push_left',
    19:'visual_pliers_left',
    21:'visual_stick_left',
    23:'motor_grasp',
    25:'motor_rake'
}

class IntanRecordingSet:
    """
    A set of intan recording files for a single subject and a single day (multiple sessions)
    """

    def __init__(self, subj_name, date, data_dir, output_dir, data_files, plot_rec=True):
        self.subj_name=subj_name
        self.date=date
        self.data_dir=data_dir
        self.srate=cfg['intan_srate']

        self.data_files=data_files
        self.trial_files=[]
        self.trial_seg_idxs=[]
        self.trial_tasks=[]
        self.trial_durations=[]
        self.trial_start_idxs=[]
        self.trial_end_idxs=[]
        self.trial_times=[]

        # Trials coming from an intan file with any problem in the recordng signal
        self.bad_recording_signal_trials=[]

        self.read_files(data_files, output_dir, plot_rec)

    """
    Read all intan files for the given day
    """
    def read_files(self, data_files, output_dir, plot_rec):

        cutoff_dur_ms = None
        cutoff_file = None
        cutoff_seg_idx = None
        cutoff_seg_start_idx = None
        cutoff_seg_end_idx = None
        cutoff_seg_times = None

        # Split files into trials
        for idx, data_file in enumerate(data_files):

            (path, root) = os.path.split(data_file['fname'])
            (prefix, ext) = os.path.splitext(root)
            json_fname=os.path.join(output_dir, '%s.json' % prefix)

            if os.path.exists(json_fname):
                rec_data = json.load(open(json_fname))
                rec_signal = np.array(rec_data['rec_signal'])
            else:
                # Read recording signal
                data=rhd.read_data(data_file['fname'], no_floats=True)
                if data['board_dig_in_data'].shape[0]>1:
                    rec_signal=data['board_dig_in_data'][2,:]
                else:
                    rec_signal = data['board_dig_in_data'][0, :]
                rec_signal=rec_signal.astype(int)

                # Write recording signal to output
                with open(json_fname, 'w') as outfile:
                    json.dump({'rec_signal': rec_signal.tolist()}, outfile)

            # Find trial start and end points
            trial_start = np.where(np.diff(rec_signal) == 1)[0]+1
            trial_end = np.where(np.diff(rec_signal) == -1)[0]

            times = np.linspace(1 / self.srate, rec_signal.size / self.srate, rec_signal.size)*1000
            bad_rec_signal = False

            # Start of next trial at end
            if len(trial_start)>1 and len(trial_end)>0 and trial_start[-1]>trial_end[-1]:
                if cutoff_file is not None:
                    print('cutoff without end of trial')
                cutoff_dur_ms=(len(rec_signal)-trial_start[-1])/self.srate*1000.0
                cutoff_file=data_file['fname']
                cutoff_seg_idx=idx
                cutoff_seg_start_idx = trial_start[-1]
                cutoff_seg_end_idx = len(rec_signal) - 1
                cutoff_seg_times = times
                trial_start=trial_start[0:-1]
                bad_rec_signal=True

            # Start of last trial at beginning
            if len(trial_start)>0 and len(trial_end)>1 and trial_end[0]<trial_start[0]:
                if cutoff_file is None:
                    print('end of trial without start')
                else:
                    self.trial_durations.append(trial_end[0]/self.srate*1000.0+cutoff_dur_ms)
                    self.trial_tasks.append(data_file['task'])
                    self.trial_files.append(';'.join([cutoff_file, data_file['fname']]))
                    self.trial_seg_idxs.append([cutoff_seg_idx,idx])
                    self.trial_start_idxs.append([cutoff_seg_start_idx, 0])
                    self.trial_end_idxs.append([cutoff_seg_end_idx, trial_end[0]])
                    self.trial_times.append([cutoff_seg_times, times])
                    cutoff_seg_idx = None
                    cutoff_seg_start_idx = None
                    cutoff_seg_end_idx = None
                    cutoff_seg_times = None
                    cutoff_file=None
                    cutoff_dur_ms=None
                trial_end=trial_end[1:]
                bad_rec_signal=True

            if len(trial_start) > 0 and len(trial_end) > 0:
                if len(trial_start)>len(trial_end):
                    print('more trial start')
                    trial_start=trial_start[0:-1]
                    bad_rec_signal=True
                elif len(trial_start) < len(trial_end):
                    print('more trial end')
                    trial_end=trial_end[1:]
                    bad_rec_signal=True

            if len(trial_start) > 0 and len(trial_end) > 0:
                # Number of time steps between each up and down state switch
                dur_steps=trial_end-trial_start

                nz_steps=np.where(dur_steps>1)[0]
                if len(nz_steps) > 0:
                    if len(nz_steps) > 1:
                        print('too many nz steps')
                        bad_rec_signal = True
                    dur_step=trial_end[nz_steps]-trial_start[nz_steps]
                    dur_ms = dur_step / self.srate * 1000
                    for nz_idx,d in zip(nz_steps,dur_ms):
                        self.trial_durations.append(d)
                        self.trial_tasks.append(data_file['task'])
                        self.trial_files.append(data_file['fname'])
                        self.trial_seg_idxs.append([idx])
                        self.trial_start_idxs.append([trial_start[nz_idx]])
                        self.trial_end_idxs.append([trial_end[nz_idx]])
                        self.trial_times.append([times])
                else:
                    print('no nz steps')
                    self.trial_durations.append(-1)
                    self.trial_tasks.append(data_file['task'])
                    self.trial_files.append(data_file['fname'])
                    self.trial_seg_idxs.append([])
                    self.trial_start_idxs.append([])
                    self.trial_end_idxs.append([])
                    self.trial_times.append([])
                    bad_rec_signal=True


            # If there is a trial start and no trial end - files are split into two if longer than 60s
            elif len(trial_start)>0 and len(trial_end)==0:
                bad_rec_signal=True
                # Recording goes until end of file
                dur_step = len(rec_signal) - trial_start[0]
                # Ignore single time step blups
                if dur_step > 1:
                    if cutoff_file is not None:
                        print('cutoff without end of trial')
                    cutoff_dur_ms = dur_step / self.srate * 1000
                    cutoff_file = data_file['fname']
                    cutoff_seg_idx=idx
                    cutoff_seg_start_idx = trial_start[-1]
                    cutoff_seg_end_idx = len(rec_signal) - 1
                    cutoff_seg_times = times
                    #if dur_ms < 10000:
                    #self.trial_durations.append(dur_ms)
                    #self.tasks.append(task)
                    #self.files.append(file)
                    #self.postcutoff_trial_files.append(len(self.files)-1)
                else:
                    print('blip')
            # If there is a trial end and no trial start- files are split into two if longer than 60s
            elif len(trial_start)==0 and len(trial_end)>0:
                bad_rec_signal=True
                # Recording starts at beginning of file
                dur_step = trial_end[0]
                # Ignore single time step blips
                if dur_step > 1:
                    if cutoff_file is None:
                        print('end of trial without start')
                        self.trial_durations.append(-1)
                        self.trial_tasks.append(data_file['task'])
                        self.trial_files.append(data_file['fname'])
                        self.trial_seg_idxs.append([])
                        self.trial_start_idxs.append([])
                        self.trial_end_idxs.append([])
                        self.trial_times.append([])
                    else:
                        dur_ms = dur_step / self.srate * 1000
                        self.trial_durations.append(cutoff_dur_ms+dur_ms)
                        self.trial_tasks.append(data_file['task'])
                        self.trial_files.append(';'.join([cutoff_file, data_file['fname']]))
                        self.trial_seg_idxs.append([cutoff_seg_idx,idx])
                        self.trial_start_idxs.append([cutoff_seg_start_idx, 0])
                        self.trial_end_idxs.append([cutoff_seg_end_idx, trial_end[0]])
                        self.trial_times.append([cutoff_seg_times, times])
                        cutoff_seg_idx = None
                        cutoff_seg_start_idx = None
                        cutoff_seg_end_idx = None
                        cutoff_seg_times = None
                        cutoff_dur_ms=None
                        cutoff_file=None
                    #if dur_ms < 10000:
                    #self.trial_durations.append(dur_ms)
                    #self.tasks.append(task)
                    #self.files.append(file)
                    #self.precutoff_trial_files.append(len(self.files) - 1)
                else:
                    print('blip')
            else:
                print('no start/stop times')
                dur_ms = len(rec_signal) / self.srate * 1000
                # if dur_ms < 10000:
                self.trial_durations.append(dur_ms-2000)
                self.trial_tasks.append(data_file['task'])
                self.trial_files.append(data_file['fname'])
                self.trial_seg_idxs.append([idx])
                self.trial_start_idxs.append([self.srate])
                self.trial_end_idxs.append([len(rec_signal)-self.srate])
                self.trial_times.append([times])
                bad_rec_signal=True

            if bad_rec_signal:
                if plot_rec:
                    save_rec_signal_image(times, rec_signal, os.path.join(output_dir, '%s.png' % prefix))
                self.bad_recording_signal_trials.append(len(self.trial_files) - 1)

    """
    Get toal number of trials
    """
    def total_trials(self):
        return len(self.trial_durations)


def save_rec_signal_image(times,rec_signal, fname):
    fig, ax = plt.subplots(ncols=1, nrows=1)
    ax.plot(times,rec_signal)
    fig.savefig(fname)
    fig.clf()
    plt.close()