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
visual_trial_events=['trial_start','trial_stop','error','exp_grasp_center','exp_place_left','exp_place_right', 'go','laser_exp_start_center',
                     'reward','exp_start_off']
motor_trial_events=['trial_start','trial_stop','error','go','laser_monkey_tool_center','reward','trap_bottom','monkey_handle_off','trap_edge']

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

    # Create output dir
    out_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/data/preprocessed_data/', subj_name, date)
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)

    # Directories containing logs and plexon data (events)
    log_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/data/logs/', subj_name)
    plx_data_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/data/recordings/plexon/%s/%s' % (subj_name, date))

    # Figure out temporal order of log files
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
    sorted_logs=sorted(zip(log_file_dates, log_file_tasks,log_file_names))
    log_file_names=[x[2] for x in sorted_logs]
    log_file_tasks = [x[1] for x in sorted_logs]


    # Trial info
    trial_info={
        'block':[],
        'condition':[],
        'correct':[]
    }
    trial_event_info=[]

    # Trial and block index
    trial_idx = 0
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

            trial_locs=[]
            if log_file_task=='motor_task_training':
                # Read log file
                f=open(os.path.join(log_dir,log_file_name),'r')
                trials_started = False

                for line in f:
                    # Remove extra characters
                    line=line.strip()
                    # Trial states start after first blank line
                    if len(line)==0:
                        trials_started=True
                        continue

                    if trials_started:
                        # Parse line and get trial number
                        line_parts=line.split(',')
                        # Recording started - parse condition
                        if line_parts[5]=='CheckHandleStartPosition':
                            location = line_parts[4]
                            trial_locs.append(location)
                f.close()

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

                condition_pulses=np.array([x.rescale('ms').magnitude.item(0) for x in seg.events[22]])

                # Get time of all events in this segment
                event_times = {}
                for evt_code in event_channels.keys():
                    event_times[evt_code] = np.array(
                        [x.rescale('ms').magnitude.item(0) for x in seg.events[event_channels[evt_code]]])

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

                    if i==0:
                        pulse_codes=np.where(condition_pulses<trial_start)[0]
                    else:
                        pulse_codes=np.where((condition_pulses>stop_times[i-1]) & (condition_pulses<trial_start))[0]

                    # If not odd number of pulse codes - check for large temporal difference between them
                    if not len(pulse_codes)%2==1 or len(pulse_codes)>np.max(np.array(list(condition_pulse_codes.keys()))):
                        pulse_code_time_diff=np.diff(condition_pulses[pulse_codes])
                        big_diff=np.where(pulse_code_time_diff>100)[0]
                        if len(big_diff):
                            loc_trial_idx=loc_trial_idx+len(big_diff)
                            big_diff=big_diff[-1]+1
                            pulse_codes=pulse_codes[big_diff:]
                    assert(len(pulse_codes)%2==1)
                    trial_info['block'].append(block_idx)
                    condition=condition_pulse_codes[len(pulse_codes)-2]
                    if condition=='motor_grasp' or condition=='motor_rake':
                        assert(loc_trial_idx<len(trial_locs))
                        condition='%s_%s' % (condition, trial_locs[loc_trial_idx])
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
                    if log_file_task == 'visual_task_training':
                        # Remove extra events
                        for evt_code in trial.keys():
                            if not evt_code in visual_trial_events:
                                trial[evt_code] = []

                        # Reliable visual task events
                        if len(trial['error']):
                            trial['error'] = [np.min(trial['error'])]
                        if len(trial['reward']):
                            trial['reward'] = [np.min(trial['reward'])]
                        if len(trial['laser_exp_start_center']):
                            trial['laser_exp_start_center'] = [np.min(trial['laser_exp_start_center'])]
                        if len(trial['go']):
                            trial['go'] = [np.min(trial['go'])]
                        if len(trial['exp_grasp_center']):
                            trial['exp_grasp_center'] = [np.min(trial['exp_grasp_center'])]
                        # Start offset should be between go and grasp
                        if len(trial['exp_start_off']):
                            off_times = trial['exp_start_off']
                            if len(trial['go']) and len(trial['exp_grasp_center']):
                                go_time = trial['go'][0]
                                grasp_time = trial['exp_grasp_center'][0]
                                if len(np.where((off_times > go_time) & (off_times < grasp_time))[0]):
                                    trial['exp_start_off'] = [np.max(
                                        off_times[np.where((off_times > go_time) & (off_times < grasp_time))[0]])]
                                else:
                                    trial['exp_start_off'] = [np.max(trial['exp_start_off'])]
                            else:
                                trial['exp_start_off'] = [np.max(trial['exp_start_off'])]
                        # Place should be after grasp
                        if len(trial['exp_place_left']):
                            place_times = trial['exp_place_left']
                            if len(trial['exp_grasp_center']):
                                grasp_time = trial['exp_grasp_center'][0]
                                if len(np.where(place_times > grasp_time)[0]):
                                    trial['exp_place_left'] = [
                                        np.min(place_times[np.where(place_times > grasp_time)[0]])]
                                else:
                                    trial['exp_place_left'] = [np.min(trial['exp_place_left'])]
                            else:
                                trial['exp_place_left'] = [np.min(trial['exp_place_left'])]
                        # Place should be after grasp
                        if len(trial['exp_place_right']):
                            place_times = trial['exp_place_right']
                            if len(trial['exp_grasp_center']):
                                grasp_time = trial['exp_grasp_center'][0]
                                if len(np.where(place_times > grasp_time)[0]):
                                    trial['exp_place_right'] = [
                                        np.min(place_times[np.where(place_times > grasp_time)[0]])]
                                else:
                                    trial['exp_place_right'] = [np.min(trial['exp_place_right'])]
                            else:
                                trial['exp_place_right'] = [np.min(trial['exp_place_right'])]

                    elif log_file_task == 'motor_task_training':
                        # Remove extra events
                        for evt_code in trial.keys():
                            if not evt_code in motor_trial_events:
                                trial[evt_code] = []

                        # Reliable motor task events
                        if len(trial['error']):
                            trial['error'] = [np.min(trial['error'])]
                        if len(trial['reward']):
                            trial['reward'] = [np.min(trial['reward'])]
                        if len(trial['laser_monkey_tool_center']):
                            trial['laser_monkey_tool_center'] = [np.min(trial['laser_monkey_tool_center'])]
                        if len(trial['go']):
                            trial['go'] = [np.min(trial['go'])]
                        # Handle off should be after go
                        if len(trial['monkey_handle_off']):
                            handle_off_times = trial['monkey_handle_off']
                            if len(trial['go']):
                                go_time = trial['go'][0]
                                if len(np.where(handle_off_times > go_time)[0]):
                                    trial['monkey_handle_off'] = [
                                        np.min(handle_off_times[np.where(handle_off_times > go_time)[0]])]
                                else:
                                    trial['monkey_handle_off'] = [np.min(trial['monkey_handle_off'])]
                            else:
                                trial['monkey_handle_off'] = [np.min(trial['monkey_handle_off'])]
                        # Trap edge (grasp) should be after handle off
                        if len(trial['trap_edge']):
                            trap_edge_times = trial['trap_edge']
                            if len(trial['monkey_handle_off']):
                                handle_off_time = trial['monkey_handle_off']
                                if len(np.where(trap_edge_times > handle_off_time)[0]):
                                    trial['trap_edge'] = [
                                        np.min(trap_edge_times[np.where(trap_edge_times > handle_off_time)[0]])]
                                else:
                                    trial['trap_edge'] = []
                            else:
                                trial['trap_edge'] = []
                        # Trap bottom (place) should be between trap edge (grasp) and reward
                        if len(trial['trap_bottom']):
                            trap_bottom_times = trial['trap_bottom']
                            if len(trial['trap_edge']) and len(trial['reward']):
                                trap_edge_time = trial['trap_edge'][0]
                                reward_time = trial['reward'][0]
                                if len(np.where(
                                        (trap_bottom_times > trap_edge_time) & (trap_bottom_times < reward_time))[0]):
                                    trial['trap_bottom'] = [np.min(trap_bottom_times[np.where(
                                        (trap_bottom_times > trap_edge_time) & (trap_bottom_times < reward_time))[0]])]
                                else:
                                    trial['trap_bottom'] = []
                            else:
                                trial['trap_bottom'] = []

                    trial_evts = []
                    evt_times = []
                    for evt in trial.keys():
                        time_list = trial[evt]
                        if len(time_list) > 0:
                            trial_evts.append(evt)
                            evt_times.append(time_list[0])
                    sorted_evts = [x[1] for x in sorted(zip(evt_times, trial_evts))]
                    sorted_times = [x[0] for x in sorted(zip(evt_times, trial_evts))]
                    error = False
                    if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
                        print('Error, trial %d, first event not trial start' % i)
                        error = True
                    if log_file_task == 'visual_task_training' and not 'error' in sorted_evts:
                        start_idx = sorted_evts.index('trial_start')
                        if not sorted_evts[start_idx + 1] == 'laser_exp_start_center':
                            print('Error, trial %d, first event after start not laser' % i)
                            error = True
                        laser_idx = sorted_evts.index('laser_exp_start_center')
                        if not sorted_evts[laser_idx + 1] == 'go':
                            print('Error, trial %d, first event after laser not go' % i)
                            error = True
                        if 'go' in sorted_evts:
                            go_idx = sorted_evts.index('go')
                            if not sorted_evts[go_idx + 1] == 'exp_start_off':
                                print('Error, trial %d, first event after go not s_off' % i)
                                error = True
                        else:
                            print('Error, trial %d, no go event' % i)
                            error = True
                        if 'exp_start_off' in sorted_evts:
                            s_off_idx = sorted_evts.index('exp_start_off')
                            if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[
                                                                            s_off_idx + 1] == 'exp_grasp_center':
                                print('Error, trial %d, first event after s_off not grasp' % i)
                                error = True
                        else:
                            print('Error, trial %d, no s_off event' % i)
                            error = True
                        if 'exp_grasp_center' in sorted_evts:
                            grasp_idx = sorted_evts.index('exp_grasp_center')
                            if grasp_idx >= len(sorted_evts) - 1 or not (
                                    sorted_evts[grasp_idx + 1] == 'exp_place_right' or sorted_evts[
                                grasp_idx + 1] == 'exp_place_left'):
                                print('Error, trial %d, first event after grasp not place' % i)
                                error = True
                        else:
                            print('Error, trial %d, no grasp event' % i)
                            error = True
                        if not error:
                            n_correct = n_correct + 1
                    elif log_file_task == 'motor_task_training' and not 'error' in sorted_evts:  # and not 'error' in sorted_evts:
                        if 'trial_start' in sorted_evts:
                            start_idx = sorted_evts.index('trial_start')
                            if not sorted_evts[start_idx + 1] == 'go':
                                print('Error, trial %d, first event after start not go' % i)
                                error = True
                        if 'go' in sorted_evts:
                            go_idx = sorted_evts.index('go')
                            if not sorted_evts[go_idx + 1] == 'monkey_handle_off':
                                print('Error, trial %d, first event after go not monkey_handle_off' % i)
                                error = True
                        else:
                            print('Error, trial %d, no go event' % i)
                            error = True
                        if 'monkey_handle_off' in sorted_evts:
                            s_off_idx = sorted_evts.index('monkey_handle_off')
                            if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'trap_edge':
                                print('Error, trial %d, first event after monkey_handle_off not trap_edge' % i)
                                error = True
                        else:
                            print('Error, trial %d, no monkey_handle_off event' % i)
                            error = True
                        if 'trap_edge' in sorted_evts:
                            grasp_idx = sorted_evts.index('trap_edge')
                            if grasp_idx >= len(sorted_evts) - 1 or not sorted_evts[grasp_idx + 1] == 'trap_bottom':
                                print('Error, trial %d, first event after trap_edge not trap_bottom' % i)
                                error = True
                        else:
                            print('Error, trial %d, no trap_edge event' % i)
                            error = True
                        if not error:
                            n_correct = n_correct + 1
                    if error:
                        print(sorted_evts)
                        # print(sorted_times)
                        print('\n')
                print('%d correct trials' % n_correct)
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

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    run_process_trial_info(subject, recording_date)