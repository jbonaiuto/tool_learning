import json
from datetime import datetime, timedelta

import os
import sys

from process_spikes import run_process_spikes
from process_trial_info import run_process_trial_info
from spike_sorting.compare_catalogues import run_compare_catalogues
from spike_sorting.compute_catalogue import read_and_sort_data_files, preprocess_data, compute_catalogue
from spike_sorting.generate_longitudinal_report import generate_longitudinal_report
from spike_sorting.generate_spike_sorting_report import generate_spike_sorting_report
from spike_sorting.run_peeler import run_peeler, export_spikes

from config import read_config

cfg = read_config()

def array_peeler(array_idx, subject, date_str):
    output_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, date_str,
                              'array_%d' % array_idx)
    if os.path.exists(output_dir):
        for ch_grp in range(cfg['n_channels_per_array']):
            run_peeler(output_dir, chan_grp=ch_grp)


def array_export_spikes(array_idx, subject, date_str):
    output_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, date_str,
                              'array_%d' % array_idx)
    if os.path.exists(output_dir):
        for ch_grp in range(cfg['n_channels_per_array']):
            run_peeler(output_dir, chan_grp=ch_grp)
            export_spikes(output_dir, array_idx, ch_grp)


def run_good_dates_betta():
    dates=['26.02.19','27.02.19','28.02.19','01.03.19','04.03.19','05.03.19','07.03.19','08.03.19','11.03.19','12.03.19',
           '07.05.19','09.05.19','10.05.19','13.05.19','14.05.19','15.05.19','16.05.19','17.05.19','20.05.19','21.05.19',
           '01.07.19','02.07.19','03.07.19','04.07.19','05.07.19','08.07.19','10.07.19','11.07.19','12.07.19','15.07.19',
           '04.10.19','07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19']
    for date in dates:
        run_single_day('betta',date)
    generate_longitudinal_report(subject, dates[0], dates[-1])


def run_all(subject, date_start_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_now = datetime.now()

    current_date=date_start
    while current_date<=date_now:
        date_str=datetime.strftime(current_date, '%d.%m.%y')
        run_single_day(date_str, subject)

        current_date=current_date+timedelta(days=1)
        date_now = datetime.now()

    generate_longitudinal_report(subject, '29.01.19', datetime.strftime(date_now, '%d.%m.%y'))


def run_single_day(subject, date_str):
    recording_path = None
    for x in cfg['intan_data_dirs']:
        if os.path.exists(os.path.join(x, subject, date_str)):
            recording_path = os.path.join(x, subject, date_str)
    if recording_path is not None and os.path.exists(recording_path):

        base_path = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, date_str)
        if not os.path.exists(base_path):
            os.mkdir(base_path)
        json_fname = os.path.join(base_path, 'intan_files.json')
        if not os.path.exists(json_fname):
            # Compute total duration (want to use all data for clustering)
            data_files=read_and_sort_data_files(recording_path, date_str)
            with open(json_fname, 'w') as outfile:
                json.dump(data_files, outfile)
        else:
            with open(json_fname,'r') as infile:
                data_files=json.load(infile)

        if len(data_files) > 0:

            preprocess_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, date_str, 'preprocess')
            if not os.path.exists(preprocess_dir):
                preprocess_data(subject, date_str, data_files)

            compute_catalogue(subject, date_str, data_files)

            for array_idx in range(len(cfg['arrays'])):
                array_export_spikes(array_idx, subject, date_str)

            generate_spike_sorting_report(subject, date_str)

            run_process_trial_info(subject, date_str, data_files)

            run_process_spikes(subject, date_str, data_files)


if __name__=='__main__':
    subject = sys.argv[1]
    start_date = sys.argv[2]
    #run_all(subject,start_date)
    #run_single_day(subject,start_date)
    run_good_dates_betta()
