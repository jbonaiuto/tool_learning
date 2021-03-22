import json

import matplotlib.pyplot as plt
import glob
from datetime import datetime, timedelta
import os
import sys

import neo
import numpy as np
import pandas as pd

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
log_condition_map={
    'motor-grasp_left': 'motor_grasp_left',
    'motor-grasp_center': 'motor_grasp_center',
    'motor-grasp_right': 'motor_grasp_right',
    'motor-rake_center' : 'motor_rake_center',
    'motor-rake_center with cube': 'motor_rake_center',
    'motor-rake_center catch': 'motor_rake_center_catch',
    'Rake pull_right': 'visual_rake_pull_right',
    'Rake pull_left': 'visual_rake_pull_left',
    'Pliers_right': 'visual_pliers_right',
    'Pliers_left': 'visual_pliers_left',
    'Grasping_right': 'visual_grasp_right',
    'Grasping_left': 'visual_grasp_left',
    'Fixation_': 'fixation',
    'Fixation_Center': 'fixation',
    'motor-rake_right': 'motor_rake_right',
    'motor-rake_left': 'motor_rake_left',
    'motor-rake_right-cube': 'motor_rake_right',
    'motor-rake_right-food': 'motor_rake_food_right',
    'motor-rake_left-cube': 'motor_rake_left',
    'motor-rake_left-food': 'motor_rake_food_left',
    'motor-rake_center-cube': 'motor_rake_center',
    'motor-rake_center-food': 'motor_rake_food_center',
    'Rake push_left': 'visual_rake_push_left',
    'Rake push_right': 'visual_rake_push_right',
    'Stick_left': 'visual_stick_left',
    'Stick_right': 'visual_stick_right'
}
event_channels={
    #'exp_start_on': 0,
    'exp_place_right': 1,
    'exp_grasp_center': 2,
    'exp_place_left': 3,
    'monkey_handle_on': 4,
    'monkey_tool_right':5,
    'monkey_tool_mid_right': 6,
    'monkey_tool_center': 7,
    'monkey_tool_mid_left': 8,
    'monkey_tool_left': 9,
    'trap_edge': 10,
    'trap_bottom': 11,
    'monkey_rake_handle': 12,
    'monkey_rake_blade': 13,
    'reward': 14,
    'error': 15,
    'exp_start_off': 16,
    'monkey_handle_off': 17,
    'laser_exp_start_right': 18,
    'laser_exp_start_left': 19,
    'laser_exp_start_center': 20,
    #'manual_reward': 23,
    #'manual_error': 24,
    'go':25,
    'laser_monkey_tool_center': 26,
    'trial_start': 27,
    'trial_stop': 28,
}
visual_trial_events=['trial_start','trial_stop','error','exp_grasp_center','exp_place_left','exp_place_right', 'go',
                     'laser_exp_start_center', 'reward','exp_start_off','tool_start_off']
motor_grasp_trial_events=['trial_start', 'trial_stop', 'error', 'go', 'laser_monkey_tool_center', 'reward',
                          'trap_bottom', 'monkey_handle_off', 'trap_edge']
fixation_trial_events=['trial_start','trial_stop','error','go','laser_exp_start_center','reward']
motor_rake_trial_events=['trial_start', 'trial_stop', 'error', 'go', 'laser_monkey_tool_center', 'reward',
                         'monkey_handle_off', 'monkey_tool_right', 'monkey_tool_mid_right', 'monkey_tool_center',
                         'monkey_tool_mid_left', 'monkey_tool_left', 'trap_edge', 'trap_bottom', 'monkey_rake_handle',
                         'monkey_rake_blade']


class Logger(object):
    def __init__(self, fname):
        self.terminal = sys.stdout
        self.log = open(fname,'w')

    def write(self, message):
        self.terminal.write(message)
        self.log.write(message)

    def flush(self):
        #this flush method is needed for python 3 compatibility.
        #this handles the flush command by doing nothing.
        #you might want to specify some extra behavior here.
        pass


"""
A set of log files for recording of a subject in a single day (multiple sessions)
"""
class EventIDELogSet:
    def __init__(self, subj_name, date, log_dir, plexon_data_dir):
        self.subj_name=subj_name
        self.date=date
        self.log_dir=log_dir

        self.logs=[]

        self.read_log_files(plexon_data_dir)


    """
    Read log files for this day
    """
    def read_log_files(self, plexon_data_dir):
        recording_date = datetime.strptime(self.date, '%d.%m.%y')

        # Get list of all log file names, tasks, and timestamps
        log_file_tasks = []
        log_file_names = []
        log_file_dates = []
        for x in os.listdir(self.log_dir):
            if os.path.splitext(x)[1] == '.csv':
                fparts = os.path.splitext(x)[0].split('_')
                try:
                    filedate = datetime.strptime(fparts[-1], '%Y-%d-%m--%H-%M')
                    if filedate.year == recording_date.year and filedate.month == recording_date.month and filedate.day == recording_date.day:
                        log_file_tasks.append('_'.join(fparts[0:-1]))
                        log_file_dates.append(filedate)
                        log_file_names.append(x)
                except:
                    pass

        # Sort files by timestamp
        sorted_logs = sorted(zip(log_file_dates, log_file_tasks, log_file_names))
        log_file_names = [x[2] for x in sorted_logs]
        log_file_tasks = [x[1] for x in sorted_logs]

        # Only read log files for which there is a corresponding plexon recording
        last_session_number = {}
        for log_file, task in zip(log_file_names,log_file_tasks):
            # Figure out session number
            if not task in last_session_number:
                session_number = 1
            else:
                session_number = last_session_number[task] + 1
            last_session_number[task] = session_number

            plx_file_name = '%s_%s_%s_%d.plx' % (self.subj_name, task, self.date, session_number)
            if os.path.exists(os.path.join(plexon_data_dir, plx_file_name)):
                self.logs.append(EventIDELog(self.subj_name,self.date,task,os.path.join(self.log_dir,log_file)))
        return log_file_names, log_file_tasks


    """
    Get total number of trials
    """
    def total_trials(self):
        total=0
        for log in self.logs:
            total=total+len(log.trial_durations)
        return total

    """
    Get all trial durations
    """
    def trial_durations(self):
        durations=[]
        for log in self.logs:
            durations.extend(log.trial_durations)
        return durations

"""
A log file for one recording session
"""
class EventIDELog:
    def __init__(self, subj_name, date, task, log_file):
        self.subj_name=subj_name
        self.date=date
        self.task=task
        self.file=log_file

        self.trial_conditions = []
        self.trial_durations = []

        self.read_log_file()


    """
    Read trial conditions and durations from log file
    """
    def read_log_file(self):
        # Read log file
        f = open(os.path.join(self.file), 'r')
        trials_started = False
        trial_start = None

        for line in f:
            # Remove extra characters
            line = line.strip()
            # Trial states start after first blank line
            if len(line) == 0:
                trials_started = True
                continue

            if trials_started:
                # Parse line and get trial number
                line_parts = line.split(',')
                # Recording started - parse condition
                if line_parts[5] == 'StartLaser':
                    # location = line_parts[4]
                    # trial_locs.append(location)
                    last_condition = log_condition_map['%s_%s' % (line_parts[3], line_parts[4])]
                    self.trial_conditions.append(last_condition)
                    trial_start = float(line_parts[6])
                elif line_parts[5] == 'EndTrial' and trial_start is not None:
                    trial_end = float(line_parts[6])
                    self.trial_durations.append(trial_end - trial_start)
                    trial_start=None
        f.close()


"""
A set of plexon files for recording of a subject in a single day (multiple sessions)
"""
class PlexonRecordingSet:
    def __init__(self, subj_name, date, data_dir, log_set):
        self.subj_name=subj_name
        self.date=date
        self.data_dir=data_dir

        self.recordings=[]

        self.read_recordings(log_set)


    """
    Read plexon files for this day
    """
    def read_recordings(self, log_set):
        # Session number and last session task (for figuring out plexon filenames)
        last_session_number = {}
        for log in log_set.logs:
            # Figure out session number
            if not log.task in last_session_number:
                session_number = 1
            else:
                session_number = last_session_number[log.task] + 1
            last_session_number[log.task] = session_number

            # If corresponding plexon file exists (recording during this session)
            plx_file_name = '%s_%s_%s_%d.plx' % (self.subj_name, log.task, self.date, session_number)
            self.recordings.append(PlexonRecording(self.subj_name, self.date, log.task, session_number,
                                                   os.path.join(self.data_dir, plx_file_name), log))

    """
    Get total number of trials
    """
    def total_trials(self):
        total=0
        for recording in self.recordings:
            total=total+len(recording.trial_start_times)
        return total

    """
    Get all trial durations
    """
    def trial_durations(self):
        durations = []
        for recording in self.recordings:
            durations.extend(recording.trial_durations.tolist())
        return durations

"""
A plexon file for one recording session
"""
class PlexonRecording:
    def __init__(self, subj_name, date, task, session_num, data_file, log):
        self.subj_name=subj_name
        self.date=date
        self.task=task
        self.session_num=session_num
        self.file=data_file

        self.trial_start_times=[]
        self.trial_stop_times=[]
        self.trial_durations=[]
        self.trial_conditions=[]
        self.trial_events=[]

        self.read_data_file(log)


    """
    Read trial start/stop times and events from plexon file
    """
    def read_data_file(self, log):
        r = neo.io.PlexonIO(filename=self.file)
        block = r.read(lazy=False)[0]

        # Read trial start/stop events and all other events
        start_times=[]
        stop_times=[]
        event_times = {}
        for evt_code in event_channels.keys():
            event_times[evt_code] = []
        for seg_idx, seg in enumerate(block.segments):
            if len(seg.events)>0:
                # Get the start and end times of each trial
                start_times.extend([x.rescale('ms').magnitude.item(0) for x in seg.events[event_channels['trial_start']]])
                stop_times.extend([x.rescale('ms').magnitude.item(0) for x in seg.events[event_channels['trial_stop']]])
                # Get time of all events in this segment
                for evt_code in event_channels.keys():
                    event_times[evt_code].extend([x.rescale('ms').magnitude.item(0) for x in seg.events[event_channels[evt_code]]])
                    
        for evt_code in event_channels.keys():
            event_times[evt_code]=np.array(event_times[evt_code])

        # Match start/stop events
        (matched_start_idx,matched_stop_idx)=self.match_trial_start_stop_times(log, start_times, stop_times)
        d={'matched_start_idx':matched_start_idx, 'matched_stop_idx':matched_stop_idx}
        df=pd.DataFrame(data=d)
        (pth,f)=os.path.split(self.file)
        (base,ext)=os.path.splitext(f)
        out_dir = os.path.join(cfg['preprocessed_data_dir'], self.subj_name, self.date)
        if not os.path.exists(out_dir):
            os.mkdir(out_dir)
        df.to_csv(os.path.join(out_dir,'%s_matched_start_stop.csv' % base))

        # Split events into trial and save event time as relative to trial start
        for i in range(len(self.trial_start_times)):
            events = {}
            trial_start = self.trial_start_times[i]
            trial_stop = self.trial_stop_times[i]
            for evt_code in event_channels.keys():
                events[evt_code] = event_times[evt_code][np.where((event_times[evt_code] >= trial_start) &
                                                                  (event_times[evt_code] <= trial_stop))[0]] - trial_start
            self.trial_events.append(events)

        # Clean events
        self.filter_events()


    """
    Match trial start and stop events based on correspondence between trial duration in log file
    """
    def match_trial_start_stop_times(self, log, start_times, stop_times):
        # List of matched times
        matched_start_times = []
        matched_stop_times = []
        matched_start_idx=[]
        matched_stop_idx=[]

        # Index of current start time event
        curr_start_idx = 0
        last_end_idx = -1

        # For each trial in the log
        for log_idx in range(len(log.trial_durations)):

            # Get the trial duration according to the log file
            log_duration = log.trial_durations[log_idx]

            # Find matching start/stop times in plexon
            matched = False
            for start_idx in range(curr_start_idx, len(start_times)):

                # End event to start looking from
                curr_end_idx = last_end_idx + 1

                # Current trial duration
                last_dur = stop_times[curr_end_idx] - start_times[start_idx]

                # Initialize matched stop time index
                matched_end_idx = curr_end_idx

                # Look for better stop time index
                for end_idx in range(curr_end_idx + 1, len(stop_times)):

                    # Update matched stop time index if trial duration closer to that of log file
                    trial_dur = stop_times[end_idx] - start_times[start_idx]
                    if trial_dur > 0 and np.abs(trial_dur - log_duration) < np.abs(last_dur - log_duration):  # and trial_dur<12000:
                        matched_end_idx = end_idx
                    last_dur = trial_dur

                # Final best matching trial duration
                curr_dur = stop_times[matched_end_idx] - start_times[start_idx]

                # If within 10ms of log trial duration, match was successful
                if curr_dur > 0 and np.abs(curr_dur - log_duration) <= 10:
                    matched_start_times.append(start_times[start_idx])
                    matched_stop_times.append(stop_times[matched_end_idx])
                    matched_start_idx.append(start_idx)
                    matched_stop_idx.append(matched_end_idx)
                    matched = True
                    break

            # Start looking from next start event if matched
            if matched:
                last_end_idx=matched_end_idx
                curr_start_idx = curr_start_idx + 1
            else:
                matched_start_times.append(float('NaN'))
                matched_stop_times.append(float('NaN'))
                matched_start_idx.append(-1)
                matched_stop_idx.append(-1)

        self.trial_start_times = np.array(matched_start_times)
        self.trial_stop_times = np.array(matched_stop_times)
        self.trial_durations = self.trial_stop_times - self.trial_start_times
        self.trial_conditions = log.trial_conditions

        return (matched_start_idx,matched_stop_idx)

    """
    Filter events
    """
    def filter_events(self):

        for t_idx in range(len(self.trial_events)):
            if self.task == 'visual_task_training' or self.task == 'visual_task_stage1-2' or self.task=='visual_task_stage3' or self.task=='visual_task_stage4':
                self.trial_events[t_idx] = filter_visual_events(self.trial_events[t_idx], self.trial_conditions[t_idx])

            elif self.task == 'motor_task_training' or self.task == 'motor_task_grasp':
                self.trial_events[t_idx] = filter_motor_grasp_events(self.trial_events[t_idx])

            elif self.task == 'fixation_training' or self.task=='fixation':
                self.trial_events[t_idx] = filter_fixation_events(self.trial_events[t_idx])

            elif self.task == 'motor_task_rake' or self.task == 'motor_task_rake_catch':
                self.trial_events[t_idx] = filter_motor_rake_events(self.trial_events[t_idx])



"""
A set of intan recording files for a single subject and a single day (multiple sessions)
"""
class IntanRecordingSet:
    def __init__(self, subj_name, date, data_dir, output_dir):
        self.subj_name=subj_name
        self.date=date
        self.data_dir=data_dir
        self.srate=cfg['intan_srate']

        self.files=[]
        self.tasks=[]
        self.trial_durations=[]

        # Files where trial recording is cutoff
        self.precutoff_trial_files=[]
        self.postcutoff_trial_files = []

        self.read_files(output_dir)

    """
    Read all intan files for the given day
    """
    def read_files(self, output_dir):

        # Read all RHD files and sort by timestamp
        files = glob.glob(os.path.join(self.data_dir, '*.rhd'))
        file_datetimes = []
        file_tasks=[]
        for fname in files:
            (path,root)=os.path.split(fname)
            (prefix,ext)=os.path.splitext(root)
            file_datetimes.append(datetime.strptime(prefix.split('_')[-1],'%H%M%S'))
            file_tasks.append('_'.join(prefix.split('_')[1:-2]))
        sorted_files=sorted(zip(file_datetimes,files,file_tasks))

        # Split files into trials
        for idx, (time, file, task) in enumerate(sorted_files):

            (path, root) = os.path.split(file)
            (prefix, ext) = os.path.splitext(root)
            json_fname=os.path.join(output_dir, '%s.json' % prefix)

            if os.path.exists(json_fname):
                rec_data = json.load(open(json_fname))
                rec_signal = np.array(rec_data['rec_signal'])
            else:
                # Read recording signal
                data=rhd.read_data(file, no_floats=True)
                if data['board_dig_in_data'].shape[0]>1:
                    rec_signal=data['board_dig_in_data'][2,:]
                else:
                    rec_signal = data['board_dig_in_data'][0, :]
                rec_signal=rec_signal.astype(int)

                # Write recording signal to output
                with open(json_fname, 'w') as outfile:
                    json.dump({'rec_signal': rec_signal.tolist()}, outfile)

            # Find trial start and end points
            trial_start = np.where(np.diff(rec_signal) == 1)[0]
            trial_end = np.where(np.diff(rec_signal) == -1)[0]

            times=np.array(range(len(rec_signal)))/self.srate*1000
            plot = False

            # If there is at least one start and stop time
            if len(trial_start)>0 and len(trial_end)>0:

                # Start of next trial at end
                if trial_start[-1]>trial_end[-1]:
                    trial_start=trial_start[0:-1]
                    plot=True

            if len(trial_start) > 0 and len(trial_end) > 0:
                # Start of last trial at beginnig
                if trial_end[0]<trial_start[0]:
                    trial_end=trial_end[1:]
                    plot=True

            if len(trial_start) > 0 and len(trial_end) > 0:
                if len(trial_start)>len(trial_end):
                    print('more trial start')
                    trial_start=trial_start[0:-1]
                    plot=True
                elif len(trial_start) < len(trial_end):
                    print('more trial end')
                    trial_end=trial_end[1:]
                    plot=True

            if len(trial_start) > 0 and len(trial_end) > 0:
                # Number of time steps between each up and down state switch
                dur_steps=trial_end-trial_start

                nz_steps=np.where(dur_steps>1)[0]
                if len(nz_steps)==1:
                    dur_step=dur_steps[nz_steps[0]]
                    dur_ms = dur_step / self.srate * 1000
                    self.trial_durations.append(dur_ms)
                    self.tasks.append(task)
                    self.files.append(file)
                elif len(nz_steps)>1:
                    print('too many nz steps')
                    trial_start_ms=trial_start/self.srate*1000
                    best_start_idx=np.argmin(np.abs(trial_start_ms-1000))
                    trial_end_ms=trial_end/self.srate*1000
                    trial_dur_ms=len(rec_signal)/self.srate*1000
                    best_end_idx=np.argmin(np.abs(trial_end_ms-(trial_dur_ms-1000)))
                    dur_step=trial_end[best_end_idx]-trial_start[best_start_idx]
                    dur_ms = dur_step / self.srate * 1000
                    self.trial_durations.append(dur_ms)
                    self.tasks.append(task)
                    self.files.append(file)
                    plot=True
                else:
                    print('no nz steps')
                    self.trial_durations.append(0)
                    self.tasks.append(task)
                    self.files.append(file)
                    plot=True


            # If there is a trial start and no trial end - files are split into two if longer than 60s
            elif len(trial_start)>0 and len(trial_end)==0:
                plot=True
                # Recording goes until end of file
                dur_step = len(rec_signal) - trial_start[0]
                # Ignore single time step blups
                if dur_step > 1:
                    dur_ms = dur_step / self.srate * 1000
                    #if dur_ms < 10000:
                    self.trial_durations.append(dur_ms)
                    self.tasks.append(task)
                    self.files.append(file)
                    self.postcutoff_trial_files.append(len(self.files)-1)
                else:
                    print('blip')
            # If there is a trial end and no trial start- files are split into two if longer than 60s
            elif len(trial_start)==0 and len(trial_end)>0:
                plot=True
                # Recording starts at beginning of file
                dur_step = trial_end[0]
                # Ignore single time step blips
                if dur_step > 1:
                    dur_ms = dur_step / self.srate * 1000
                    #if dur_ms < 10000:
                    self.trial_durations.append(dur_ms)
                    self.tasks.append(task)
                    self.files.append(file)
                    self.precutoff_trial_files.append(len(self.files) - 1)
                else:
                    print('blip')

            if plot:
                save_rec_signal_image(times, rec_signal, os.path.join(output_dir, '%s.png' % prefix))

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

def run_process_trial_info(subj_name, date):
    log_dir = os.path.join(cfg['log_dir'], subj_name)
    plx_data_dir=None
    intan_data_dir=None
    for x in cfg['plexon_data_dirs']:
        if os.path.exists(os.path.join(x,subj_name, date)):
            plx_data_dir=os.path.join(x,subj_name, date)
            break
    for x in cfg['intan_data_dirs']:
        if os.path.exists(os.path.join(x,subj_name, date)):
            intan_data_dir=os.path.join(x,subj_name, date)
            break

    if plx_data_dir is not None and intan_data_dir is not None:
        # Create output dir
        out_dir = os.path.join(cfg['preprocessed_data_dir'], subj_name, date)
        if not os.path.exists(out_dir):
            os.mkdir(out_dir)
        rhd_rec_out_dir = os.path.join(out_dir, 'rhd2000')
        if not os.path.exists(rhd_rec_out_dir):
            os.mkdir(rhd_rec_out_dir)

        sys.stdout=Logger(os.path.join(out_dir, 'process_trial_info.log'))

        print(date)

        # Read log and plexon files
        log_set=EventIDELogSet(subj_name, date, log_dir, plx_data_dir)
        plexon_set=PlexonRecordingSet(subj_name, date, plx_data_dir, log_set)

        # Make sure there is same number of trials in each
        assert (log_set.total_trials() == plexon_set.total_trials())
        # Check trial durations
        assert(np.nanmax(np.abs(np.array(log_set.trial_durations())-np.array(plexon_set.trial_durations())))<10)

        # Read intan files
        intan_set=IntanRecordingSet(subj_name, date, intan_data_dir, rhd_rec_out_dir)

        # Trial info
        trial_info = {
            'overall_trial': [],
            'block': [],
            'task': [],
            'trial': [],
            'condition': [],
            'reward': [],
            'status': [],
            'log_file': [],
            'plexon_file': [],
            'intan_file': [],
            'log_trial_idx': [],
            'plexon_trial_idx': [],
            'intan_trial_idx': [],
            'log_duration': [],
            'plexon_duration': [],
            'intan_duration': []
        }
        # Trial events
        trial_event_info = []

        # Currently mapped session number and trial
        current_session_num=0
        curr_trial_num = -1
        last_block = -1
        plexon_start=0

        # Go through each intan file
        for t_idx in range(len(intan_set.files)):
            # Get duration and task
            intan_dur=intan_set.trial_durations[t_idx]
            intan_task=intan_set.tasks[t_idx]

            # Try to match to plexon trial
            matched=False
            # Stop looking if last session matched the intan task
            last_session_task_matched=False
            for session_idx in range(current_session_num,len(plexon_set.recordings)):
                if plexon_set.recordings[session_idx].task==intan_task:
                    for plx_t_idx in range(plexon_start,len(plexon_set.recordings[session_idx].trial_durations)):

                        # Check trial durations for match within 2ms
                        plx_dur=plexon_set.recordings[session_idx].trial_durations[plx_t_idx]
                        log_dur=log_set.logs[session_idx].trial_durations[plx_t_idx]
                        dur_delta=np.abs(plx_dur-intan_dur)
                        if dur_delta>=0 and dur_delta<=2:
                            matched=True
                            current_session_num=session_idx

                            if session_idx!=last_block:
                                curr_trial_num = 0

                            task=plexon_set.recordings[session_idx].task
                            trial_condition=log_set.logs[session_idx].trial_conditions[plx_t_idx]
                            trial_events=plexon_set.recordings[session_idx].trial_events[plx_t_idx]
                            error = check_trial(task, session_idx, curr_trial_num, trial_condition, trial_events)

                            # Add trial information
                            trial_info['overall_trial'].append(t_idx)
                            trial_info['block'].append(session_idx)
                            trial_info['trial'].append(curr_trial_num)
                            trial_info['task'].append(task)
                            trial_info['condition'].append(trial_condition)
                            trial_info['reward'].append(len(plexon_set.recordings[session_idx].trial_events[plx_t_idx]['reward'])>0)
                            status='good'
                            #if t_idx in intan_set.multiple_trial_files or t_idx in intan_set.cutoff_trial_files or error:
                            if t_idx in intan_set.precutoff_trial_files or t_idx in intan_set.postcutoff_trial_files or error:
                                status='bad'
                            trial_info['status'].append(status)
                            trial_info['log_file'].append(os.path.split(log_set.logs[session_idx].file)[1])
                            trial_info['plexon_file'].append(os.path.split(plexon_set.recordings[session_idx].file)[1])
                            trial_info['intan_file'].append(os.path.split(intan_set.files[t_idx])[1])
                            trial_info['log_trial_idx'].append(plx_t_idx)
                            trial_info['plexon_trial_idx'].append(plx_t_idx)
                            trial_info['intan_trial_idx'].append(t_idx)
                            trial_info['log_duration'].append(log_dur)
                            trial_info['plexon_duration'].append(plx_dur)
                            trial_info['intan_duration'].append(intan_dur)
                            trial_event_info.append(trial_events)

                            plexon_start=plx_t_idx+1
                            break
                    # Start at first trial of next session if not matched
                    if matched:
                        break
                    else:
                        plexon_start = 0

                    last_session_task_matched=True
                elif last_session_task_matched:
                    break
                else:
                    plexon_start = 0

            # Add to trial info even if not matched
            if not matched:
                trial_info['overall_trial'].append(t_idx)
                # Try to figure out block number
                if len(trial_info['task'])>0:
                    if intan_task==trial_info['task'][-1]:
                        trial_info['block'].append(trial_info['block'][-1])
                    else:
                        trial_info['block'].append(trial_info['block'][-1]+1)
                    if trial_info['block'][-1] != last_block:
                        curr_trial_num = 0
                else:
                    trial_info['block'].append(0)
                    curr_trial_num=0
                trial_info['trial'].append(curr_trial_num)
                trial_info['task'].append(intan_task)
                trial_info['condition'].append('')
                trial_info['reward'].append(False)
                trial_info['status'].append('bad')
                trial_info['log_file'].append('')
                trial_info['plexon_file'].append('')
                trial_info['intan_file'].append(os.path.split(intan_set.files[t_idx])[1])
                trial_info['log_trial_idx'].append(float('NaN'))
                trial_info['plexon_trial_idx'].append(float('NaN'))
                trial_info['intan_trial_idx'].append(t_idx)
                trial_info['log_duration'].append(float('NaN'))
                trial_info['plexon_duration'].append(float('NaN'))
                trial_info['intan_duration'].append(intan_dur)
                trial_event_info.append({})

            last_block = trial_info['block'][-1]
            curr_trial_num = curr_trial_num + 1

        # Check that trial durations match
        assert(np.all(np.isnan(np.array(trial_info['plexon_duration']))) or np.nanmax(np.abs(np.array(trial_info['intan_duration'])-np.array(trial_info['plexon_duration'])))<=2)

        print('Total num trials: log=%d, plexon=%d, intan=%d' % (log_set.total_trials(), plexon_set.total_trials(),
                                                                 len(trial_info['block'])))

        df = pd.DataFrame(trial_info, columns=['overall_trial', 'block', 'task', 'trial', 'condition', 'reward',
                                               'status', 'log_file', 'plexon_file', 'intan_file', 'log_trial_idx',
                                               'plexon_trial_idx', 'intan_trial_idx', 'log_duration',
                                               'plexon_duration', 'intan_duration'])
        df.to_csv(os.path.join(out_dir, 'trial_info.csv'), index=False)

        print('*** Good trials per condition per block ****')
        data={'condition':[],
              'trials':[]}
        all_good_trials={}
        for block in np.unique(df['block']):
            block_rows=np.where(df['block']==block)[0]
            block_task=df['task'][block_rows[0]]
            block_good_trials={}
            for row in block_rows:
                trial_condition=df['condition'][row]
                status=df['status'][row]
                reward=df['reward'][row]
                if not trial_condition in block_good_trials:
                    block_good_trials[trial_condition] = 0
                if status=='good':
                    block_good_trials[trial_condition]=block_good_trials[trial_condition]+1
                    if not trial_condition in all_good_trials:
                        all_good_trials[trial_condition]=0
                    all_good_trials[trial_condition]=all_good_trials[trial_condition]+1
            print('Block %d - %s' % (block, block_task))
            for key, val in block_good_trials.items():
                print('%s - %d trials' % (key, val))
        print('*** Good trials per condition overall ****')
        for key, val in all_good_trials.items():
            print('%s - %d trials' % (key, val))
            data['condition'].append(key)
            data['trials'].append(val)

        df = pd.DataFrame(data, columns=['condition','trials'])
        df.to_csv(os.path.join(out_dir, 'trial_numbers.csv'), index=False)

        # Write to csv
        fid = open(os.path.join(out_dir, 'trial_events.csv'), 'w')
        fid.write('trial,event,time\n')
        for trial_idx, trial in enumerate(trial_event_info):
            for evt_code in trial.keys():
                if len(trial[evt_code]) > 0:
                    fid.write('%d,%s,%.4f\n' % (trial_idx, evt_code, trial[evt_code][0]))
        fid.close()


def filter_visual_events(trial, condition):
    # Remove extra events
    for evt_code in trial.keys():
        if not evt_code in visual_trial_events:
            trial[evt_code] = []

    # Reliable visual task events
    if len(trial['error']):
        trial=filter_event(trial, 'error', np.min, after_evt='trial_start')
    if len(trial['reward']):
        trial = filter_event(trial, 'reward', np.min, after_evt='trial_start')
    if len(trial['laser_exp_start_center']):
        trial = filter_event(trial, 'laser_exp_start_center', np.min, after_evt='trial_start', before_evt='trial_stop')
    if len(trial['go']):
        trial = filter_event(trial, 'go', np.min, after_evt='laser_exp_start_center', before_evt='trial_stop')

    # Get first grasp event after go and before reward
    if len(trial['exp_grasp_center']):
        trial = filter_event(trial, 'exp_grasp_center', np.min, after_evt='go', before_evt='reward')
    # Start offset should be between go and grasp
    if len(trial['exp_start_off']):
        if not (condition=='visual_grasp_right' or condition=='visual_grasp_left'):
            if len(trial['exp_grasp_center']) and len(trial['go']):
                pre_grasp_start_off=trial['exp_start_off'][np.where((trial['exp_start_off']<trial['exp_grasp_center'][0]) & (trial['exp_start_off']>trial['go'][0]))[0]]

                splits=np.where(np.diff(pre_grasp_start_off)>10)[0]
                if len(splits)>0:
                    trial['exp_start_off']=[np.min(pre_grasp_start_off[0:splits[0]+1])]
                    trial['tool_start_off'] = [np.min(pre_grasp_start_off[splits[0]+1:])]
            else:
                splits = np.where(np.diff(trial['exp_start_off']) > 10)[0]
                if len(splits) > 0:
                    trial['tool_start_off'] = [np.min(trial['exp_start_off'][splits[0]+1:])]
                    trial['exp_start_off'] = [np.min(trial['exp_start_off'][0:splits[0] + 1])]
        else:
            # For tool trials there will be two start off events
            trial=filter_event(trial, 'exp_start_off', np.max, after_evt='go', before_evt='exp_grasp_center')
    # Place should be after grasp and before reward
    if len(trial['exp_place_left']):
        trial=filter_event(trial, 'exp_place_left', np.min, after_evt='exp_grasp_center', before_evt='trial_stop')
    # Place should be after grasp
    if len(trial['exp_place_right']):
        trial=filter_event(trial, 'exp_place_right', np.min, after_evt='exp_grasp_center', before_evt='trial_stop')
    return trial


def filter_motor_grasp_events(trial):
    # Remove extra events
    for evt_code in trial.keys():
        if not evt_code in motor_grasp_trial_events:
            trial[evt_code] = []

    # Reliable motor task events
    if len(trial['error']):
        trial=filter_event(trial, 'error', np.min, after_evt='trial_start')
    if len(trial['reward']):
        trial = filter_event(trial, 'reward', np.min, after_evt='trial_start')
    if len(trial['laser_monkey_tool_center']):
        trial = filter_event(trial, 'laser_monkey_tool_center', np.min, after_evt='trial_start', before_evt='trial_stop')
    if len(trial['go']):
        trial = filter_event(trial, 'go', np.min, after_evt='laser_monkey_tool_center', before_evt='trial_stop')

    # Handle off should be after go
    if len(trial['monkey_handle_off']):
        trial=filter_event(trial, 'monkey_handle_off', np.min, after_evt='go', before_evt='trial_stop')
    # Trap edge (grasp) should be after handle off
    if len(trial['trap_edge']):
        trial=filter_event(trial, 'trap_edge', np.min, after_evt='monkey_handle_off', before_evt='trial_stop')
    # Trap bottom (place) should be between trap edge (grasp) and reward
    if len(trial['trap_bottom']):
        trial=filter_event(trial, 'trap_bottom', np.min, after_evt='trap_edge', before_evt='trial_stop')
    return trial


def filter_motor_rake_events(trial):
    # Remove extra events
    for evt_code in trial.keys():
        if not evt_code in motor_rake_trial_events:
            trial[evt_code] = []

    # Reliable motor task events
    if len(trial['error']):
        trial = filter_event(trial, 'error', np.min, after_evt='trial_start')
    if len(trial['reward']):
        trial = filter_event(trial, 'reward', np.min, after_evt='trial_start')
    if len(trial['go']):
        trial = filter_event(trial, 'go', np.min, after_evt='trial_start', before_evt='trial_stop')

    # Handle off should be after go
    if len(trial['monkey_handle_off']):
        trial=filter_event(trial, 'monkey_handle_off', np.min, after_evt='go', before_evt='trial_stop')
    # Rake handle should be after handle off
    if len(trial['monkey_rake_handle']):
        trial=filter_event(trial, 'monkey_rake_handle', np.min, after_evt='monkey_handle_off', before_evt='trial_stop')
    # Tocchino should be after rake handle
    if len(trial['monkey_tool_right']):
        trial = filter_event(trial, 'monkey_tool_right', np.min, after_evt='monkey_rake_handle', before_evt='trial_stop')
    if len(trial['monkey_tool_mid_right']):
        trial = filter_event(trial, 'monkey_tool_mid_right', np.min, after_evt='monkey_rake_handle', before_evt='trial_stop')
    if len(trial['monkey_tool_center']):
        trial = filter_event(trial, 'monkey_tool_center', np.min, after_evt='monkey_rake_handle', before_evt='trial_stop')
    if len(trial['monkey_tool_mid_left']):
        trial = filter_event(trial, 'monkey_tool_mid_left', np.min, after_evt='monkey_rake_handle', before_evt='trial_stop')
    if len(trial['monkey_tool_left']):
        trial = filter_event(trial, 'monkey_tool_left', np.min, after_evt='monkey_rake_handle', before_evt='trial_stop')
    # Rake blade should be after rake handle
    if len(trial['monkey_rake_blade']):
        trial=filter_event(trial, 'monkey_rake_blade', np.min, after_evt='monkey_rake_handle', before_evt='trial_stop')
    # Trap edge should be after rake blade
    if len(trial['trap_edge']):
        trial=filter_event(trial, 'trap_edge', np.min, after_evt='monkey_rake_blade', before_evt='trial_stop')
    # Trap bottom should be after trap edge and before reward
    if len(trial['trap_bottom']):
        trial=filter_event(trial, 'trap_bottom', np.min, after_evt='trap_edge', before_evt='trial_stop')
    return trial


def filter_fixation_events(trial):
    # Remove extra events
    for evt_code in trial.keys():
        if not evt_code in visual_trial_events:
            trial[evt_code] = []

    # Reliable visual task events
    if len(trial['error']):
        trial = filter_event(trial, 'error', np.min)
    if len(trial['reward']):
        trial = filter_event(trial, 'reward', np.min)
    if len(trial['laser_exp_start_center']):
        trial = filter_event(trial, 'laser_exp_start_center', np.min)
    if len(trial['go']):
        trial = filter_event(trial, 'go', np.min)
    return trial


def filter_event(trial, evt, func, after_evt=None, before_evt=None):
    evt_times = trial[evt]
    if after_evt is not None and len(trial[after_evt]) and before_evt is not None and len(trial[before_evt]):
        after_evt_time = trial[after_evt][0]
        before_evt_time = trial[before_evt][0]
        mid_times=evt_times[np.where((evt_times > after_evt_time) & (evt_times < before_evt_time))[0]]
        if len(mid_times):
            trial[evt] = [func(mid_times)]
        else:
            trial[evt] = [func(evt_times)]
    elif after_evt is not None and len(trial[after_evt]) and before_evt is None:
        after_evt_time = trial[after_evt][0]
        mid_times = evt_times[np.where(evt_times > after_evt_time)[0]]
        if len(mid_times):
            trial[evt] = [func(mid_times)]
        else:
            trial[evt] = [func(evt_times)]
    elif after_evt is None and before_evt is not None and len(trial[before_evt]):
        before_evt_time = trial[before_evt][0]
        mid_times=evt_times[np.where(evt_times < before_evt_time)[0]]
        if len(mid_times):
            trial[evt] = [func(mid_times)]
        else:
            trial[evt] = [func(evt_times)]
    else:
        trial[evt] = [func(evt_times)]
    return trial


def check_trial(task, block_idx, trial_idx, condition, trial_events):
    evts = []
    evt_times = []
    for evt in trial_events.keys():
        time_list = trial_events[evt]
        if len(time_list) > 0:
            evts.append(evt)
            evt_times.append(time_list[0])
    sorted_evts = [x[1] for x in sorted(zip(evt_times, evts))]
    sorted_times = [x[0] for x in sorted(zip(evt_times, evts))]

    error = False
    if task == 'visual_task_training' or task == 'visual_task_stage1-2' or task=='visual_task_stage3' or task=='visual_task_stage4':
        error = check_visual_trial(block_idx, trial_idx, condition, sorted_evts)
    elif task == 'motor_task_training' or task == 'motor_task_grasp':
        error = check_motor_grasp_trial(block_idx, trial_idx, condition, sorted_evts)
    elif task == 'motor_task_rake' or task == 'motor_task_rake_catch':
        error = check_motor_rake_trial(block_idx, trial_idx, condition, sorted_evts)
    elif task == 'fixation_training':
        error = check_fixation_trial(block_idx, trial_idx, condition, sorted_evts)

    return error


def check_visual_trial(block_idx, trial_idx, condition, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        print('Error, block %d, trial %d-%s, error' % (block_idx, trial_idx, condition))
        error=True
    else:
        if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
            print('Error, block %d, trial %d-%s, first event not trial start' % (block_idx, trial_idx, condition))
            error = True

        start_idx = sorted_evts.index('trial_start')
        if not sorted_evts[start_idx + 1] == 'laser_exp_start_center':
            print('Error, block %d, trial %d-%s, first event after start not laser' % (block_idx, trial_idx, condition))
            error = True

        if 'laser_exp_start_center' in sorted_evts:
            laser_idx = sorted_evts.index('laser_exp_start_center')
            if not sorted_evts[laser_idx + 1] == 'go':
                print('Error, block %d, trial %d-%s, first event after laser not go' % (block_idx, trial_idx, condition))
                error = True
        else:
            print('Error, block %d, trial %d-%s, no laser_exp_start_center event' % (block_idx, trial_idx, condition))
            error=True

        if 'go' in sorted_evts:
            go_idx = sorted_evts.index('go')
            if not sorted_evts[go_idx + 1] == 'exp_start_off':
                print('Error, block %d, trial %d-%s, first event after go not s_off' % (block_idx, trial_idx, condition))
                error = True
        else:
            print('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
            error = True

        if 'exp_start_off' in sorted_evts:
            s_off_idx = sorted_evts.index('exp_start_off')
            if not (condition == 'visual_grasp_right' or condition == 'visual_grasp_left'):
                if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'tool_start_off':
                    print('Error, block %d, trial %d-%s, first event after s_off not tool_start_off' % (block_idx, trial_idx, condition))
                    error = True
            else:
                if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'exp_grasp_center':
                    print('Error, block %d, trial %d-%s, first event after s_off not grasp' % (block_idx, trial_idx, condition))
                    error = True
        else:
            print('Error, block %d, trial %d-%s, no s_off event' % (block_idx, trial_idx, condition))
            error = True

        if not (condition == 'visual_grasp_right' or condition == 'visual_grasp_left'):
            if 'tool_start_off' in sorted_evts:
                s_off_idx = sorted_evts.index('tool_start_off')
                if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'exp_grasp_center':
                    print('Error, block %d, trial %d-%s, first event after tool_start_off not grasp' % (block_idx, trial_idx, condition))
                    error = True
            else:
                print('Error, block %d, trial %d-%s, no tool_start_off event' % (block_idx, trial_idx, condition))
                error = True

        if 'exp_grasp_center' in sorted_evts:
            grasp_idx = sorted_evts.index('exp_grasp_center')
            if grasp_idx >= len(sorted_evts) - 1 or not (sorted_evts[grasp_idx + 1] == 'exp_place_right' or sorted_evts[grasp_idx + 1] == 'exp_place_left'):
                print('Error, block %d, trial %d-%s, first event after grasp not place' % (block_idx, trial_idx, condition))
                error = True
        else:
            print('Error, block %d, trial %d-%s, no grasp event' % (block_idx, trial_idx, condition))
            error = True

        if error:
            print(sorted_evts)
            # print(sorted_times)
            print('\n')

    return error


def check_motor_grasp_trial(block_idx, trial_idx, condition, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        print('Error, block %d, trial %d-%s, error' % (block_idx, trial_idx, condition))
        error=True
    else:
        if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
            print('Error, block %d, trial %d-%s, first event not trial start' % (block_idx, trial_idx, condition))
            error = True

        if 'trial_start' in sorted_evts:
            start_idx = sorted_evts.index('trial_start')
            if not sorted_evts[start_idx + 1] == 'go':
                print('Error, block %d, trial %d-%s, first event after start not go' % (block_idx, trial_idx, condition))
                error = True

        if 'go' in sorted_evts:
            go_idx = sorted_evts.index('go')
            if not sorted_evts[go_idx + 1] == 'monkey_handle_off':
                print('Error, block %d, trial %d-%s, first event after go not monkey_handle_off' % (block_idx, trial_idx, condition))
                error = True
        else:
            print('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
            error = True

        if 'monkey_handle_off' in sorted_evts:
            s_off_idx = sorted_evts.index('monkey_handle_off')
            if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'trap_edge':
                print('Error, block %d, trial %d-%s, first event after monkey_handle_off not trap_edge' % (block_idx, trial_idx, condition))
                error = True
        else:
            print('Error, block %d, trial %d-%s, no monkey_handle_off event' % (block_idx, trial_idx, condition))
            error = True

        if 'trap_edge' in sorted_evts:
            grasp_idx = sorted_evts.index('trap_edge')
            if grasp_idx >= len(sorted_evts) - 1 or not sorted_evts[grasp_idx + 1] == 'trap_bottom':
                print('Error, block %d, trial %d-%s, first event after trap_edge not trap_bottom' % (block_idx, trial_idx, condition))
                error = True
        else:
            print('Error, block %d, trial %d-%s, no trap_edge event' % (block_idx, trial_idx, condition))
            error = True

        if error:
            print(sorted_evts)
            # print(sorted_times)
            print('\n')

    return error


def check_motor_rake_trial(block_idx, trial_idx, condition, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        print('Error, block %d, trial %d-%s, error' % (block_idx, trial_idx, condition))
        error = True
    else:
        if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
            print('Error, block %d, trial %d-%s, first event not trial start' % (block_idx, trial_idx, condition))
            error = True

        if 'trial_start' in sorted_evts:
            start_idx = sorted_evts.index('trial_start')
            if not sorted_evts[start_idx + 1] == 'go':
                print('Error, block %d, trial %d-%s, first event after start not go' % (block_idx, trial_idx, condition))
                error = True

        if 'go' in sorted_evts:
            go_idx = sorted_evts.index('go')
            if not sorted_evts[go_idx + 1] == 'monkey_handle_off':
                print('Error, block %d, trial %d-%s, first event after go not monkey_handle_off' % (block_idx, trial_idx, condition))
                error = True
        else:
            print('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
            error = True

        if 'monkey_handle_off' in sorted_evts:
           s_off_idx = sorted_evts.index('monkey_handle_off')
           if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'monkey_rake_handle':
               print('Error, block %d, trial %d-%s, first event after monkey_handle_off not monkey_rake_handle' % (block_idx, trial_idx, condition))
               error = True
        else:
           print('Error, block %d, trial %d-%s, no monkey_handle_off event' % (block_idx, trial_idx, condition))
           error = True

        #if not 'monkey_rake_handle' in sorted_evts:
        #    print('Error, block %d, trial %d-%s, no monkey_rake_handle event' % (block_idx, trial_idx, condition))
        #    error = True

        # if not 'monkey_handle_off' in sorted_evts:
        #     print('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
        #     error = True

        if condition=='motor_rake_left' or condition=='motor_rake_food_left':
            if not ('monkey_tool_mid_left' in sorted_evts or 'monkey_tool_left' in sorted_evts):
                print('Error, block %d, trial %d-%s, no tool/object contact event' % (block_idx, trial_idx, condition))
                error = True
        elif condition=='motor_rake_right' or condition=='motor_rake_food_right':
            if not ('monkey_tool_right' in sorted_evts or 'monkey_tool_mid_right' in sorted_evts):
                print('Error, block %d, trial %d-%s, no tool/object contact event' % (block_idx, trial_idx, condition))
                error = True
        elif condition=='motor_rake_center' or condition=='motor_rake_food_center':
            if not ('monkey_tool_center' in sorted_evts):
                print('Error, block %d, trial %d-%s, no tool/object contact event' % (block_idx, trial_idx, condition))
                error = True

        if not 'trap_edge' in sorted_evts and not 'trap_bottom' in sorted_evts:
            print('Error, block %d, trial %d-%s, no trap_edge or trap_bottom event' % (block_idx, trial_idx, condition))
            error = True

        # if not 'trap_bottom' in sorted_evts:
        #     print('Error, block %d, trial %d-%s, no trap_bottom event' % (block_idx, trial_idx, condition))
        #     error = True

        # if 'monkey_rake_handle' in sorted_evts:
        #     handle_idx = sorted_evts.index('monkey_rake_handle')
        #     if handle_idx >= len(sorted_evts) - 1 or not sorted_evts[handle_idx + 1] == 'trap_bottom':
        #         print('Error, block %d, trial %d-%s, first event after trap_edge not trap_bottom' % (block_idx, trial_idx, condition))
        #         error = True
        # else:
        #     print('Error, block %d, trial %d-%s, no trap_edge event' % (block_idx, trial_idx, condition))
        #     error = True

        if error:
            print(sorted_evts)
            # print(sorted_times)
            print('\n')

    return error


def check_fixation_trial(block_idx, trial_idx, condition, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        print('Error, block %d, trial %d-%s, error' % (block_idx, trial_idx, condition))
        error=True

    else:
        if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
            print('Error, block %d, trial %d-%s, first event not trial start' % (block_idx, trial_idx, condition))
            error = True
        start_idx = sorted_evts.index('trial_start')
        if not sorted_evts[start_idx + 1] == 'laser_exp_start_center':
            print('Error, block %d, trial %d-%s, first event after start not laser' % (block_idx, trial_idx, condition))
            error = True

        if 'laser_exp_start_center' in sorted_evts:
            laser_idx = sorted_evts.index('laser_exp_start_center')
            if not sorted_evts[laser_idx + 1] == 'go':
                print('Error, block %d, trial %d-%s, first event after laser not go' % (block_idx, trial_idx, condition))
                error = True
        else:
            print('Error, block %d, trial %d-%s, no laser_exp_start_center event' % (block_idx, trial_idx, condition))
            error=True

        if not 'go' in sorted_evts:
            print('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
            error = True

        if error:
            print(sorted_evts)
            # print(sorted_times)
            print('\n')

    return error


def rerun(subject, date_start_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_now = datetime.now()

    current_date = date_start
    while current_date <= date_now:
        date_str = datetime.strftime(current_date, '%d.%m.%y')
        for x in cfg['intan_data_dirs']:

            if os.path.exists(os.path.join(x, subject, date_str)):

                run_process_trial_info(subject, date_str)

        current_date = current_date + timedelta(days=1)
        date_now = datetime.now()

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    #run_process_trial_info(subject, recording_date)
    rerun(subject,recording_date)
