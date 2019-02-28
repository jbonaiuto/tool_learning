import glob
from datetime import datetime, timedelta

from process_trial_info import run_process_trial_info
from spike_sorting.compute_catalogue import run_compute_catalogue
from spike_sorting.compare_catalogues import run_compare_catalogues
from spike_sorting.generate_spike_sorting_report import generate_spike_sorting_report
from spike_sorting.generate_longitudinal_report import generate_longitudinal_report
from process_spikes import run_process_spikes
import transplant
import os

from spike_sorting.run_peeler import run_peeler


def resort(subject, date_start_str, date_end_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_end = datetime.strptime(date_end_str, '%d.%m.%y')

    current_date=date_start
    while current_date<=date_end:
        date_str=datetime.strftime(current_date, '%d.%m.%y')
        recording_path=os.path.join('/home/bonaiuto/Projects/tool_learning/data/recordings/rhd2000',subject,date_str)
        if os.path.exists(recording_path):
            if not len(glob.glob(os.path.join(recording_path,'*.raw'))):
                matlab = transplant.Matlab()
                matlab.addpath('/home/bonaiuto/Projects/tool_learning/src/matlab')
                matlab.preprocessSpikeData(subject, date_str)
                matlab.exit()

            run_compute_catalogue(subject, date_str)
            run_compare_catalogues(subject, date_str)
            run_process_trial_info(subject, date_str)
            run_process_spikes(subject, date_str)
            generate_spike_sorting_report(subject, date_str)


        current_date=current_date+timedelta(days=1)
    generate_longitudinal_report(subject, '29.01.19', date_end_str)

if __name__=='__main__':
    resort('betta','08.02.19','18.02.19')
