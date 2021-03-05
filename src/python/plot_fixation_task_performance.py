import os
import sys
from datetime import datetime

import pandas as pd
import matplotlib.pyplot as plt

from config import read_config

cfg = read_config()

def plot_performance(subject):
    filename=os.path.join(cfg['log_dir'], subject, 'fixation_performance.csv')
    df=pd.read_csv(filename)
    print (df)

    df['Date'] = df['Date'].map(lambda x: datetime.strptime(str(x), '%d.%m.%Y'))
    x = df['Date']
    y = df['PercentCorrect']

    change_dates=[x[0]]
    last_dist_thresh=df['DistanceThreshold'][0]
    last_min_fixation=df['MinFixationTime'][0]
    dist_thresh_vals = ['%d' % last_dist_thresh]
    min_fix_vals=['%d' % last_min_fixation]

    for i in range(len(x)-1):
        if not (df['DistanceThreshold'][i+1]==last_dist_thresh and df['MinFixationTime'][i+1]==last_min_fixation):
            change_dates.append(x[i+1])
            last_dist_thresh=df['DistanceThreshold'][i+1]
            last_min_fixation=df['MinFixationTime'][i+1]
            dist_thresh_vals.append('%d' % last_dist_thresh)
            min_fix_vals.append('%d' % last_min_fixation)
    # plot
    plt.plot(x, y)
    for idx,change_date in enumerate(change_dates):
        plt.plot([change_date,change_date],[0,100],'r')
        plt.text(change_date,100,'Distance:'+dist_thresh_vals[idx]+'\nTime:'+min_fix_vals[idx])
    # beautify the x-labels
    plt.gcf().autofmt_xdate()

    plt.show()

if __name__=='__main__':
    subject = sys.argv[1]
    plot_performance(subject)