import os
import pandas as pd
from deeplabcut.utils import auxiliaryfunctions


def transfer_video(coder1_cfg, coder2_cfg, video):
    cfg1 = auxiliaryfunctions.read_config(coder1_cfg)
    cfg2 = auxiliaryfunctions.read_config(coder2_cfg)

    old_fname = os.path.join(cfg2['project_path'], 'labeled-data', video, 'CollectedData_' + cfg2['scorer'] + '.h5')
    df = pd.read_hdf(old_fname, 'df_with_missing')
    df.columns.set_levels([cfg1['scorer']],level=0,inplace=True)
    df.sort_index(inplace=True)
    df.to_csv(os.path.join(cfg1['project_path'], 'labeled-data', video, "CollectedData_" + cfg1['scorer'] + ".csv"))
    df.to_hdf(os.path.join(cfg1['project_path'], 'labeled-data', video, "CollectedData_" + cfg1['scorer'] + '.h5'), 'df_with_missing',
                          format='table', mode='w')

    pass

if __name__=='__main__':
    transfer_video('/home/bonaiuto/Projects/facial_expression/dlc_projects/face-Marine-2020-01-11/config.yaml',
                   '/home/bonaiuto/Projects/facial_expression/dlc_projects/face-Claudia-2020-01-11/config.yaml', 'zp09_intruder_20.11.19_1')
    transfer_video('/home/bonaiuto/Projects/facial_expression/dlc_projects/face-Marine-2020-01-11/config.yaml',
                   '/home/bonaiuto/Projects/facial_expression/dlc_projects/face-Claudia-2020-01-11/config.yaml', 'zp09_intruder_20.11.19_2')
    transfer_video('/home/bonaiuto/Projects/facial_expression/dlc_projects/face-Marine-2020-01-11/config.yaml',
                   '/home/bonaiuto/Projects/facial_expression/dlc_projects/face-Claudia-2020-01-11/config.yaml', 'zp10_unfam_male_27.11.19_gopro1')
    transfer_video('/home/bonaiuto/Projects/facial_expression/dlc_projects/face-Marine-2020-01-11/config.yaml',
                   '/home/bonaiuto/Projects/facial_expression/dlc_projects/face-Claudia-2020-01-11/config.yaml', 'zp10_unfam_male_27.11.19_gopro2')
