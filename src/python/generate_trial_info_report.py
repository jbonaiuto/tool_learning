import copy
import os
import sys
from datetime import datetime, timedelta
from shutil import copyfile

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from jinja2 import Environment, FileSystemLoader

from config import read_config
from process_trial_info import run_process_trial_info

cfg = read_config()

def generate_trial_info_report(subject, date_start_str):
    report_output_dir = os.path.join(cfg['preprocessed_data_dir'],subject)
    if not os.path.exists(report_output_dir):
        os.mkdir(report_output_dir)
    if not os.path.exists(os.path.join(report_output_dir, 'img')):
        os.mkdir(os.path.join(report_output_dir, 'img'))

    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_now = datetime.now()

    stage1_start=datetime.strptime('12.02.19', '%d.%m.%y')
    stage2_start = datetime.strptime('27.03.19', '%d.%m.%y')

    # All possible conditions
    current_date = date_start
    condition_trial_numbers={}

    weekly_date_index=[]
    weekly_condition_trial_numbers={}
    daily_date_index=[]
    daily_condition_trial_numbers = {}
    for condition in cfg['all_conditions']:
        weekly_condition_trial_numbers[condition]=[]
        daily_condition_trial_numbers[condition] = []

    while current_date <= date_now:
        date_str = datetime.strftime(current_date, '%d.%m.%y')
        info_dir = os.path.join(cfg['preprocessed_data_dir'], date_str)
        if not os.path.exists(info_dir):
            run_process_trial_info(subject, date_str)
        if os.path.exists(info_dir):
            df=pd.read_csv(os.path.join(info_dir, 'trial_numbers.csv'))
            if current_date.weekday()==0:
                condition_trial_numbers={}
            for condition,num_trials in zip(df['condition'].values, df['trials'].values):
                if condition in cfg['all_conditions']:
                    if not condition in condition_trial_numbers:
                        condition_trial_numbers[condition]=0
                    condition_trial_numbers[condition]=condition_trial_numbers[condition]+num_trials
            if current_date.weekday()==4:
                weekly_date_index.append(current_date)
                for condition in cfg['all_conditions']:
                    if condition in condition_trial_numbers:
                        weekly_condition_trial_numbers[condition].append(condition_trial_numbers[condition])
                    else:
                        weekly_condition_trial_numbers[condition].append(0)

            daily_date_index.append(current_date)
            for condition in cfg['all_conditions']:
                if condition in df['condition'].values:
                    daily_condition_trial_numbers[condition].append(df['trials'].values[np.where(df['condition'].values==condition)[0][0]])
                else:
                    daily_condition_trial_numbers[condition].append(0)

        current_date = current_date + timedelta(days=1)
        date_now = datetime.now()

    collapsed_weekly_condition_trial_numbers={}
    for collapsed_condition in cfg['collapsed_conditions']:

        collapsed_weekly_condition_trial_numbers[collapsed_condition]=[]
        for condition in cfg['all_conditions']:
            if condition.startswith(collapsed_condition):
                if len(collapsed_weekly_condition_trial_numbers[collapsed_condition])==0:
                    collapsed_weekly_condition_trial_numbers[collapsed_condition]=copy.copy(weekly_condition_trial_numbers[condition])
                else:
                    for idx, val in enumerate(weekly_condition_trial_numbers[condition]):
                        collapsed_weekly_condition_trial_numbers[collapsed_condition][idx]=collapsed_weekly_condition_trial_numbers[collapsed_condition][idx]+val

    collapsed_daily_condition_trial_numbers = {}
    for collapsed_condition in cfg['collapsed_conditions']:
        collapsed_daily_condition_trial_numbers[collapsed_condition] = []
        for condition in cfg['all_conditions']:
            if condition.startswith(collapsed_condition):
                if len(collapsed_daily_condition_trial_numbers[collapsed_condition]) == 0:
                    collapsed_daily_condition_trial_numbers[collapsed_condition] = copy.copy(daily_condition_trial_numbers[condition])
                else:
                    for idx, val in enumerate(daily_condition_trial_numbers[condition]):
                        collapsed_daily_condition_trial_numbers[collapsed_condition][idx]=collapsed_daily_condition_trial_numbers[collapsed_condition][idx] + val

    df=pd.DataFrame(collapsed_weekly_condition_trial_numbers, index=weekly_date_index)
    ax=df.plot(figsize=(12,4))
    max_val=np.max(df.values)
    ax.plot([stage1_start, stage1_start], [0, max_val], 'r--')
    plt.text(stage1_start, max_val, 'Stage 1')
    ax.plot([stage2_start, stage2_start], [0, max_val], 'r--')
    plt.text(stage2_start, max_val, 'Stage 2')
    plt.xlim((date_start, date_now+timedelta(days=31)))
    plt.savefig(os.path.join(report_output_dir,'img','collapsed_weekly_condition_trial_numbers.png'))

    df=pd.DataFrame(weekly_condition_trial_numbers, index=weekly_date_index)
    ax=df.plot(figsize=(12,4))
    max_val = np.max(df.values)
    ax.plot([stage1_start, stage1_start], [0, max_val], 'r--')
    plt.text(stage1_start, max_val, 'Stage 1')
    ax.plot([stage2_start, stage2_start], [0, max_val], 'r--')
    plt.text(stage2_start, max_val, 'Stage 2')
    plt.xlim((date_start, date_now + timedelta(days=31)))
    plt.savefig(os.path.join(report_output_dir,'img','weekly_condition_trial_numbers.png'))

    df = pd.DataFrame(collapsed_daily_condition_trial_numbers, index=daily_date_index)
    ax = df.plot(figsize=(12, 4))
    max_val = np.max(df.values)
    ax.plot([stage1_start, stage1_start], [0, max_val], 'r--')
    plt.text(stage1_start, max_val, 'Stage 1')
    ax.plot([stage2_start, stage2_start], [0, max_val], 'r--')
    plt.text(stage2_start, max_val, 'Stage 2')
    plt.xlim((date_start, date_now + timedelta(days=31)))
    plt.savefig(os.path.join(report_output_dir, 'img', 'collapsed_daily_condition_trial_numbers.png'))

    df = pd.DataFrame(daily_condition_trial_numbers, index=daily_date_index)
    ax = df.plot(figsize=(12, 4))
    max_val = np.max(df.values)
    ax.plot([stage1_start, stage1_start], [0, max_val], 'r--')
    plt.text(stage1_start, max_val, 'Stage 1')
    ax.plot([stage2_start, stage2_start], [0, max_val], 'r--')
    plt.text(stage2_start, max_val, 'Stage 2')
    plt.xlim((date_start, date_now + timedelta(days=31)))
    plt.savefig(os.path.join(report_output_dir, 'img', 'daily_condition_trial_numbers.png'))

    env = Environment(loader=FileSystemLoader(cfg['template_dir']))
    template = env.get_template('trial_info_template.html')
    template_output = template.render(subject=subject)

    out_filename = os.path.join(report_output_dir, 'trial_info_report.html')
    with open(out_filename, 'w') as fh:
        fh.write(template_output)

    copyfile(os.path.join(cfg['template_dir'], 'style.css'), os.path.join(report_output_dir, 'style.css'))


if __name__=='__main__':
    subject=sys.argv[1]
    start_date=sys.argv[2]
    generate_trial_info_report(subject, start_date)

