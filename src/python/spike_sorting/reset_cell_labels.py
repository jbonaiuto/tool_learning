import os
import sys
from tridesclous import DataIO, CatalogueConstructor

def reset_cell_labels(subject, date):
    output_dir = '/data/tool_learning/spike_sorting/%s/%s' % (subject, date)

    for array_idx in range(6):
        array_dir=os.path.join(output_dir,'array_%d' % array_idx)
        for ch_grp in range(32):
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