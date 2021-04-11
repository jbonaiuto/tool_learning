from datetime import datetime, timedelta
import os
import sys

import numpy as np
import pandas as pd

from config import read_config
import eventide
import plexon
import intan
import logging

cfg = read_config()


def run_process_trial_info(subj_name, date, intan_data_files):
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
        plexon_rec_out_dir = os.path.join(out_dir, 'plexon')
        if not os.path.exists(plexon_rec_out_dir):
            os.mkdir(plexon_rec_out_dir)

        logging.basicConfig(filename=os.path.join(out_dir, 'process_trial_info.log'), filemode='w', level=logging.INFO)
        logging.getLogger().addHandler(logging.StreamHandler(sys.stdout))
        logging.info(date)

        # Read log and plexon files
        log_set= eventide.EventIDELogSet(subj_name, date, log_dir, plx_data_dir)
        plexon_set= plexon.PlexonRecordingSet(subj_name, date, plx_data_dir, log_set, plexon_rec_out_dir)

        # Make sure there is same number of trials in each
        assert (log_set.total_trials() == plexon_set.total_trials())
        # Check trial durations
        assert(np.nanmax(np.abs(np.array(log_set.trial_durations())-np.array(plexon_set.trial_durations())))<10)

        # Read intan files
        intan_set= intan.IntanRecordingSet(subj_name, date, intan_data_dir, rhd_rec_out_dir, intan_data_files)

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
            'seg_idx':[],
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
        prev_plexon_start=0

        # Go through each intan file
        for t_idx in range(len(intan_set.trial_files)):
            # Get duration and task
            intan_dur=intan_set.trial_durations[t_idx]
            intan_task=intan_set.trial_tasks[t_idx]
            intan_seg_idxs=intan_set.trial_seg_idxs[t_idx]

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
                            if t_idx in intan_set.bad_recording_signal_trials:
                                status='bad_rec_signal'
                            elif error:
                                status='error'
                            trial_info['status'].append(status)
                            trial_info['log_file'].append(os.path.split(log_set.logs[session_idx].file)[1])
                            trial_info['plexon_file'].append(os.path.split(plexon_set.recordings[session_idx].file)[1])
                            file_parts=intan_set.trial_files[t_idx].split(';')
                            file_fnames=[]
                            for part in file_parts:
                                file_fnames.append(os.path.split(part)[1])
                            trial_info['intan_file'].append(';'.join(file_fnames))
                            trial_info['seg_idx'].append(';'.join([str(x) for x in intan_seg_idxs]))
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
                        prev_plexon_start=plexon_start
                        plexon_start = 0

                    last_session_task_matched=True
                elif last_session_task_matched:
                    break
                else:
                    plexon_start = 0

            # Add to trial info even if not matched
            if not matched:
                plexon_start=prev_plexon_start
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
                trial_info['status'].append('no match')
                trial_info['log_file'].append('')
                trial_info['plexon_file'].append('')
                trial_info['intan_file'].append(os.path.split(intan_set.trial_files[t_idx])[1])
                trial_info['seg_idx'].append('')
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

        logging.info('Total num trials: log=%d, plexon=%d, intan=%d' % (log_set.total_trials(), plexon_set.total_trials(),
                                                                 len(trial_info['block'])))

        df = pd.DataFrame(trial_info, columns=['overall_trial', 'block', 'task', 'trial', 'condition', 'reward',
                                               'status', 'log_file', 'plexon_file', 'intan_file', 'log_trial_idx',
                                               'plexon_trial_idx', 'intan_trial_idx', 'seg_idx','log_duration',
                                               'plexon_duration', 'intan_duration'])
        df.to_csv(os.path.join(out_dir, 'trial_info.csv'), index=False)

        logging.info('*** Good trials per condition per block ****')
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
            logging.info('Block %d - %s' % (block, block_task))
            for key, val in block_good_trials.items():
                logging.info('%s - %d trials' % (key, val))
        logging.info('*** Good trials per condition overall ****')
        for key, val in all_good_trials.items():
            logging.info('%s - %d trials' % (key, val))
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

        logging.shutdown()


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
        logging.warning('Error, block %d, trial %d-%s, error' % (block_idx, trial_idx, condition))
        error=True
    else:
        if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
            logging.warning('Error, block %d, trial %d-%s, first event not trial start' % (block_idx, trial_idx, condition))
            error = True

        start_idx = sorted_evts.index('trial_start')
        if not sorted_evts[start_idx + 1] == 'laser_exp_start_center':
            logging.warning('Error, block %d, trial %d-%s, first event after start not laser' % (block_idx, trial_idx, condition))
            error = True

        if 'laser_exp_start_center' in sorted_evts:
            laser_idx = sorted_evts.index('laser_exp_start_center')
            if not sorted_evts[laser_idx + 1] == 'go':
                logging.warning('Error, block %d, trial %d-%s, first event after laser not go' % (block_idx, trial_idx, condition))
                error = True
        else:
            logging.warning('Error, block %d, trial %d-%s, no laser_exp_start_center event' % (block_idx, trial_idx, condition))
            error=True

        if 'go' in sorted_evts:
            go_idx = sorted_evts.index('go')
            if not sorted_evts[go_idx + 1] == 'exp_start_off':
                logging.warning('Error, block %d, trial %d-%s, first event after go not s_off' % (block_idx, trial_idx, condition))
                error = True
        else:
            logging.warning('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
            error = True

        if 'exp_start_off' in sorted_evts:
            s_off_idx = sorted_evts.index('exp_start_off')
            if not (condition == 'visual_grasp_right' or condition == 'visual_grasp_left'):
                if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'tool_start_off':
                    logging.warning('Error, block %d, trial %d-%s, first event after s_off not tool_start_off' % (block_idx, trial_idx, condition))
                    error = True
            else:
                if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'exp_grasp_center':
                    logging.warning('Error, block %d, trial %d-%s, first event after s_off not grasp' % (block_idx, trial_idx, condition))
                    error = True
        else:
            logging.warning('Error, block %d, trial %d-%s, no s_off event' % (block_idx, trial_idx, condition))
            error = True

        if not (condition == 'visual_grasp_right' or condition == 'visual_grasp_left'):
            if 'tool_start_off' in sorted_evts:
                s_off_idx = sorted_evts.index('tool_start_off')
                if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'exp_grasp_center':
                    logging.warning('Error, block %d, trial %d-%s, first event after tool_start_off not grasp' % (block_idx, trial_idx, condition))
                    error = True
            else:
                logging.warning('Error, block %d, trial %d-%s, no tool_start_off event' % (block_idx, trial_idx, condition))
                error = True

        if 'exp_grasp_center' in sorted_evts:
            grasp_idx = sorted_evts.index('exp_grasp_center')
            if grasp_idx >= len(sorted_evts) - 1 or not (sorted_evts[grasp_idx + 1] == 'exp_place_right' or sorted_evts[grasp_idx + 1] == 'exp_place_left'):
                logging.warning('Error, block %d, trial %d-%s, first event after grasp not place' % (block_idx, trial_idx, condition))
                error = True
        else:
            logging.warning('Error, block %d, trial %d-%s, no grasp event' % (block_idx, trial_idx, condition))
            error = True

        if error:
            logging.warning(sorted_evts)
            # logging.warning(sorted_times)
            logging.warning('\n')

    return error


def check_motor_grasp_trial(block_idx, trial_idx, condition, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        logging.warning('Error, block %d, trial %d-%s, error' % (block_idx, trial_idx, condition))
        error=True
    else:
        if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
            logging.warning('Error, block %d, trial %d-%s, first event not trial start' % (block_idx, trial_idx, condition))
            error = True

        if 'trial_start' in sorted_evts:
            start_idx = sorted_evts.index('trial_start')
            if not sorted_evts[start_idx + 1] == 'go':
                logging.warning('Error, block %d, trial %d-%s, first event after start not go' % (block_idx, trial_idx, condition))
                error = True

        if 'go' in sorted_evts:
            go_idx = sorted_evts.index('go')
            if not sorted_evts[go_idx + 1] == 'monkey_handle_off':
                logging.warning('Error, block %d, trial %d-%s, first event after go not monkey_handle_off' % (block_idx, trial_idx, condition))
                error = True
        else:
            logging.warning('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
            error = True

        if 'monkey_handle_off' in sorted_evts:
            s_off_idx = sorted_evts.index('monkey_handle_off')
            if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'trap_edge':
                logging.warning('Error, block %d, trial %d-%s, first event after monkey_handle_off not trap_edge' % (block_idx, trial_idx, condition))
                error = True
        else:
            logging.warning('Error, block %d, trial %d-%s, no monkey_handle_off event' % (block_idx, trial_idx, condition))
            error = True

        if 'trap_edge' in sorted_evts:
            grasp_idx = sorted_evts.index('trap_edge')
            if grasp_idx >= len(sorted_evts) - 1 or not sorted_evts[grasp_idx + 1] == 'trap_bottom':
                logging.warning('Error, block %d, trial %d-%s, first event after trap_edge not trap_bottom' % (block_idx, trial_idx, condition))
                error = True
        else:
            logging.warning('Error, block %d, trial %d-%s, no trap_edge event' % (block_idx, trial_idx, condition))
            error = True

        if error:
            logging.warning(sorted_evts)
            # logging.warning(sorted_times)
            logging.warning('\n')

    return error


def check_motor_rake_trial(block_idx, trial_idx, condition, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        logging.warning('Error, block %d, trial %d-%s, error' % (block_idx, trial_idx, condition))
        error = True
    else:
        if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
            logging.warning('Error, block %d, trial %d-%s, first event not trial start' % (block_idx, trial_idx, condition))
            error = True

        if 'trial_start' in sorted_evts:
            start_idx = sorted_evts.index('trial_start')
            if not sorted_evts[start_idx + 1] == 'go':
                logging.warning('Error, block %d, trial %d-%s, first event after start not go' % (block_idx, trial_idx, condition))
                error = True

        if 'go' in sorted_evts:
            go_idx = sorted_evts.index('go')
            if not sorted_evts[go_idx + 1] == 'monkey_handle_off':
                logging.warning('Error, block %d, trial %d-%s, first event after go not monkey_handle_off' % (block_idx, trial_idx, condition))
                error = True
        else:
            logging.warning('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
            error = True

        if 'monkey_handle_off' in sorted_evts:
           s_off_idx = sorted_evts.index('monkey_handle_off')
           if s_off_idx >= len(sorted_evts) - 1 or not sorted_evts[s_off_idx + 1] == 'monkey_rake_handle':
               logging.warning('Error, block %d, trial %d-%s, first event after monkey_handle_off not monkey_rake_handle' % (block_idx, trial_idx, condition))
               error = True
        else:
           logging.warning('Error, block %d, trial %d-%s, no monkey_handle_off event' % (block_idx, trial_idx, condition))
           error = True

        #if not 'monkey_rake_handle' in sorted_evts:
        #    logging.warning('Error, block %d, trial %d-%s, no monkey_rake_handle event' % (block_idx, trial_idx, condition))
        #    error = True

        # if not 'monkey_handle_off' in sorted_evts:
        #     logging.warning('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
        #     error = True

        if condition=='motor_rake_left' or condition=='motor_rake_food_left':
            if not ('monkey_tool_mid_left' in sorted_evts or 'monkey_tool_left' in sorted_evts):
                logging.warning('Error, block %d, trial %d-%s, no tool/object contact event' % (block_idx, trial_idx, condition))
                error = True
        elif condition=='motor_rake_right' or condition=='motor_rake_food_right':
            if not ('monkey_tool_right' in sorted_evts or 'monkey_tool_mid_right' in sorted_evts):
                logging.warning('Error, block %d, trial %d-%s, no tool/object contact event' % (block_idx, trial_idx, condition))
                error = True
        elif condition=='motor_rake_center' or condition=='motor_rake_food_center':
            if not ('monkey_tool_center' in sorted_evts):
                logging.warning('Error, block %d, trial %d-%s, no tool/object contact event' % (block_idx, trial_idx, condition))
                error = True

        if not 'trap_edge' in sorted_evts and not 'trap_bottom' in sorted_evts:
            logging.warning('Error, block %d, trial %d-%s, no trap_edge or trap_bottom event' % (block_idx, trial_idx, condition))
            error = True

        # if not 'trap_bottom' in sorted_evts:
        #     logging.warning('Error, block %d, trial %d-%s, no trap_bottom event' % (block_idx, trial_idx, condition))
        #     error = True

        # if 'monkey_rake_handle' in sorted_evts:
        #     handle_idx = sorted_evts.index('monkey_rake_handle')
        #     if handle_idx >= len(sorted_evts) - 1 or not sorted_evts[handle_idx + 1] == 'trap_bottom':
        #         logging.warning('Error, block %d, trial %d-%s, first event after trap_edge not trap_bottom' % (block_idx, trial_idx, condition))
        #         error = True
        # else:
        #     logging.warning('Error, block %d, trial %d-%s, no trap_edge event' % (block_idx, trial_idx, condition))
        #     error = True

        if error:
            logging.warning(sorted_evts)
            # logging.warning(sorted_times)
            logging.warning('\n')

    return error


def check_fixation_trial(block_idx, trial_idx, condition, sorted_evts):
    error = False

    if 'error' in sorted_evts:
        logging.warning('Error, block %d, trial %d-%s, error' % (block_idx, trial_idx, condition))
        error=True

    else:
        if len(sorted_evts) == 0 or not sorted_evts[0] == 'trial_start':
            logging.warning('Error, block %d, trial %d-%s, first event not trial start' % (block_idx, trial_idx, condition))
            error = True
        start_idx = sorted_evts.index('trial_start')
        if not sorted_evts[start_idx + 1] == 'laser_exp_start_center':
            logging.warning('Error, block %d, trial %d-%s, first event after start not laser' % (block_idx, trial_idx, condition))
            error = True

        if 'laser_exp_start_center' in sorted_evts:
            laser_idx = sorted_evts.index('laser_exp_start_center')
            if not sorted_evts[laser_idx + 1] == 'go':
                logging.warning('Error, block %d, trial %d-%s, first event after laser not go' % (block_idx, trial_idx, condition))
                error = True
        else:
            logging.warning('Error, block %d, trial %d-%s, no laser_exp_start_center event' % (block_idx, trial_idx, condition))
            error=True

        if not 'go' in sorted_evts:
            logging.warning('Error, block %d, trial %d-%s, no go event' % (block_idx, trial_idx, condition))
            error = True

        if error:
            logging.warning(sorted_evts)
            # logging.warning(sorted_times)
            logging.warning('\n')

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
    run_process_trial_info(subject, recording_date)
    #rerun(subject,recording_date)
