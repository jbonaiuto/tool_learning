import os
import sys
from tridesclous import DataIO, CatalogueConstructor
from config import read_config

cfg = read_config()

def reset_cell_labels(subject, date):
    output_dir = os.path.join(cfg['single_unit_spike_sorting_dir'], subject, date)

    for array_idx in range(len(cfg['arrays'])):
        array_dir=os.path.join(output_dir,'array_%d' % array_idx)
        for ch_grp in range(cfg['n_channels_per_array']):
            print(ch_grp)
            new_dataio = DataIO(dirname=array_dir, ch_grp=ch_grp)
            catalogueconstructor = CatalogueConstructor(dataio=new_dataio,chan_grp=ch_grp)

            assert(len(catalogueconstructor.clusters['cell_label'])==len(catalogueconstructor.cluster_labels))
            catalogueconstructor.clusters['cell_label']=catalogueconstructor.cluster_labels
            catalogueconstructor.compute_all_centroid()
            catalogueconstructor.make_catalogue_for_peeler()

if __name__=='__main__':
    subject = sys.argv[1]
    date = sys.argv[2]
    reset_cell_labels(subject, date)