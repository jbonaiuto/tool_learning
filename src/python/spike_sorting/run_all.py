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


def run_all(subject, date_start_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_now = datetime.now()

    current_date=date_start
    while current_date<=date_now:
        date_str=datetime.strftime(current_date, '%d.%m.%y')
        recording_path=None
        for x in cfg['intan_data_dirs']:
            if os.path.exists(os.path.join(x,subject,date_str)):
                recording_path=os.path.join(x,subject,date_str)

        if recording_path is not None:

            # Compute total duration (want to use all data for clustering)
            (data_file_names, total_duration) = read_and_sort_data_files(recording_path)

            if os.path.exists(recording_path) and len(data_file_names) > 0:

                run_process_trial_info(subject, date_str)

                preprocess_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, date_str, 'preprocess')
                if not os.path.exists(preprocess_dir):
                    preprocess_data(subject, date_str)

                compute_catalogue(subject, date_str, len(data_file_names), total_duration)

                for array_idx in range(len(cfg['arrays'])):
                    array_peeler(array_idx, subject, date_str)

                generate_spike_sorting_report(subject, date_str)

                run_compare_catalogues(subject, date_str)

                for array_idx in range(len(cfg['arrays'])):
                    array_export_spikes(array_idx, subject, date_str)

                run_process_spikes(subject, date_str)

        current_date=current_date+timedelta(days=1)
        date_now = datetime.now()

    generate_longitudinal_report(subject, '29.01.19', datetime.strftime(date_now, '%d.%m.%y'))


if __name__=='__main__':
    subject = sys.argv[1]
    start_date = sys.argv[2]
    run_all(subject,start_date)
