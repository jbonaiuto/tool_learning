from datetime import datetime, timedelta

import os
import sys

from multiunit.compute_catalogue import read_and_sort_data_files, preprocess_data, compute_catalogue
from multiunit.run_peeler import run_peeler, export_spikes
from process_multiunit import run_process_multiunit
from process_trial_info import run_process_trial_info

from config import read_config

cfg = read_config()

def array_export_spikes(array_idx, subject, date_str):
    output_dir = os.path.join(cfg['multi_unit_spike_sorting_dir'], subject, date_str,
                              'multiunit', 'array_%d' % array_idx)
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
        recording_path=os.path.join(cfg['intan_data_dir'],subject,date_str)
        if os.path.exists(recording_path):

            # Compute total duration (want to use all data for clustering)
            (data_file_names, total_duration) = read_and_sort_data_files(recording_path)

            if os.path.exists(recording_path) and len(data_file_names) > 0:

                run_process_trial_info(subject, date_str)

                preprocess_dir = os.path.join(cfg['multi_unit_spike_sorting_dir'], subject, date_str, 'preprocess')
                if not os.path.exists(preprocess_dir):
                    preprocess_data(subject, date_str)

                compute_catalogue(subject, date_str, len(data_file_names), total_duration)

                for array_idx in range(len(cfg['arrays'])):
                    array_export_spikes(array_idx, subject, date_str)

                run_process_multiunit(subject, date_str)

        current_date=current_date+timedelta(days=1)
        date_now = datetime.now()


if __name__=='__main__':
    subject = sys.argv[1]
    start_date = sys.argv[2]
    run_all(subject,start_date)
