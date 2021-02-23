"""
This script is equivalent of the jupyter notebook example_locust_dataset.ipynb
but in a standard python script.
"""

import pyqtgraph as pg

import os
import shutil

from matplotlib import pyplot
import time

from tridesclous import DataIO, CatalogueConstructor, CatalogueWindow, Peeler, PeelerWindow


def initialize_catalogueconstructor(dirname, filenames):
    # create a DataIO
    if os.path.exists(dirname):
        # remove is already exists
        shutil.rmtree(dirname)
    dataio = DataIO(dirname=dirname)

    # The dataset contains 4 channels : we use them all
    #dataio.set_channel_groups({'channels':{'channels':[0, 1, 2, 3]}})

    # feed DataIO
    dataio.set_data_source(type='Intan', filenames=filenames, channel_indexes=list(range(192)))
    #dataio.set_probe_file('/home/bonaiuto/Projects/tool_learning/recordings/rhd2000/betta/default.prb')

    dataio.add_one_channel_group(channels=range(192), chan_grp=0)

    print(dataio)


def preprocess_signals_and_peaks(dirname):
    dataio = DataIO(dirname=dirname)
    catalogueconstructor = CatalogueConstructor(dataio=dataio)

    catalogueconstructor.set_preprocessor_params(chunksize=1024,

                                                 # signal preprocessor
                                                 highpass_freq=250,
                                                 lowpass_freq=5000,
                                                 smooth_size=0,
                                                 common_ref_removal=False,
                                                 lostfront_chunksize=0,
                                                 signalpreprocessor_engine='opencl',

                                                 # peak detector
                                                 peakdetector_engine='opencl',
                                                 peak_sign='-',
                                                 relative_threshold=5,
                                                 peak_span=0.0002
                                                 )

    t1 = time.perf_counter()
    catalogueconstructor.estimate_signals_noise(seg_num=0, duration=10)
    t2 = time.perf_counter()
    print('estimate_signals_noise', t2 - t1)
    print(catalogueconstructor.signals_medians)
    print(catalogueconstructor.signals_mads)

    t1 = time.perf_counter()
    catalogueconstructor.run_signalprocessor(duration=300)
    t2 = time.perf_counter()
    print('run_signalprocessor', t2 - t1)

    print(catalogueconstructor)


def extract_waveforms_pca_cluster(dirname):
    dataio = DataIO(dirname=dirname)
    catalogueconstructor = CatalogueConstructor(dataio=dataio)
    print(catalogueconstructor)

    t1 = time.perf_counter()
    # ~ catalogueconstructor.extract_some_waveforms(n_left=-35, n_right=150,  nb_max=10000, align_waveform=True, subsample_ratio=20)
    catalogueconstructor.extract_some_waveforms(n_left=-20, n_right=30, nb_max=20000, align_waveform=False)
    t2 = time.perf_counter()
    print('extract_some_waveforms', t2 - t1)
    # ~ print(catalogueconstructor.some_waveforms.shape)
    print(catalogueconstructor)

    # ~ t1 = time.perf_counter()
    # ~ n_left, n_right = catalogueconstructor.find_good_limits(mad_threshold = 1.1,)
    # ~ t2 = time.perf_counter()
    # ~ print('n_left', n_left, 'n_right', n_right)
    # ~ print(catalogueconstructor.some_waveforms.shape)
    print(catalogueconstructor)

    # ~ print(catalogueconstructor.all_peaks)
    # ~ exit()

    t1 = time.perf_counter()
    catalogueconstructor.clean_waveforms(alien_value_threshold=100.)
    t2 = time.perf_counter()
    print('clean_waveforms', t2 - t1)

    # extract_some_noise
    t1 = time.perf_counter()
    catalogueconstructor.extract_some_noise(nb_snippet=300)
    t2 = time.perf_counter()
    print('extract_some_noise', t2 - t1)

    t1 = time.perf_counter()
    catalogueconstructor.project(method='pca_by_channel', n_components_by_channel=3)
    # ~ catalogueconstructor.project(method='tsne', n_components=2, perplexity=40., init='pca')
    t2 = time.perf_counter()
    print('project', t2 - t1)
    print(catalogueconstructor)

    t1 = time.perf_counter()
    catalogueconstructor.find_clusters(method='gmm', n_clusters=3*192)
    t2 = time.perf_counter()
    print('find_clusters', t2 - t1)
    print(catalogueconstructor)


def open_cataloguewindow(dirname):
    dataio = DataIO(dirname=dirname)
    catalogueconstructor = CatalogueConstructor(dataio=dataio)

    app = pg.mkQApp()
    win = CatalogueWindow(catalogueconstructor)
    win.show()

    app.exec_()


def clean_and_save_catalogue(dirname):
    dataio = DataIO(dirname=dirname)
    catalogueconstructor = CatalogueConstructor(dataio=dataio)

    catalogueconstructor.trash_small_cluster(n=5)

    # order cluster by waveforms rms
    catalogueconstructor.order_clusters(by='waveforms_rms')

    # put label 0 to trash
    mask = catalogueconstructor.all_peaks['cluster_label'] == 0
    catalogueconstructor.all_peaks['cluster_label'][mask] = -1
    catalogueconstructor.on_new_cluster()

    # save the catalogue
    catalogueconstructor.make_catalogue_for_peeler()


def run_peeler(dirname):
    dataio = DataIO(dirname=dirname)
    initial_catalogue = dataio.load_catalogue(chan_grp=0)

    peeler = Peeler(dataio)
    peeler.change_params(catalogue=initial_catalogue)

    t1 = time.perf_counter()
    peeler.run()
    t2 = time.perf_counter()
    print('peeler.run', t2 - t1)

    print()
    for seg_num in range(dataio.nb_segment):
        spikes = dataio.get_spikes(seg_num)
        print('seg_num', seg_num, 'nb_spikes', spikes.size)


def open_PeelerWindow(dirname):
    dataio = DataIO(dirname=dirname)
    initial_catalogue = dataio.load_catalogue(chan_grp=0)

    app = pg.mkQApp()
    win = PeelerWindow(dataio=dataio, catalogue=initial_catalogue)
    win.show()
    app.exec_()


def export_spikes(dirname):
    dataio = DataIO(dirname=dirname)
    dataio.export_spikes(dirname,formats='csv')
    dataio.export_spikes(dirname, formats='mat')


if __name__ == '__main__':
    dir_name='/home/bonaiuto/Projects/tool_learning/recordings/rhd2000/betta/test'
    initialize_catalogueconstructor(dir_name,
                                    ['/home/bonaiuto/Projects/tool_learning/recordings/rhd2000/betta/first_recording_181108_120858.rhd'])
    preprocess_signals_and_peaks(dir_name)
    extract_waveforms_pca_cluster(dir_name)
    clean_and_save_catalogue(dir_name)
    run_peeler(dir_name)
    export_spikes(dir_name)

    # open_cataloguewindow(dir_name)
    # open_PeelerWindow(dir_name)
