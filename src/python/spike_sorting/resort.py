import glob
from datetime import datetime, timedelta

import transplant
import os

from process_spikes import run_process_spikes
from process_trial_info import run_process_trial_info
from spike_sorting.compare_catalogues import run_compare_catalogues
from spike_sorting.compute_catalogue import read_and_sort_data_files, preprocess_data, compute_catalogue
from spike_sorting.generate_longitudinal_report import generate_longitudinal_report
from spike_sorting.generate_spike_sorting_report import generate_spike_sorting_report
from spike_sorting.run_peeler import run_peeler, export_spikes


def resort(subject, date_start_str, date_end_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_end = datetime.strptime(date_end_str, '%d.%m.%y')

    current_date=date_start
    while current_date<=date_end:
        date_str=datetime.strftime(current_date, '%d.%m.%y')
        recording_path=os.path.join('/data/tool_learning/recordings/rhd2000',subject,date_str)
        if os.path.exists(recording_path):

            # Compute total duration (want to use all data for clustering)
            (data_file_names, total_duration) = read_and_sort_data_files(recording_path)

            if os.path.exists(recording_path) and len(data_file_names) > 0:

                preprocess_data(subject, date_str, data_file_names, total_duration)

                compute_catalogue(subject, date_str, len(data_file_names), total_duration)

                for array_idx in range(6):
                    output_dir = os.path.join('/data/tool_learning/spike_sorting/', subject, date_str,
                                              'array_%d' % array_idx)
                    if os.path.exists(output_dir):
                        for ch_grp in range(32):
                            run_peeler(output_dir, chan_grp=ch_grp)

                generate_spike_sorting_report(subject, date_str)

                run_compare_catalogues(subject, date_str)
                for array_idx in range(6):
                    output_dir = os.path.join('/data/tool_learning/spike_sorting/', subject, date_str,
                                              'array_%d' % array_idx)
                    if os.path.exists(output_dir):
                        for ch_grp in range(32):
                            run_peeler(output_dir, chan_grp=ch_grp)
                            export_spikes(output_dir, array_idx, ch_grp)

                run_process_trial_info(subject, date_str)
                run_process_spikes(subject, date_str)


        current_date=current_date+timedelta(days=1)
    generate_longitudinal_report(subject, '29.01.19', date_end_str)

if __name__=='__main__':
    resort('betta','01.02.19','20.04.19')
