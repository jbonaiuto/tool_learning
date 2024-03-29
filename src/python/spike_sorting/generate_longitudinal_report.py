from datetime import datetime
from datetime import timedelta
import os
import scipy.io
import sys
import csv
from glob import glob
from shutil import copyfile
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from jinja2 import Environment, FileSystemLoader

from config import read_config

cfg = read_config()

array_map={'F1':'F1',
           'F5(HAND)':'F5hand',
           'F5(MOUTH)':'F5mouth',
           '46v/12r':'46v-12r',
           '45A':'45a',
           'F2':'F2'}
condition_map={'visual_grasp_right':'visual_grasp',
               'visual_grasp_left':'visual_grasp',
               'motor_grasp_left': 'motor_grasp',
               'motor_grasp_right': 'motor_grasp',
               'motor_grasp_center': 'motor_grasp',
               'motor_grasp': 'motor_grasp',
               'visual_pliers_right': 'visual_pliers',
               'visual_pliers_left': 'visual_pliers',
               'visual_rake_pull_left': 'visual_rake_pull',
               'visual_rake_pull_right': 'visual_rake_pull',
               'fixation': 'fixation',
               'motor_rake_center':'motor_rake'}

def generate_longitudinal_report(subject, date_start_str, date_end_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_end = datetime.strptime(date_end_str, '%d.%m.%y')

    report_output_dir=os.path.join(cfg['single_unit_spike_sorting_dir'],subject)
    if not os.path.exists(report_output_dir):
        os.mkdir(report_output_dir)
    if not os.path.exists(os.path.join(report_output_dir,'img')):
        os.mkdir(os.path.join(report_output_dir,'img'))

    array_results=[]
    date_results=[]

    for array in cfg['arrays']:
        current_date = date_start
        print(array)
        electrode_data={}
        dates=[]
        while current_date <= date_end:
            print(current_date)
            current_date_str = datetime.strftime(current_date, '%d.%m.%y')

            trial_info_fname=os.path.join(cfg['preprocessed_data_dir'],subject,current_date_str,'trial_info.csv')
            if os.path.exists(trial_info_fname):
                trial_info=pd.read_csv(trial_info_fname)

                trial_durations = trial_info['intan_duration'].values

                spike_data_dir = os.path.join(cfg['preprocessed_data_dir'], subject, datetime.strftime(current_date,'%d.%m.%y'),'spikes')

                fnames = glob(os.path.join(spike_data_dir, '%s*spikes.csv' % array))
                for fname in sorted(fnames):
                    electrode_df = pd.read_csv(fname)
                    if len(electrode_df):
                        electrode=np.unique(electrode_df.electrode)[0]
                        if not electrode in electrode_data:
                            electrode_data[electrode]={}
                        for cell in np.unique(electrode_df.cell):
                            if cell>=0:
                                if not cell in electrode_data[electrode]:
                                    electrode_data[electrode][cell]={}
                                trial_rates={}
                                for trial in np.unique(electrode_df.trial):
                                    if not np.isnan(trial):
                                        trial_condition=trial_info.condition[trial]
                                        if isinstance(trial_condition,str):
                                            condition=condition_map[trial_condition]
                                            rows=np.where((electrode_df.cell==cell) & (electrode_df.trial==trial))[0]
                                            n_spikes = float(len(rows))
                                            time=float(trial_durations[int(trial)])
                                            if not condition in trial_rates:
                                                trial_rates[condition]=[]
                                            trial_rates[condition].append(n_spikes/time)
                                for condition in trial_rates:
                                    if not condition in electrode_data[electrode][cell]:
                                        electrode_data[electrode][cell][condition] = []
                                        for x in range(len(dates)):
                                            electrode_data[electrode][cell][condition].append(0)
                                    electrode_data[electrode][cell][condition].append(np.mean(trial_rates[condition]))
                if len(fnames):
                    dates.append(current_date)
                    if not current_date_str in date_results:
                        date_results.append(current_date_str)
                    for electrode in electrode_data:
                        for cell in electrode_data[electrode]:
                            for condition in electrode_data[electrode][cell]:
                                if len(electrode_data[electrode][cell][condition])<len(dates):
                                    electrode_data[electrode][cell][condition].append(0)
            current_date = current_date + timedelta(days=1)

        electrodes=list(electrode_data.keys())
        cells=list(electrode_data[electrodes[0]].keys())
        conditions =sorted(electrode_data[electrodes[0]][cells[0]].keys())
        for electrode in electrode_data:
            fig=plt.figure(1,(12,4*len(conditions)))
            for idx,condition in enumerate(conditions):
                condition_data = {}
                for cell in electrode_data[electrode]:
                    if condition in electrode_data[electrode][cell]:
                        condition_data[str(cell)]=pd.Series(electrode_data[electrode][cell][condition], index=dates)
                if len(condition_data.keys())>0:
                    condition_df=pd.DataFrame(condition_data, index=dates)
                    ax=plt.subplot(len(conditions),1,idx+1)
                    condition_df.plot(ax=ax)
                    plt.ylabel('%s rate (Hz)' % condition)
            fname=os.path.join('img','%s_%d_spikes.png' % (array,electrode))
            plt.savefig(os.path.join(report_output_dir, fname))
            array_results.append({'array': array, 'channel': electrode, 'spike_img':fname,
                                  'impedance_img': os.path.join('img','%s_%d_impedances.png' % (array,electrode))})
            fig.clf()
            plt.close()

    array_impedances = {}
    for array in cfg['arrays']:
        array_impedances[array]={}
        for electrode in range(cfg['n_channels_per_array']):
            array_impedances[array][electrode]=[]

    impedance_dates=[]
    current_date = date_start
    while current_date <= date_end:
        print(current_date)
        current_date_str = datetime.strftime(current_date, '%d.%m.%y')
        for intan_dir in cfg['intan_data_dirs']:
            if os.path.exists(os.path.join(intan_dir,subject,current_date_str)):
                recording_base_path=os.path.join(intan_dir,subject,current_date_str)
                fname = os.path.join(recording_base_path, current_date_str, '%s_%s_impedance_data.csv' % (subject, current_date_str))
                if os.path.exists(fname):
                    print(fname)
                    with open(fname, 'rU') as csvfile:
                        reader = csv.reader(csvfile, delimiter=',')
                        empty_file=True
                        day_impedances={}
                        for array in cfg['arrays']:
                            day_impedances[array] = {}
                            for electrode in range(cfg['n_channels_per_array]']):
                                day_impedances[array][electrode] = float('NaN')
                        for idx, row in enumerate(reader):
                            if idx > 0:
                                empty_file=False
                                chan_name = row[1]
                                array = array_map[chan_name.split('-')[0]]
                                electrode = int(chan_name.split('-')[1])-1#+arrays.index(array)*32
                                impedance = float(row[4])
                                day_impedances[array][electrode]=impedance
                        for array in cfg['arrays']:
                            for electrode in range(cfg['n_channels_per_array']):
                                array_impedances[array][electrode].append(day_impedances[array][electrode])
                        if not empty_file:
                            impedance_dates.append(current_date_str)
                        else:
                            print('no impedance data for %s!' % current_date_str)
                break
        current_date = current_date + timedelta(days=1)

    for array in array_impedances:
        for electrode in array_impedances[array]:
            fig=plt.figure()
            ch_series=pd.Series(array_impedances[array][electrode],index=[datetime.strptime(x,'%d.%m.%y') for x in impedance_dates])
            ch_series.plot(figsize=(12,4))
            plt.ylabel('impedance')
            plt.savefig(os.path.join(report_output_dir, 'img','%s_%d_impedances.png' % (array,electrode)))
            fig.clf()
            plt.close()

    env = Environment(loader=FileSystemLoader(cfg['template_dir']))
    template = env.get_template('spike_sorting_longitudinal_template.html')
    template_output = template.render(subject=subject, array_results=array_results, date_results=date_results)

    out_filename = os.path.join(report_output_dir, 'spike_sorting_longitudinal_report.html')
    with open(out_filename, 'w') as fh:
        fh.write(template_output)

    copyfile(os.path.join(cfg['template_dir'], 'style.css'), os.path.join(report_output_dir, 'style.css'))

if __name__=='__main__':
    subject=sys.argv[1]
    end_date=sys.argv[2]
    generate_longitudinal_report(subject,'01.02.19',end_date)

