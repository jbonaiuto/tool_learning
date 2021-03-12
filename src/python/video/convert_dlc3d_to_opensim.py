import os
import pandas as pd

unlabeled_markers=['Thumb_MCP_L','Index_MCP_L','Middle_MCP_L','Ring_MCP_L','Little_MCP_L','Shoulder_L','Point_E1_L','Point_W1_L','Elbow_L']
def convert_dlc_label_to_opensim_label(dlc_label):
    opensim_label=''
    if dlc_label=='wrist':
        opensim_label='Wrist_L'
    elif dlc_label=='thumb_2':
        opensim_label='Thumb_PIP_L'
    elif dlc_label=='thumb_1':
        opensim_label='Thumb_DIP_L'
    elif dlc_label=='thumb_tip':
        opensim_label='Thumb_TIP_L'
    elif dlc_label=='index_2':
        opensim_label='Index_PIP_L'
    elif dlc_label=='index_1':
        opensim_label='Index_DIP_L'
    elif dlc_label=='index_tip':
        opensim_label='Index_TIP_L'
    elif dlc_label=='middle_2':
        opensim_label='Middle_PIP_L'
    elif dlc_label=='middle_1':
        opensim_label='Middle_DIP_L'
    elif dlc_label=='middle_tip':
        opensim_label='Middle_TIP_L'
    elif dlc_label=='ring_2':
        opensim_label='Ring_PIP_L'
    elif dlc_label=='ring_1':
        opensim_label='Ring_DIP_L'
    elif dlc_label=='ring_tip':
        opensim_label='Ring_TIP_L'
    elif dlc_label=='pinky_2':
        opensim_label='Little_PIP_L'
    elif dlc_label=='pinky_1':
        opensim_label='Little_DIP_L'
    elif dlc_label=='pinky_tip':
        opensim_label='Little_TIP_L'
    return opensim_label

def convert(fname):
    (path,file)=os.path.split(fname)
    (base,ext)=os.path.splitext(file)
    df=pd.read_hdf(fname)
    num_frames=len(df)
    num_markers=int(len(df.columns)/3)
    out_fname='%s.trc' % base
    file = open(os.path.join(path,out_fname), "w")
    file.write('PathFileType\t4\t(X/Y/Z)\t%s\n' % out_fname)
    file.write('DataRate\tCameraRate\tNumFrames\tNumMarkers\tUnits\tOrigDataRate\tOrigDataStartFrame\tOrigNumFrames\n')
    file.write('100.00\t100.00\t%d\t%d\tmm\t100.00\t1\t%d\n' % (num_frames, (num_markers+len(unlabeled_markers)), num_frames))
    file.write('Frame#\tTime')
    for i in range(num_markers):
        file.write('\t%s' % convert_dlc_label_to_opensim_label(df.columns[i*3][1]))
    for l in unlabeled_markers:
        file.write('\t%s' % l)
    file.write('\n')
    file.write('\t')
    for i in range(num_markers+len(unlabeled_markers)):
        file.write('\tX%d\tY%d\tZ%d' % ((i+1),(i+1),(i+1)))
    file.write('\n')
    for i in range(num_frames):
        file.write('%d\t%0.4f' % ((i+1),i*1/100.0))
        for col in df.columns:
            file.write('\t%.4f' % (df[col][i]))
        for l in unlabeled_markers:
            file.write('\tnan\tnan\tnan')
        file.write('\n')
    file.close()

if __name__=='__main__':
    convert('/media/bonaiuto/Maxtor/tool_learning/preprocessed_data/betta/01-03-2019/video/01-03-2019_10-50-28_1_DLC_3D.h5')