import sys
from tridesclous import DataIO, CatalogueConstructor

def reset_cell_labels(subject, date):
    output_dir = '/home/bonaiuto/Projects/tool_learning/data/spike_sorting/%s/%s' % (subject, date)

    for ch_grp in range(32*6):
        print(ch_grp)
        new_dataio = DataIO(dirname=output_dir, ch_grp=ch_grp)
        catalogueconstructor = CatalogueConstructor(dataio=new_dataio,chan_grp=ch_grp)

        assert(len(catalogueconstructor.clusters['cell_label'])==len(catalogueconstructor.cluster_labels))
        catalogueconstructor.clusters['cell_label']=catalogueconstructor.cluster_labels
        catalogueconstructor.compute_all_centroid()
        catalogueconstructor.make_catalogue_for_peeler()

if __name__=='__main__':
    subject = sys.argv[1]
    date = sys.argv[2]
    reset_cell_labels(subject, date)