from datetime import datetime
import os
import sys
import numpy as np
import pandas as pd

def process_logs(subj_name, date):
    recording_date = datetime.strptime(date, '%d.%m.%y')
    log_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/logs/', subj_name)
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

    # Read corresponding event files
    evt_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/recordings/plexon', subj_name, date)
    evt_files = []
    session_number = 0
    last_session_task = ''
    for log_file_task in log_file_tasks:
        if log_file_task == last_session_task:
            session_number = session_number + 1
        else:
            session_number = 1
            last_session_task = log_file_task
        evt_files.append('%s_%s_%s_%d.csv' % (subj_name, log_file_task, date, session_number))

    # Read conditions from log files
    trial_info={
        'block':[],
        'trial':[],
        'condition':[],
        'correct':[]
    }

    trial_idx = 0

    for log_file_name,log_file_task in zip(log_file_names,log_file_tasks):
        name_parts = log_file_name.split('_')
        f=open(os.path.join(log_dir,log_file_name),'r')
        trials_started = False
        last_trial_num = -1
        for line in f:
            line=line.strip()
            if len(line)==0:
                trials_started=True
                continue

            if trials_started:
                line_parts=line.split(',')
                action = line_parts[3]
                if action=='Grasping' or action=='motor-grasp':
                     action = 'grasp'
                location = line_parts[4]
                trial_num = int(line_parts[0])
                if not trial_num==last_trial_num and line_parts[5]=='StartLaser':
                    if name_parts[0]=='visual':
                        trial_info['condition'].append('%s_%s_%s' % (name_parts[0], location, action))
                    else:
                        trial_info['condition'].append('%s_%s' % (name_parts[0], action))
                    trial_info['trial'].append(trial_idx)
                    trial_idx = trial_idx + 1
                    last_trial_num = trial_num
        f.close()

    for block_idx,evt_file in enumerate(evt_files):
        evts=pd.read_csv(os.path.join(evt_dir,evt_file))

        for trial_idx in np.unique(evts['Trial']):
            trial_info['block'].append(block_idx)

            # Figure out if correct trial
            correct_trial=np.any(evts.EventCode[np.where(evts.Trial == trial_idx)[0]]=='reward') or\
                          np.any(evts.EventCode[np.where(evts.Trial == trial_idx)[0]]=='manual_reward')
            trial_info['correct'].append(correct_trial)

    out_dir = os.path.join('/home/bonaiuto/Projects/tool_learning/preprocessed_data/', subj_name, date)
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)

    df=pd.DataFrame(trial_info, columns=['block','trial','condition','correct'])
    df.to_csv(os.path.join(out_dir,'trial_info.csv'),index=False)

if __name__=='__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    process_logs(subject, recording_date)