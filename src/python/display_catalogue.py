import sys

from tridesclous import DataIO, CatalogueConstructor, CatalogueWindow
import pyqtgraph as pg

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

    output_dir = '/home/bonaiuto/Projects/tool_learning/spike_sorting/%s/%s' % (subject,recording_date)
    arrays = ['F1', 'F5hand', 'F5mouth', '46v/12r', '45a', 'F2']
    open_cataloguewindow(output_dir, chan_grp)
