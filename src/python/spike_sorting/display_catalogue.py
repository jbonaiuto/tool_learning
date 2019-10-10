import os
import sys

from tridesclous import DataIO, CatalogueConstructor, CatalogueWindow
import pyqtgraph as pg

from config import read_config

cfg = read_config()

def open_cataloguewindow(dirname, chan_grp):
    dataio = DataIO(dirname=dirname)
    catalogueconstructor = CatalogueConstructor(dataio=dataio, chan_grp=chan_grp)

    app = pg.mkQApp()
    win = CatalogueWindow(catalogueconstructor)
    win.show()

    app.exec_()


if __name__ == '__main__':
    subject = sys.argv[1]
    recording_date = sys.argv[2]
    chan_grp = int(sys.argv[3])

    output_dir = os.path.join(cfg['single_unit_spike_sorting_dir'],subject,recording_date)
    open_cataloguewindow(output_dir, chan_grp)
