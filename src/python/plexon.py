import os

import neo
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt

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


class PlexonRecordingSet:
    """
    A set of plexon files for recording of a subject in a single day (multiple sessions)
    """

    def __init__(self, subj_name, date, data_dir, log_set, output_dir):
        self.subj_name=subj_name
        self.date=date
        self.data_dir=data_dir
        self.output_dir=output_dir

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
                                                   os.path.join(self.data_dir, plx_file_name), log, self.output_dir))

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


class PlexonRecording:
    """
    A plexon file for one recording session
    """

    def __init__(self, subj_name, date, task, session_num, data_file, log, output_dir):
        self.subj_name=subj_name
        self.date=date
        self.task=task
        self.session_num=session_num
        self.file=data_file
        self.output_dir=output_dir

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
        df.to_csv(os.path.join(self.output_dir,'%s_matched_start_stop.csv' % base))

        # Split events into trial and save event time as relative to trial start
        for i in range(len(self.trial_start_times)):
            events = {}
            trial_start = self.trial_start_times[i]
            trial_stop = self.trial_stop_times[i]
            for evt_code in event_channels.keys():
                events[evt_code] = event_times[evt_code][np.where((event_times[evt_code] >= trial_start) &
                                                                  (event_times[evt_code] <= trial_stop))[0]] - trial_start
            self.trial_events.append(events)

        # Plot events prefiltered
        plotted_evts=[]
        fig = plt.figure(figsize=[12,10])
        ax = plt.subplot(111)
        for evt_code in event_channels.keys():
            evt_trial = []
            evt_times = []
            for i in range(len(self.trial_events)):
                events = self.trial_events[i]
                if len(events[evt_code]) > 0 and len(events['reward'])>0:
                    evt_trial.extend((i * np.ones(events[evt_code].shape)).tolist())
                    evt_times.extend(events[evt_code])
            if len(evt_times) > 0:
                ax.plot(evt_times, evt_trial, '.',label=evt_code, alpha=0.2)
                plotted_evts.append(evt_code)

        # Clean events
        self.filter_events()

        ax.set_prop_cycle(None)

        for evt_code in plotted_evts:
            evt_trial = []
            evt_times = []
            for i in range(len(self.trial_events)):
                events = self.trial_events[i]
                if len(events[evt_code]) > 0 and len(events['reward'])>0:
                    evt_trial.extend((i * np.ones([len(events[evt_code]),1])).tolist())
                    evt_times.extend(events[evt_code])
            ax.plot(evt_times, evt_trial, '.', label=evt_code, alpha=1.0)
        # xl = ax.get_xlim()
        # for i in range(len(self.trial_events)):
        #     ax.plot(xl, [i, i], 'grey')
        box = ax.get_position()
        ax.set_position([box.x0, box.y0, box.width * 0.8, box.height])
        # Put a legend to the right of the current axis
        ax.legend(loc='center left', bbox_to_anchor=(1, 0.5))
        fig.savefig(os.path.join(self.output_dir, '%s_events.png' % base))
        fig.clf()
        plt.close()

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

    # Trap bottom (place) should be between trap edge (grasp) and reward
    if len(trial['trap_bottom']):
        trial=filter_event(trial, 'trap_bottom', np.min, after_evt='go', before_evt='trap_edge')
    # Trap edge (grasp) should be after handle off
    if len(trial['trap_edge']):
        trial = filter_event(trial, 'trap_edge', np.min, after_evt='go', before_evt='trial_stop')
    # Handle off should be after go
    if len(trial['monkey_handle_off']):
        trial = filter_event(trial, 'monkey_handle_off', np.min, after_evt='go', before_evt='trap_edge')

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


def filter_event(trial, evt, func, after_evt=None, before_evt=None, min_var=None):
    evt_times = trial[evt]
    if min_var is not None and np.std(evt_times)>min_var:
        trial[evt]=[]
    else:
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