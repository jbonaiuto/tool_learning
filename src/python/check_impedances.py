import csv
import os

from dateutil.parser import parse
from pandas import DataFrame, Series
import matplotlib.pyplot as plt

def check_impedances(subject):
    basepath=os.path.join('/home/bonaiuto/Projects/tool_learning/data/recordings/rhd2000/',subject)
    index=[]
    array_impedances={}
    for f in os.listdir(basepath):
        if os.path.isdir(os.path.join(basepath,f)):
            try:
                date=parse(f,dayfirst=True)
            except:
                continue

            fname=os.path.join(basepath,f,'%s_%s_impedance_data.csv' % (subject, f))
            if os.path.exists(fname):
                print(fname)
                with open(fname, 'rU') as csvfile:
                    reader = csv.reader(csvfile, delimiter=',')
                    for idx,row in enumerate(reader):
                        if idx>0:
                            chan_name=row[1]
                            array=chan_name.split('-')[0].upper()
                            if array in arrays:
                                if idx==1:
                                    index.append(date)
                                electrode=chan_name.split('-')[1]
                                impedance=float(row[4])
                                if not array in array_impedances:
                                    array_impedances[array]={}
                                if not electrode in array_impedances[array]:
                                    array_impedances[array][electrode]=[]
                                array_impedances[array][electrode].append(impedance)

    for array in array_impedances:
        ch_series={}
        for electrode in array_impedances[array]:
            ch_series[electrode]=Series(array_impedances[array][electrode],index=index)
        df=DataFrame(ch_series)
        df.plot()
        plt.title(array)
    plt.show()


if __name__=='__main__':
    check_impedances('betta')
