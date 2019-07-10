from datetime import datetime
import os
import sys

import neo
import numpy as np
import pandas as pd

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
    'motor-rake_left': 'motor_rake_left'
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
    'trial_stop': 28
}
visual_trial_events=['trial_start','trial_stop','error','exp_grasp_center','exp_place_left','exp_place_right', 'go',
                     'laser_exp_start_center', 'reward','exp_start_off']
motor_grasp_trial_events=['trial_start', 'trial_stop', 'error', 'go', 'laser_monkey_tool_center', 'reward',
                          'trap_bottom', 'monkey_handle_off', 'trap_edge']
fixation_trial_events=['trial_start','trial_stop','error','go','laser_exp_start_center','reward']
motor_rake_trial_events=['trial_start', 'trial_stop', 'error', 'go', 'laser_monkey_tool_center', 'reward',
                         'monkey_tool_right', 'monkey_tool_mid_right', 'monkey_tool_center', 'monkey_tool_mid_left',
                         'monkey_tool_left', 'trap_edge', 'trap_bottom', 'monkey_rake_handle', 'monkey_rake_blade']

DATA_DIR='/data/tool_learning/'

def str_to_bool(s):
    if s == 'True' or s=='true' or s=='t' or s=='T' or s=='1':
         return True
    elif s == 'False' or s=='false' or s=='f' or s=='F' or s=='0':
         return False
    else:
         raise ValueError

def run_process_trial_info(subj_name, date):
    # Parse date
    recording_date = datetime.strptime(date, '%d.%m.%y')
    print(date)


    # Directories containing logs and plexon data (events)
    log_dir = os.path.join(DATA_DIR, 'logs', subj_name)
    plx_data_dir = os.path.join(DATA_DIR, 'recordings/plexon/%s/%s' % (subj_name, date))

    if os.path.exists(plx_data_dir):
        # Create output dir
        out_dir = os.path.join(DATA_DIR, 'preprocessed_data/', subj_name, date)
        if not os.path.exists(out_dir):
            os.mkdir(out_dir)

        # Figure out temporal order of log files
        log_file_names, log_file_tasks = order_log_files(log_dir, recording_date)

        # Trial info
        trial_info={
            'block':[],
            'condition':[],
            'correct':[]
        }
        trial_event_info=[]

        # Trial and block index
        block_idx = 0

        # Session number and last session task (for figuring out plexon filenames)
        last_session_number = {}

        for log_file_name,log_file_task in zip(log_file_names,log_file_tasks):

            # Figure out session number
            if not log_file_task in last_session_number:
                session_number=1
            else:
                session_number=last_session_number[log_file_task]+1
            last_session_number[log_file_task]=session_number

            # If corresponding plexon file exists (recording during this session)
            plx_file_name='%s_%s_%s_%d.plx' % (subj_name, log_file_task, date, session_number)
            if os.path.exists(os.path.join(plx_data_dir,plx_file_name)):

                print(plx_file_name)

                #trial_locs=[]
                log_trial_conditions = read_conditions_from_log(log_dir, log_file_name)

                r = neo.io.PlexonIO(filename=os.path.join(plx_data_dir, plx_file_name))
                block = r.read(lazy=False)[0]
                for seg_idx, seg in enumerate(block.segments):
                    # Get the start and end times of each trial
                    start_times = [x.rescale('ms').magnitude.item(0) for x in seg.events[event_channels['trial_start']]]
                    stop_times = [x.rescale('ms').magnitude.item(0) for x in seg.events[event_channels['trial_stop']]]
                    if not len(start_times)==len(stop_times):
                        removed=True
                        while removed:
                            x=False
                            for i in range(len(start_times)):
                                if i<len(start_times)-1 and not (stop_times[i]>start_times[i] and stop_times[i]<start_times[i+1]):
                                    del stop_times[i]
                                    x=True
                                    break
                            removed=x
                    assert(len(start_times)==len(stop_times))

                    # condition_pulses=np.array([x.rescale('ms').magnitude.item(0) for x in seg.events[22]])

                    # Get time of all events in this segment
                    event_times = {}
                    for evt_code in event_channels.keys():
                        event_times[evt_code] = np.array([x.rescale('ms').magnitude.item(0) for x in seg.events[event_channels[evt_code]]])

                    seg_trials = []
                    # Get time of events in each trial
                    loc_trial_idx=0
                    for i in range(len(start_times)):
                        trial_events = {}
                        trial_start = start_times[i]
                        trial_stop = stop_times[i]
                        for evt_code in event_channels.keys():
                            trial_events[evt_code] = event_times[evt_code][np.where((event_times[evt_code] >= trial_start) & (event_times[evt_code] <= trial_stop))[0]] - trial_start
                        seg_trials.append(trial_events)

                        # if i==0:
                        #     pulse_codes=np.where(condition_pulses<trial_start)[0]
                        # else:
                        #     pulse_codes=np.where((condition_pulses>stop_times[i-1]) & (condition_pulses<trial_start))[0]
                        #
                        # # If not odd number of pulse codes - check for large temporal difference between them
                        # if not len(pulse_codes)%2==1 or len(pulse_codes)>np.max(np.array(list(condition_pulse_codes.keys()))):
                        #     pulse_code_time_diff=np.diff(condition_pulses[pulse_codes])
                        #     big_diff=np.where(pulse_code_time_diff>100)[0]
                        #     if len(big_diff):
                        #         loc_trial_idx=loc_trial_idx+len(big_diff)
                        #         big_diff=big_diff[-1]+1
                        #         pulse_codes=pulse_codes[big_diff:]
                        # if not len(pulse_codes) % 2 == 1 or len(pulse_codes)>np.max(np.array(list(condition_pulse_codes.keys()))):
                        if date=='16.04.19' and log_file_task=='motor_task_rake':
                            condition='motor_rake_center'
                        else:
                            assert (loc_trial_idx < len(log_trial_conditions))
                            condition=log_trial_conditions[loc_trial_idx]
                        # else:
                        #     condition = condition_pulse_codes[len(pulse_codes) - 2]
                        #     if condition == 'motor_grasp' or condition == 'motor_rake':
                        #         assert (loc_trial_idx < len(trial_locs))
                        #         condition = '%s_%s' % (condition, trial_locs[loc_trial_idx])
                        trial_info['block'].append(block_idx)

                        trial_info['condition'].append(condition)
                        trial_rew_event=np.where((event_times['reward']>trial_start) & (event_times['reward']<trial_stop+1000))[0]
                        if len(trial_rew_event)>0:
                            trial_info['correct'].append(True)
                        else:
                            trial_info['correct'].append(False)
                        loc_trial_idx=loc_trial_idx+1


                    # Clean trials
                    n_correct = 0
                    for i, trial in enumerate(seg_trials):
                        if log_file_task == 'visual_task_training' or log_file_task=='visual_task_stage1-2':
                            trial=filter_visual_events(trial)

                        elif log_file_task == 'motor_task_training' or log_file_task == 'motor_task_grasp':
                            trial=filter_motor_grasp_events(trial)

                        elif log_file_task == 'fixation_training':
                            trial = filter_fixation_events(trial)

                        elif log_file_task == 'motor_task_rake' or log_file_task == 'motor_task_rake_catch':
                            trial = filter_motor_rake_events(trial)

                        trial_evts = []
                        evt_times = []
                        for evt in trial.keys():
                            time_list = trial[evt]
                            if len(time_list) > 0:
                                trial_evts.append(evt)
                                evt_times.append(time_list[0])
                        sorted_evts = [x[1] for x in sorted(zip(evt_times, trial_evts))]
                        sorted_times = [x[0] for x in sorted(zip(evt_times, trial_evts))]

                        error=False
                        if log_file_task == 'visual_task_training' or log_file_task == 'visual_task_stage1-2':
                            error=check_visual_trial(i, sorted_evts)
                        elif log_file_task == 'motor_task_training' or log_file_task == 'motor_task_grasp':
                            error=check_motor_grasp_trial(i, sorted_evts)
                        elif log_file_task == 'motor_task_rake' or log_file_task == 'motor_task_rake_catch':
                            error = check_motor_rake_trial(i, sorted_evts)
                        elif log_file_task == 'fixation_training':
                            error=check_fixation_trial(i, sorted_evts)

                        if error:
                            print(sorted_evts)
                            # print(sorted_times)
                            print('\n')
                        else:
                            n_correct = n_correct + 1
                    print('%s: %d correct trials' % (log_file_task, n_correct))
                    trial_event_info.extend(seg_trials)

                block_idx=block_idx+1

        assert(len(trial_info['condition'])==len(trial_event_info))

        trial_info['trial']=range(len(trial_info['condition']))
        df=pd.DataFrame(trial_info, columns=['block','trial','condition','correct'])
        df.to_csv(os.path.join(out_dir,'trial_info.csv'),index=False)

        # Write to csv
        fid = open(os.path.join(out_dir, 'trial_events.csv'), 'w')
        fid.write('trial,event,time\n')
        for trial_idx, trial in enumerate(trial_event_info):
            for evt_code in trial.keys():
                if len(trial[evt_code]) > 0:
                    fid.write('%d,%s,%.4f\n' % (trial_idx, evt_code, trial[evt_code][0]))
        fid.close()


def read_conditions_from_log(log_dir, log_file_name):
    log_trial_conditions = []
    # Read log file
    f = open(os.path.join(log_dir, log_file_name), 'r')
    trials_started = False
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
            if line_parts[5] == 'CheckHandleStartPosition':
                # location = line_parts[4]
                # trial_locs.append(location)
                log_trial_conditions.append(log_condition_map['%s_%s' % (line_parts[3], line_parts[4])])
    f.close()
    return log_trial_conditions


def order_log_files(log_dir, recording_date):
    log_file_tasks = []
    log_file_names = []
    log_file_dates = []
    for x in os.listdir(log_dir):
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
    sorted_logs = sorted(zip(log_file_dates, log_file_tasks, log_file_names))
    log_file_names = [x[2] for x in sorted_logs]
    log_file_tasks = [x[1] for x in sorted_logs]
    return log_file_names, log_file_tasks


def filter_visual_events(trial):
    # Remove extra events
    for evt_code in trial.keys():
        if not evt_code in visual_trial_events:
            trial[evt_code] = []

    # Reliable visual task events
    if len(trial['error']):
        trial=filter_event(trial, 'error', np.min)
    if len(trial['reward']):
        trial = filter_event(trial, 'reward', np.min)
    if len(trial['laser_exp_start_center']):
        trial = filter_event(trial, 'laser_exp_start_center', np.min)
    if len(trial['go']):
        trial = filter_event(trial, 'go', np.min)
    if len(trial['exp_grasp_center']):
        trial = filter_event(trial, 'exp_grasp_center', np.min)

    # Start offset should be between go and grasp
    if len(trial['exp_start_off']):
        trial=filter_event(trial, 'exp_start_off', np.max, after_evt='go', before_evt='exp_grasp_center')
    # Place should be after grasp and before reward
    if len(trial['exp_place_left']):
        trial=filter_event(trial, 'exp_place_left', np.min, after_evt='exp_grasp_center', before_evt='reward')
    # Place should be after grasp
    if len(trial['exp_place_right']):
        trial=filter_event(trial, 'exp_place_right', np.min, after_evt='exp_grasp_center', before_evt='reward')
    return trial


def filter_motor_grasp_events(trial):
    # Remove extra events
    for evt_code in trial.keys():
        if not evt_code in motor_grasp_trial_events:
            trial[evt_code] = []

    # Reliable motor task events
    if len(trial['error']):
        trial=filter_event(trial, 'error', np.min)
    if len(trial['reward']):
        trial = filter_event(trial, 'reward', np.min)
    if len(trial['laser_monkey_tool_center']):
        trial = filter_event(trial, 'laser_monkey_tool_center', np.min)
    if len(trial['go']):
        trial = filter_event(trial, 'go', np.min)

    # Handle off should be after go
    if len(trial['monkey_handle_off']):
        trial=filter_event(trial, 'monkey_handle_off', np.min, after_evt='go')
    # Trap edge (grasp) should be after handle off
    if len(trial['trap_edge']):
        trial=filter_event(trial, 'trap_edge', np.min, after_evt='monkey_handle_off')
    # Trap bottom (place) should be between trap edge (grasp) and reward
    if len(trial['trap_bottom']):
        trial=filter_event(trial, 'trap_bottom', np.min, after_evt='trap_edge', before_evt='reward')
    return trial


def filter_motor_rake_events(trial):
    # Remove extra events
    for evt_code in trial.keys():
        if not evt_code in motor_grasp_trial_events:
            trial[evt_code] = []

    # Reliable motor task events
    if len(trial['error']):
        trial = filter_event(trial, 'error', np.min)
    if len(trial['reward']):
        trial = filter_event(trial, 'reward', np.min)
    if len(trial['go']):
        trial = filter_event(trial, 'go', np.min)

    # Handle off should be after go
    if len(trial['monkey_handle_off']):
        trial=filter_event(trial, 'monkey_handle_off', np.min, after_evt='go')
    # Rake handle should be after handle off
    if len(trial['monkey_rake_handle']):
        trial=filter_event(trial, 'monkey_rake_handle', np.min, after_evt='monkey_handle_off')
    # Tocchino should be after rake handle
    if len(trial['monkey_tool_right']):
        trial = filter_event(trial, 'monkey_tool_right', np.min, after_evt='monkey_rake_handle')
    if len(trial['monkey_tool_mid_right']):
        trial = filter_event(trial, 'monkey_tool_mid_right', np.min, after_evt='monkey_rake_handle')
    if len(trial['monkey_tool_center']):
        trial = filter_event(trial, 'monkey_tool_center', np.min, after_evt='monkey_rake_handle')
    if len(trial['monkey_tool_mid_left']):
        trial = filter_event(trial, 'monkey_tool_mid_left', np.min, after_evt='monkey_rake_handle')
    if len(trial['monkey_tool_left']):
        trial = filter_event(trial, 'monkey_tool_left', np.min, after_evt='monkey_rake_handle')
    # Rake blade should be after rake handle
    if len(trial['monkey_rake_blade']):
        trial=filter_event(trial, 'monkey_rake_blade', np.min, after_evt='monkey_rake_handle')
    # Trap edge should be after rake blade
    if len(trial['trap_edge']):
        trial=filter_event(trial, 'trap_edge', np.min, after_evt='monkey_rake_blade')
    # Trap bottom should be after trap edge and before reward
    if len(trial['trap_bottom']):
        trial=filter_event(trial, 'trap_bottom', np.min, after_evt='trap_edge', before_evt='reward')
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


def check_visual_trial(trial_idx, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        print('Error, trial %d has error event' % trial_idx)
        error=True

    if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
        print('Error, trial %d, first event not trial start' % trial_idx)
        error = True

    start_idx = sorted_evts.index('trial_start')
    if not sorted_evts[start_idx + 1] == 'laser_exp_start_center':
        print('Error, trial %d, first event after start not laser' % trial_idx)
        error = True

    if 'laser_exp_start_center' in sorted_evts:
        laser_idx = sorted_evts.index('laser_exp_start_center')
        if not sorted_evts[laser_idx + 1] == 'go':
            print('Error, trial %d, first event after laser not go' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no laser_exp_start_center event' % trial_idx)
        error=True

    if 'go' in sorted_evts:
        go_idx = sorted_evts.index('go')
        if not sorted_evts[go_idx + 1] == 'exp_start_off':
            print('Error, trial %d, first event after go not s_off' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no go event' % trial_idx)
        error = True

    if 'exp_start_off' in sorted_evts:
        s_off_idx = sorted_evts.index('exp_start_off')
        if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'exp_grasp_center':
            print('Error, trial %d, first event after s_off not grasp' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no s_off event' % trial_idx)
        error = True

    if 'exp_grasp_center' in sorted_evts:
        grasp_idx = sorted_evts.index('exp_grasp_center')
        if grasp_idx >= len(sorted_evts) - 1 or not (sorted_evts[grasp_idx + 1] == 'exp_place_right' or sorted_evts[grasp_idx + 1] == 'exp_place_left'):
            print('Error, trial %d, first event after grasp not place' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no grasp event' % trial_idx)
        error = True
    return error


def check_motor_grasp_trial(trial_idx, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        print('Error, trial %d has error event' % trial_idx)
        error=True

    if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
        print('Error, trial %d, first event not trial start' % trial_idx)
        error = True

    if 'trial_start' in sorted_evts:
        start_idx = sorted_evts.index('trial_start')
        if not sorted_evts[start_idx + 1] == 'go':
            print('Error, trial %d, first event after start not go' % trial_idx)
            error = True

    if 'go' in sorted_evts:
        go_idx = sorted_evts.index('go')
        if not sorted_evts[go_idx + 1] == 'monkey_handle_off':
            print('Error, trial %d, first event after go not monkey_handle_off' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no go event' % trial_idx)
        error = True

    if 'monkey_handle_off' in sorted_evts:
        s_off_idx = sorted_evts.index('monkey_handle_off')
        if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'trap_edge':
            print('Error, trial %d, first event after monkey_handle_off not trap_edge' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no monkey_handle_off event' % trial_idx)
        error = True

    if 'trap_edge' in sorted_evts:
        grasp_idx = sorted_evts.index('trap_edge')
        if grasp_idx >= len(sorted_evts) - 1 or not sorted_evts[grasp_idx + 1] == 'trap_bottom':
            print('Error, trial %d, first event after trap_edge not trap_bottom' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no trap_edge event' % trial_idx)
        error = True

    return error


def check_motor_rake_trial(trial_idx, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        print('Error, trial %d has error event' % trial_idx)
        error = True

    if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
        print('Error, trial %d, first event not trial start' % trial_idx)
        error = True

    if 'trial_start' in sorted_evts:
        start_idx = sorted_evts.index('trial_start')
        if not sorted_evts[start_idx + 1] == 'go':
            print('Error, trial %d, first event after start not go' % trial_idx)
            error = True

    if 'go' in sorted_evts:
        go_idx = sorted_evts.index('go')
        if not sorted_evts[go_idx + 1] == 'monkey_handle_off':
            print('Error, trial %d, first event after go not monkey_handle_off' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no go event' % trial_idx)
        error = True

    if 'monkey_handle_off' in sorted_evts:
        s_off_idx = sorted_evts.index('monkey_handle_off')
        if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'monkey_rake_handle':
            print('Error, trial %d, first event after monkey_handle_off not monkey_rake_handle' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no monkey_handle_off event' % trial_idx)
        error = True

    if not 'monkey_rake_handle' in sorted_evts:
        print('Error, trial %d, no monkey_rake_handle event' % trial_idx)
        error = True

    # if not ('monkey_tool_right' in sorted_evts or 'monkey_tool_mid_right' in sorted_evts or 'monkey_tool_center' in sorted_evts or
    #         'monkey_tool_mid_left' in sorted_evts or 'monkey_tool_left' in sorted_evts):
    #     print('Error, trial %d, no tool/object contact event' % trial_idx)
    #     error = True

    # if not 'monkey_rake_blade' in sorted_evts:
    #     print('Error, trial %d, no monkey_rake_blade event' % trial_idx)
    #     error = True

    if 'trap_edge' in sorted_evts:
        grasp_idx = sorted_evts.index('trap_edge')
        if grasp_idx >= len(sorted_evts) - 1 or not sorted_evts[grasp_idx + 1] == 'trap_bottom':
            print('Error, trial %d, first event after trap_edge not trap_bottom' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no trap_edge event' % trial_idx)
        error = True

    return error


def check_fixation_trial(trial_idx, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        print('Error, trial %d has error event' % trial_idx)
        error=True

    if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
        print('Error, trial %d, first event not trial start' % trial_idx)
        error = True
    start_idx = sorted_evts.index('trial_start')
    if not sorted_evts[start_idx + 1] == 'laser_exp_start_center':
        print('Error, trial %d, first event after start not laser' % trial_idx)
        error = True

    if 'laser_exp_start_center' in sorted_evts:
        laser_idx = sorted_evts.index('laser_exp_start_center')
        if not sorted_evts[laser_idx + 1] == 'go':
            print('Error, trial %d, first event after laser not go' % trial_idx)
            error = True
    else:
        print('Error, trial %d, no laser_exp_start_center event' % trial_idx)
        error=True

    if not 'go' in sorted_evts:
        print('Error, trial %d, no go event' % trial_idx)
        error = True
    return error

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    run_process_trial_info(subject, recording_date)