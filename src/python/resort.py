from datetime import datetime, timedelta

from compute_catalogue import run_compute_catalogue


def resort(subject, date_start_str, date_end_str):
    date_start = datetime.strptime(date_start_str, '%d.%m.%y')
    date_end = datetime.strptime(date_end_str, '%d.%m.%y')

    current_date=date_start
    while current_date<=date_end:
        run_compute_catalogue(subject, datetime.strftime(current_date, '%d.%m.%y'))

        current_date=current_date+timedelta(days=1)

if __name__=='__main__':
    resort('betta','21.11.18','29.01.19')
