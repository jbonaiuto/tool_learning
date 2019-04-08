from datetime import datetime
from datetime import timedelta
import pandas as pd
import numpy as np
import os
import sys

from process_trial_info import run_process_trial_info

# Look at 13/3, 15/3, 18/3 - pulse codes are weird
excluded_days=['22.02.19']

def check_condition_trial_numbers(subject, date_start_str, date_end_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_end = datetime.strptime(date_end_str, '%d.%m.%y')

    all_conditions=[]
    all_dates=[]
    date_condition_ntrials={}
    condition_n_trials={}

    current_date = date_start
    while current_date <= date_end:
        current_date_str = datetime.strftime(current_date, '%d.%m.%y')
        if current_date_str not in excluded_days:
            print(current_date_str)
            fname='/home/bonaiuto/Projects/tool_learning/data/preprocessed_data/%s/%s/trial_info.csv' % (subject, current_date_str)
            #if not os.path.exists(fname):
            run_process_trial_info(subject, current_date_str)
            if os.path.exists(fname):
                all_dates.append(current_date_str)
                date_condition_ntrials[current_date_str]={}
                trials_df = pd.read_csv(fname)
                correct_rows = np.where(trials_df.correct == True)[0]
                conditions=np.unique(trials_df.condition)
                for c in conditions:
                    if not c in all_conditions:
                        all_conditions.append(c)
                    n_trials=len(np.where(trials_df.condition[correct_rows]==c)[0])
                    date_condition_ntrials[current_date_str][c]=n_trials
        current_date = current_date + timedelta(days=1)

    for date_str in all_dates:
        for c in all_conditions:
            if c in date_condition_ntrials[date_str]:
                print('%s - %s: %d' % (date_str, c, date_condition_ntrials[date_str][c]))
                if not c in condition_n_trials:
                    condition_n_trials[c]=0
                condition_n_trials[c]=condition_n_trials[c]+date_condition_ntrials[date_str][c]
        print('')

    print('Total')
    for c in all_conditions:
        print('%s: %d' % (c, condition_n_trials[c]))


if __name__=='__main__':
    subject = sys.argv[1]
    start_date = sys.argv[2]
    end_date = sys.argv[3]
    check_condition_trial_numbers(subject, start_date, end_date)

