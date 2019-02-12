import sys
import glob
import os
import transplant
from datetime import datetime
import neo
import numpy as np

def process_events(subject, date):
    recording_date=datetime.strptime(date, '%d.%m.%y')

    # Reads and sorts log files by date/time
    log_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/data/logs/', subject)
    log_file_names = []
    log_file_dates = []
    for x in os.listdir(log_dir):
        if os.path.splitext(x)[1] == '.csv':
            fparts = os.path.splitext(x)[0].split('_')
            try:
                filedate = datetime.strptime(fparts[-1], '%Y-%d-%m--%H-%M')
                if filedate.year==recording_date.year and filedate.month==recording_date.month and filedate.day==recording_date.day:
                    log_file_names.append('_'.join(fparts[0:-1]))
                    log_file_dates.append(filedate)
            except:
                pass
    log_file_names = [x for _, x in sorted(zip(log_file_dates, log_file_names))]

    # Read corresponding plexon files
    plx_file_names=[]
    session_number=0
    last_session_name=''
    for log_file_name in log_file_names:
        if log_file_name==last_session_name:
            session_number=session_number+1
        else:
            session_number=1
        last_session_name=log_file_name
        plx_file_names.append('%s_%s_%s_%d.plx' % (subject, log_file_name, date, session_number))

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

    trials = []

    plx_data_dir=os.path.join('/home/bonaiuto/Projects/tool_learning/data/recordings/plexon/%s/%s' % (subject, date))
    for f_idx,plx_file in enumerate(plx_file_names):
        log_file_name=log_file_names[f_idx]
        if os.path.exists(os.path.join(plx_data_dir, plx_file)):

            r = neo.io.PlexonIO(filename=os.path.join(plx_data_dir, plx_file))
            block = r.read(lazy=False)[0]
            for seg_idx, seg in enumerate(block.segments):
                print('importing segment %d' % seg_idx)

                # Get the start and end times of each trial
                start_times=[x.rescale('ms').magnitude.item(0) for x in seg.events[event_channels['trial_start']]]
                stop_times = [x.rescale('ms').magnitude.item(0)+1000 for x in seg.events[event_channels['trial_stop']]]

                # Get time of all events in this segment
                event_times={}
                for evt_code in event_channels.keys():
                    event_times[evt_code]=np.array([x.rescale('ms').magnitude.item(0) for x in seg.events[event_channels[evt_code]]])

                seg_trials=[]
                # Get time of events in each trial
                for trial_idx in range(len(start_times)):
                    trial_events={}
                    trial_start=start_times[trial_idx]
                    trial_stop=stop_times[trial_idx]
                    for evt_code in event_channels.keys():
                        trial_events[evt_code]=event_times[evt_code][np.where((event_times[evt_code]>=trial_start) & (event_times[evt_code]<=trial_stop))[0]]-trial_start
                    seg_trials.append(trial_events)

                # Clean trials
                n_correct=0
                for trial_idx,trial in enumerate(seg_trials):
                    for min_error_code in ['error','exp_grasp_center','exp_place_left','exp_place_right',
                                           'go','laser_exp_start_center','laser_exp_start_left','laser_exp_start_right',
                                           'laser_monkey_tool_center','monkey_handle_on',
                                           'monkey_rake_blade','monkey_rake_handle','monkey_tool_center','monkey_tool_left',
                                           'monkey_tool_mid_left','monkey_tool_mid_right','monkey_tool_right','reward',
                                           'trap_bottom','trap_edge','exp_start_off']:
                        if len(trial[min_error_code])>0:
                            trial[min_error_code]= [np.min(trial[min_error_code])]
                    for max_error_code in ['monkey_handle_off']:
                        if len(trial[max_error_code])>0:
                            trial[max_error_code] = [np.max(trial[max_error_code])]

                    trial_evts=[]
                    evt_times=[]
                    for evt in trial.keys():
                        time_list=trial[evt]
                        if len(time_list)>0:
                            trial_evts.append(evt)
                            evt_times.append(time_list[0])
                    sorted_evts=[x[1] for x in sorted(zip(evt_times,trial_evts))]
                    sorted_times = [x[0] for x in sorted(zip(evt_times, trial_evts))]
                    sorted_evts.remove('trial_stop')
                    error=False
                    if not sorted_evts[0]=='trial_start':
                        print('Error, trial %d, first event not trial start' % trial_idx)
                        error=True
                    if log_file_name=='visual_task_training' and not 'error' in sorted_evts:
                        sorted_evts.remove('reward')
                        if 'monkey_handle_off' in sorted_evts:
                            sorted_evts.remove('monkey_handle_off')
                        if 'monkey_handle_on' in sorted_evts:
                            sorted_evts.remove('monkey_handle_on')
                        start_idx=sorted_evts.index('trial_start')
                        if not sorted_evts[start_idx+1]=='laser_exp_start_center':
                            print('Error, trial %d, first event after start not laser' % trial_idx)
                            error = True
                        laser_idx=sorted_evts.index('laser_exp_start_center')
                        if not sorted_evts[laser_idx+1]=='go':
                            print('Error, trial %d, first event after laser not go' % trial_idx)
                            error = True
                        if 'go' in sorted_evts:
                            go_idx=sorted_evts.index('go')
                            if not sorted_evts[go_idx+1]=='exp_start_off':
                                print('Error, trial %d, first event after go not s_off' % trial_idx)
                                error = True
                        else:
                            print('Error, trial %d, no go event' % trial_idx)
                            error = True
                        if 'exp_start_off' in sorted_evts:
                            s_off_idx=sorted_evts.index('exp_start_off')
                            if s_off_idx>=len(sorted_evts)-1 or not sorted_evts[s_off_idx+1]=='exp_grasp_center':
                                print('Error, trial %d, first event after s_off not grasp' % trial_idx)
                                error = True
                        else:
                            print('Error, trial %d, no s_off event' % trial_idx)
                            error = True
                        if 'exp_grasp_center' in sorted_evts:
                            grasp_idx=sorted_evts.index('exp_grasp_center')
                            if grasp_idx>=len(sorted_evts)-1 or not (sorted_evts[grasp_idx+1]=='exp_place_right' or sorted_evts[grasp_idx+1]=='exp_place_left'):
                                print('Error, trial %d, first event after grasp not place' % trial_idx)
                                error = True
                        else:
                            print('Error, trial %d, no grasp event' % trial_idx)
                            error = True
                        if not error:
                            n_correct=n_correct+1
                    elif log_file_name == 'motor_task_training':# and not 'error' in sorted_evts:
                        print(sorted_evts)
                    if error:
                        print(sorted_evts)
                        #print(sorted_times)
                        print('\n')
                print('%d correct trials' % n_correct)
                trials.extend(seg_trials)




    # Write to csv
    out_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/data/preprocessed_data/', subject, date)
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)

    fid=open(os.path.join(out_dir, 'trial_events.csv'),'w')
    fid.write('trial,event,time\n')
    for trial_idx,trial in enumerate(trials):
        for evt_code in trial.keys():
            if len(trial[evt_code])>0:
                fid.write('%d,%s,%.4f\n' % (trial_idx,evt_code,trial[evt_code][0]))
    fid.close()

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    process_events(subject, recording_date)