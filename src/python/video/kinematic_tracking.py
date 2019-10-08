import json

import matplotlib.pyplot as plt
import cv2
import glob
import os
import sys
import subprocess

from matplotlib import gridspec
from moviepy.video.io.VideoFileClip import VideoFileClip
from tqdm import tqdm

from deeplabcut.pose_estimation_3d import undistort_points
from deeplabcut.utils import auxiliaryfunctions, auxiliaryfunctions_3d, Path, img_as_ubyte, load_config

import deeplabcut
import pandas as pd
import numpy as np

from video.preprocess_videos import CAMERA_VIEWS, combine_video
from video.transformations import unit_vector, rotation_matrix
from video.video_processor import VideoProcessorCV
from video import select_coordinate

dlc_3d_projects={
    'motor_task_grasp': {
        'motor_grasp_left': 'motor_grasp_3d-Jimmy-2019-08-13-3d',
        'motor_grasp_center': 'motor_grasp_3d-Jimmy-2019-08-13-3d',
        'motor_grasp_right': 'motor_grasp_3d-Jimmy-2019-08-13-3d',
        'motor_rake_left': 'motor_grasp_3d-Jimmy-2019-09-27-3d',
        'motor_rake_center': 'motor_grasp_3d-Jimmy-2019-09-27-3d',
        'motor_rake_right': 'motor_grasp_3d-Jimmy-2019-09-27-3d'
    },
    'visual_task_stage1-2': {
        'visual_grasp_left': 'visual_grasp_3d-Jimmy-2019-08-19-3d',
        'visual_grasp_right': 'visual_grasp_3d-Jimmy-2019-08-19-3d',
        'visual_pliers_left': 'visual_pliers_3d-Jimmy-2019-09-21-3d',
        'visual_pliers_right': 'visual_pliers_3d-Jimmy-2019-09-21-3d',
        'visual_rake_left': 'visual_rake_3d-Jimmy-2019-09-26-3d',
        'visual_rake_right': 'visual_rake_3d-Jimmy-2019-09-26-3d'
    }
}

dlc_projects={
    'motor_task_grasp': {
        'motor_grasp_left': {
            'front': 'motor_grasp_front-Anita-2019-06-18',
            'side': 'motor_grasp_side-Anita-2019-07-03',
            'top': 'motor_grasp_top-Anita-2019-07-03'
        },
        'motor_grasp_center': {
            'front': 'motor_grasp_front-Anita-2019-06-18',
            'side': 'motor_grasp_side-Anita-2019-07-03',
            'top': 'motor_grasp_top-Anita-2019-07-03'
        },
        'motor_grasp_right': {
            'front': 'motor_grasp_front-Anita-2019-06-18',
            'side': 'motor_grasp_side-Anita-2019-07-03',
            'top': 'motor_grasp_top-Anita-2019-07-03'
        }
    },
    'motor_task_rake': {
        'motor_rake_left': {
            'front': 'motor_rake_front-Sebastien-2019-08-14',
            'side': 'motor_rake_side-Sebastien-2019-08-14',
            'top': 'motor_rake_top-Sebastien-2019-08-14'
        },
        'motor_rake_center': {
            'front': 'motor_rake_front-Sebastien-2019-08-14',
            'side': 'motor_rake_side-Sebastien-2019-08-14',
            'top': 'motor_rake_top-Sebastien-2019-08-14'
        },
        'motor_rake_right': {
            'front': 'motor_rake_front-Sebastien-2019-08-14',
            'side': 'motor_rake_side-Sebastien-2019-08-14',
            'top': 'motor_rake_top-Sebastien-2019-08-14'
        }
    },
    'visual_task_stage1-2': {
        'visual_grasp_left':{
            'front': 'visual_grasp_front-Anita-2019-07-25',
            'side': 'visual_grasp_side-Anita-2019-07-25',
            'top': 'visual_grasp_top-Anita-2019-07-25'
        },
        'visual_grasp_right':{
            'front': 'visual_grasp_front-Anita-2019-07-25',
            'side': 'visual_grasp_side-Anita-2019-07-25',
            'top': 'visual_grasp_top-Anita-2019-07-25'
        },
        'visual_pliers_left':{
            'front': 'visual_pliers_front-Anita-2019-08-07',
            'side': 'visual_pliers_side-Anita-2019-08-07',
            'top': 'visual_pliers_top-Anita-2019-08-07',
        },
        'visual_pliers_right':{
            'front': 'visual_pliers_front-Anita-2019-08-07',
            'side': 'visual_pliers_side-Anita-2019-08-07',
            'top': 'visual_pliers_top-Anita-2019-08-07',
        },
        'visual_rake_left':{
            'front': 'visual_rake_front-Anita-2019-08-07',
            'side': 'visual_rake_side-Anita-2019-08-07',
            'top': 'visual_rake_top-Anita-2019-08-07',
        },
        'visual_rake_right':{
            'front': 'visual_rake_front-Anita-2019-08-07',
            'side': 'visual_rake_side-Anita-2019-08-07',
            'top': 'visual_rake_top-Anita-2019-08-07',
        }
    }
}

def process_videos(subject, date):
    base_video_path = os.path.join('/home/bonaiuto/Projects/tool_learning/preprocessed_data', subject, date, 'video')
    with open(os.path.join(base_video_path,'config.json')) as json_file:
        cfg=json.load(json_file)

    trial_info = pd.read_csv('/home/bonaiuto/Projects/tool_learning/preprocessed_data/%s/%s/trial_info.csv' % (subject, date))

    origin_checked={
        'front': False,
        'side': False,
        'top': False,
    }
    table_corners_checked={
        'front': False,
        'side': False,
        'top': False,
    }
    tocchini_checked={
        'front': False,
        'side': False,
        'top': False,
    }
    for t_idx in range(len(trial_info.index)):
        if len(trial_info.video[t_idx]):
            fname=trial_info.video[t_idx]
            (base, ext) = os.path.splitext(fname)

            block = trial_info.block[t_idx]
            task=trial_info.task[t_idx]
            condition=trial_info.condition[t_idx]
            trial_num = trial_info.trial[t_idx]

            video_fnames = {}
            for view in CAMERA_VIEWS:
                view_path=os.path.join(base_video_path, view)
                if task in dlc_projects and condition in dlc_projects[task] and view in dlc_projects[task][condition]:
                    dlc_cfg=os.path.join('/home/bonaiuto/Projects/tool_learning/preprocessed_data/dlc_projects',
                                     dlc_projects[task][condition][view],'config.yaml')
                    deeplabcut.analyze_videos(dlc_cfg, [os.path.join(view_path, fname)], shuffle=1, save_as_csv=True)
                    deeplabcut.filterpredictions(dlc_cfg, os.path.join(view_path, fname), shuffle=1)
                    deeplabcut.create_labeled_video(dlc_cfg, [os.path.join(view_path, fname)], shuffle=1, filtered=True,
                                                    draw_skeleton=True)
                    dlc_files = glob.glob(os.path.join(base_video_path, view, '%s*DeepCut*.mp4' % base))
                    if len(dlc_files):
                        video_fnames[view] = dlc_files[0]

            if len(video_fnames.keys()) == len(CAMERA_VIEWS):
                out_path = os.path.join(base_video_path, 'combined')

                if task in dlc_3d_projects and condition in dlc_3d_projects[task]:
                    dlc_cfg = os.path.join('/home/bonaiuto/Projects/tool_learning/preprocessed_data/dlc_projects',
                                       dlc_3d_projects[task][condition], 'config.yaml')
                    fnames={}
                    for view in CAMERA_VIEWS:
                        view_path = os.path.join(base_video_path, view)
                        fnames[view]=os.path.join(view_path, fname)

                        clip = VideoFileClip(fnames[view])
                        clip.reader.initialize()
                        image = img_as_ubyte(clip.reader.read_frame())

                        if not origin_checked[view]:
                            init_origin=None
                            if view in cfg['origins'] and cfg['origins'][view] is not None:
                                init_origin = np.array(cfg['origins'][view])
                            cfg['origins'][view]=select_coordinate.show(image, 'Select origin', init_coords=[init_origin])[0]
                            origin_checked[view]=True

                        if not table_corners_checked[view]:
                            init_table_corners=[]
                            if view in cfg['table_corners'] and cfg['table_corners'][view] is not None:
                                init_table_corners=cfg['table_corners'][view]
                            selected_corners=select_coordinate.show(image, 'Select table corners', init_coords=init_table_corners)
                            cfg['table_corners'][view]=[]
                            for corner in selected_corners:
                                cfg['table_corners'][view].append(corner)
                            table_corners_checked[view]=True

                        if not tocchini_checked[view]:
                            init_tocchini=[]
                            if view in cfg['tocchini'] and cfg['tocchini'][view] is not None:
                                init_tocchini = cfg['tocchini'][view]
                            selected_tocchini = select_coordinate.show(image, 'Select tocchini', init_coords=init_tocchini)
                            cfg['tocchini'][view] = []
                            for tocchino in selected_tocchini:
                                cfg['tocchini'][view].append(tocchino)
                            tocchini_checked[view] = True
                        clip.close()

                    (fname, table_corners_3d, tocchini_3d)=triangulate(dlc_cfg, cfg['origins'], cfg['table_corners'], cfg['tocchini'], fnames,
                                                          filterpredictions=True, destfolder=base_video_path, save_as_csv=True)
                    vid_fname=create_labeled_video_3d(dlc_cfg, fname, table_corners_3d, tocchini_3d, fps=100, trailpoints=5,
                                                      xlim=[-.26, .26], ylim=[-.51, 0],zlim=[-0.01,0.1])
                    video_fnames['3d']=os.path.split(vid_fname)[1]

                    combine_video(base_video_path, video_fnames, out_path, '%d-%d_%s-%s_labeled.mp4' % (block, trial_num, task, condition))

    with open(os.path.join(base_video_path,'config.json'),'w') as outfile:
        json.dump(cfg, outfile)

def triangulate(config, origins, table_corners, tocchini, video_path, filterpredictions=True, destfolder=None,
                save_as_csv=False):

    cfg_3d = auxiliaryfunctions.read_config(config)
    img_path, path_corners, path_camera_matrix, path_undistort = auxiliaryfunctions_3d.Foldernames3Dproject(cfg_3d)
    cam_names = cfg_3d['camera_names']
    pcutoff = cfg_3d['pcutoff']
    scorer_3d = cfg_3d['scorername_3d']

    snapshots = {}
    for cam in cam_names:
        snapshots[cam] = cfg_3d[str('config_file_' + cam)]
        # Check if the config file exists
        if not os.path.exists(snapshots[cam]):
            raise Exception(str("It seems the file specified in the variable config_file_" + str(cam)) +
                            " does not exist. Please edit the config file with correct file path and retry.")

    path_stereo_file = os.path.join(path_camera_matrix, 'stereo_params.pickle')
    stereo_file = auxiliaryfunctions.read_pickle(path_stereo_file)

    position=np.array([0.0,0.0,0.0])
    rotation=np.array([[1.0, 0.0, 0.0],[0.0, 1.0, 0.0], [0.0, 0.0, 1.0]])
    rotations=[np.linalg.inv(rotation)]
    translations=[np.matmul(-rotation, position)]
    projections=[]

    for cam_idx in range(1,len(cam_names)):
        pair_rotation=stereo_file[cam_names[0] + '-' + cam_names[cam_idx]]['R']
        pair_translation = stereo_file[cam_names[0] + '-' + cam_names[cam_idx]]['T']
        rotations.append(np.matmul(pair_rotation,rotations[0]))
        translations.append(np.matmul(pair_rotation, translations[0])+np.transpose(pair_translation))

    for cam_idx in range(len(cam_names)):
        path_camera_file = os.path.join(path_camera_matrix, '%s_intrinsic_params.pickle' % cam_names[cam_idx])
        intrinsic_file = auxiliaryfunctions.read_pickle(path_camera_file)

        projection=np.zeros((3,4))
        projection[:,0:3]=rotations[cam_idx]
        projection[:,3]=translations[cam_idx]

        projection=np.matmul(intrinsic_file[cam_names[cam_idx]]['mtx'], projection)
        projections.append(projection)

    [origin, pairs_used]=locate(cam_names,{'front':1,'side':1,'top':1}, origins, pcutoff, projections)

    table_coords_3d=[]
    for corner_idx in range(len(table_corners['front'])):
        corner={}
        for view in cam_names:
            corner[view]=table_corners[view][corner_idx]
        [coord,pairs_used]=locate(cam_names,{'front':1,'side':1,'top':1},corner,pcutoff,projections)
        table_coords_3d.append(coord)

    xy_norm=np.array([[0,0,1]])

    table_center=np.mean(np.array(table_coords_3d),axis=0)

    table_vec1=table_coords_3d[0]-table_center
    table_vec2=table_coords_3d[1]-table_center
    table_norm=unit_vector(np.cross(np.transpose(table_vec1),np.transpose(table_vec2)))

    rot_vec=unit_vector(np.cross(xy_norm, table_norm), axis=1)
    rot_angle=-np.arccos(np.abs(np.sum(xy_norm*table_norm))/np.sqrt(np.sum(table_norm**2)))

    rot_mat=rotation_matrix(rot_angle, np.transpose(rot_vec))
    rot_mat=np.matmul(rotation_matrix(np.pi, [1, 0, 0]), rot_mat)
    rot_mat=rot_mat[0:3,0:3]

    origin=np.matmul(rot_mat, origin)

    for idx, coord in enumerate(table_coords_3d):
        coord=np.matmul(rot_mat, coord)-origin
        table_coords_3d[idx]=coord

    tocchini_coords_3d=[]
    for tocchino_idx in range(len(tocchini['front'])):
        tocchino={}
        for view in cam_names:
            tocchino[view]=tocchini[view][tocchino_idx]
        [coord,pairs_used]=locate(cam_names,{'front':1,'side':1,'top':1},tocchino,pcutoff,projections)
        tocchini_coords_3d.append(np.matmul(rot_mat,coord)-origin)

    file_name_3d_scorer = []
    dataname = []
    for cam_name in cam_names:
        config = snapshots[cam_name]
        cfg = auxiliaryfunctions.read_config(config)

        shuffle = cfg_3d[str('shuffle_' + cam_name)]
        trainingsetindex = cfg_3d[str('trainingsetindex_' + cam_name)]

        video=video_path[cam_name]
        vname = Path(video).stem


        trainFraction = cfg['TrainingFraction'][trainingsetindex]
        modelfolder = os.path.join(cfg["project_path"],
                                   str(auxiliaryfunctions.GetModelFolder(trainFraction, shuffle, cfg)))
        path_test_config = Path(modelfolder) / 'test' / 'pose_cfg.yaml'
        dlc_cfg = load_config(str(path_test_config))
        Snapshots = np.array([fn.split('.')[0] for fn in os.listdir(os.path.join(modelfolder, 'train')) if "index" in fn])
        snapshotindex = cfg['snapshotindex']

        increasing_indices = np.argsort([int(m.split('-')[1]) for m in Snapshots])
        Snapshots = Snapshots[increasing_indices]

        dlc_cfg['init_weights'] = os.path.join(modelfolder, 'train', Snapshots[snapshotindex])
        trainingsiterations = (dlc_cfg['init_weights'].split(os.sep)[-1]).split('-')[-1]
        DLCscorer = auxiliaryfunctions.GetScorerName(cfg, shuffle, trainFraction,
                                                     trainingsiterations=trainingsiterations)

        file_name_3d_scorer.append(DLCscorer)

        if filterpredictions:
            dataname.append(os.path.join(destfolder, cam_name, vname + DLCscorer + 'filtered.h5'))
        else:
            dataname.append(os.path.join(destfolder, cam_name, vname + DLCscorer + '.h5'))

    output_filename = os.path.join(destfolder, vname + '_' + scorer_3d)
    if os.path.isfile(output_filename + '.h5'):  # TODO: don't check twice and load the pickle file to check if the same snapshots + camera matrices were used.
        print("Already analyzed...", output_filename+'.h5')
    else:
        if len(dataname) > 0:
            df = pd.read_hdf(dataname[0])
            df_3d, scorer_3d, bodyparts = auxiliaryfunctions_3d.create_empty_df(df, scorer_3d, flag='3d')

            for bpindex, bp in enumerate(bodyparts):
                bp_coords=np.zeros((3,len(df_3d)))
                for f_idx in range(len(df_3d)):
                    likelihoods={}
                    coords={}
                    for cam_idx,cam_name in enumerate(cam_names):
                        dataframe_cam = pd.read_hdf(dataname[cam_idx])
                        scorer_cam = dataframe_cam.columns.get_level_values(0)[0]
                        likelihoods[cam_name]=dataframe_cam[scorer_cam][bp]['likelihood'].values[f_idx]
                        coords[cam_name]=np.array([dataframe_cam[scorer_cam][bp]['x'].values[f_idx], dataframe_cam[scorer_cam][bp]['y'].values[f_idx]])
                    [coord, pairs_used] = locate(cam_names, likelihoods, coords, pcutoff, projections)

                    coord=np.matmul(rot_mat, coord)-origin
                    if pairs_used < 2:
                        coord[0]=np.nan
                        coord[1]=np.nan
                        coord[2] = np.nan
                    bp_coords[:,f_idx]=np.squeeze(coord)
                df_3d.iloc[:][scorer_3d, bp, 'x'] = bp_coords[0,:]
                df_3d.iloc[:][scorer_3d, bp, 'y'] = bp_coords[1,:]
                df_3d.iloc[:][scorer_3d, bp, 'z'] = bp_coords[2,:]

            # X_pairs=[]
            # for cam_idx1 in range(len(cam_names)):
            #     for cam_idx2 in range(cam_idx1+1,len(cam_names)):
            #         # undistort points for this pair
            #         # print("Undistorting...")
            #         # dataFrame_camera1_undistort, dataFrame_camera2_undistort, stereomatrix, path_stereo_file = undistort_points(config,
            #         #                                                                                                             [dataname[cam_idx1],dataname[cam_idx2]],
            #         #                                                                                                             str(cam_names[cam_idx1] + '-' + cam_names[cam_idx2]),
            #         #                                                                                                             destfolder)
            #         # if len(dataFrame_camera1_undistort) != len(dataFrame_camera2_undistort):
            #         #     raise Exception(
            #         #         "The number of frames do not match in the two videos. Please make sure that your videos have same number of frames and then retry!")
            #
            #         dataframe_cam1 = pd.read_hdf(dataname[cam_idx1])
            #         dataframe_cam2 = pd.read_hdf(dataname[cam_idx2])
            #
            #         print("Computing the triangulation...")
            #         X_final = []
            #         triangulate = []
            #         scorer_cam1 = dataframe_cam1.columns.get_level_values(0)[0]
            #         scorer_cam2 = dataframe_cam2.columns.get_level_values(0)[0]
            #         P1 = stereomatrix['P1']
            #         P2 = stereomatrix['P2']
            #
            #         for bpindex, bp in enumerate(bodyparts):
            #             # Extract the indices of frames where the likelihood of a bodypart for both cameras are less than pvalue
            #             likelihoods = np.array([dataFrame_camera1_undistort[scorer_cam1][bp]['likelihood'].values[:],
            #                                     dataFrame_camera2_undistort[scorer_cam2][bp]['likelihood'].values[:]])
            #             likelihoods = likelihoods.T
            #
            #             # Extract frames where likelihood for both the views is less than the pcutoff
            #             low_likelihood_frames = np.any(likelihoods < pcutoff, axis=1)
            #             # low_likelihood_frames = np.all(likelihoods < pcutoff, axis=1)
            #
            #             low_likelihood_frames = np.where(low_likelihood_frames == True)[0]
            #             points_cam1_undistort = np.array([dataFrame_camera1_undistort[scorer_cam1][bp]['x'].values[:],
            #                                               dataFrame_camera1_undistort[scorer_cam1][bp]['y'].values[:]])
            #             points_cam1_undistort = points_cam1_undistort.T
            #
            #             # For cam1 camera: Assign nans to x and y values of a bodypart where the likelihood for is less than pvalue
            #             points_cam1_undistort[low_likelihood_frames] = np.nan, np.nan
            #             points_cam1_undistort = np.expand_dims(points_cam1_undistort, axis=1)
            #
            #             points_cam2_undistort = np.array([dataFrame_camera2_undistort[scorer_cam2][bp]['x'].values[:],
            #                                               dataFrame_camera2_undistort[scorer_cam2][bp]['y'].values[:]])
            #             points_cam2_undistort = points_cam2_undistort.T
            #
            #             # For cam2 camera: Assign nans to x and y values of a bodypart where the likelihood is less than pvalue
            #             points_cam2_undistort[low_likelihood_frames] = np.nan, np.nan
            #             points_cam2_undistort = np.expand_dims(points_cam2_undistort, axis=1)
            #
            #             X_l = auxiliaryfunctions_3d.triangulatePoints(P1, P2, points_cam1_undistort, points_cam2_undistort)
            #
            #             # ToDo: speed up func. below by saving in numpy.array
            #             X_final.append(X_l)
            #         X_pairs.append(X_final)
            # X_pairs=np.asanyarray(X_pairs)
            # X_average=np.squeeze(np.mean(X_pairs,axis=0))
            # for i in range(X_average.shape[0]):
            #     for j in range(X_average.shape[2]):
            #         X_average[i,0:3,j] = np.squeeze(np.matmul(rot_mat,np.expand_dims(X_average[i,0:3,j],axis=1))-origin)
            # triangulate.append(X_average)
            # triangulate = np.asanyarray(triangulate)

            # metadata = {}
            # metadata['stereo_matrix'] = stereomatrix
            # metadata['stereo_matrix_file'] = path_stereo_file
            # metadata['scorer_name'] = {cam_names[0]: file_name_3d_scorer[0], cam_names[1]: file_name_3d_scorer[1]}

            # Create an empty dataframe to store x,y,z of 3d data
            # for bpindex, bp in enumerate(bodyparts):
            #     df_3d.iloc[:][scorer_3d, bp, 'x'] = triangulate[0, bpindex, 0, :]
            #     df_3d.iloc[:][scorer_3d, bp, 'y'] = triangulate[0, bpindex, 1, :]
            #     df_3d.iloc[:][scorer_3d, bp, 'z'] = triangulate[0, bpindex, 2, :]

            df_3d.to_hdf(str(output_filename + '.h5'), 'df_with_missing', format='table', mode='w')
            # auxiliaryfunctions_3d.SaveMetadata3d(str(output_filename + '_includingmetadata.pickle'), metadata)

            if save_as_csv:
                df_3d.to_csv(str(output_filename + '.csv'))

            print("Triangulated data for video", vname)
            print("Results are saved under: ", destfolder)

    return str(output_filename + '.h5'), table_coords_3d, tocchini_coords_3d


def create_labeled_video_3d(config, path, table_corners, tocchini, trailpoints=0, fps=30,
                            view=[None, -45], xlim=[None, None], ylim=[None, None], zlim=[None, None],
                            draw_skeleton=True):
    # Read the config file and related variables
    cfg_3d = auxiliaryfunctions.read_config(config)
    alphaValue = cfg_3d['alphaValue']
    cmap = cfg_3d['colormap']
    bodyparts2connect = cfg_3d['skeleton']
    skeleton_color = cfg_3d['skeleton_color']

    # Flatten the list of bodyparts to connect
    bodyparts2plot = list(np.unique([val for sublist in bodyparts2connect for val in sublist]))
    color = plt.cm.get_cmap(cmap, len(bodyparts2plot))
    df_3d = pd.read_hdf(path, 'df_with_missing')
    plt.rcParams.update({'figure.max_open_warning': 0})

    vid_fname=os.path.splitext(path)[0]+'.mp4'
    new_clip = VideoProcessorCV(sname=vid_fname, fps=fps, codec='mp4v', sw=800, sh=800)

    # Start plotting for every frame
    for k in tqdm(range(len(df_3d))):
        frame = plot2D(k, bodyparts2plot, bodyparts2connect, df_3d, table_corners, tocchini, alphaValue, color, skeleton_color, view,
                       draw_skeleton, trailpoints, xlim, ylim, zlim)
        new_clip.save_frame(np.uint8(frame[:,:,0:3]))

    # Once all the frames are saved, then make a movie using ffmpeg.
    new_clip.close()
    return vid_fname


def plot2D(k, bodyparts2plot, bodyparts2connect, xyz_pts, table_corners, tocchini, alphaValue, color, skeleton_color,
           view, draw_skeleton, trailpoints, xlim, ylim, zlim):
    """
    Creates 2D gif for a selected number of frames
    """
    # Create the fig and define the axes
    fig = plt.figure(figsize=(8, 8))
    axes3 = fig.add_subplot(1,1,1, projection='3d')  # row 1, span all columns
    fig.tight_layout()

    # Clear plot and initialize the variables
    plt.cla()
    axes3.cla()

    # Get the scorer names from the dataframe
    scorer_3d = xyz_pts.columns.get_level_values(0)[0]

    # Set the x,y, and z limits for the 3d view
    numberFrames = len(xyz_pts[scorer_3d][bodyparts2plot[0]]['x'].values)
    df_x = np.empty((len(bodyparts2plot), numberFrames))
    df_y = np.empty((len(bodyparts2plot), numberFrames))
    df_z = np.empty((len(bodyparts2plot), numberFrames))
    for bpindex, bp in enumerate(bodyparts2plot):
        df_x[bpindex, :] = xyz_pts[scorer_3d][bp]['x'].values
        df_y[bpindex, :] = xyz_pts[scorer_3d][bp]['y'].values
        df_z[bpindex, :] = xyz_pts[scorer_3d][bp]['z'].values
    if xlim == [None, None]:
        axes3.set_xlim3d([np.nanmin(df_x), np.nanmax(df_x)])
    else:
        axes3.set_xlim3d(xlim)
    if ylim == [None, None]:
        axes3.set_ylim3d([np.nanmin(df_y), np.nanmax(df_y)])
    else:
        axes3.set_ylim3d(ylim)
    if zlim == [None, None]:
        axes3.set_zlim3d([np.nanmin(df_z), np.nanmax(df_z)])
    else:
        axes3.set_zlim3d(zlim)

    axes3.set_xticklabels([])
    axes3.set_yticklabels([])
    axes3.set_zticklabels([])
    axes3.xaxis.grid(False)
    axes3.view_init(view[0], view[1])
    axes3.set_xlabel('X', fontsize=10)
    axes3.set_ylabel('Y', fontsize=10)
    axes3.set_zlabel('Z', fontsize=10)

    axes3.scatter(0, 0, 0, color='k')
    for table_corner in table_corners:
        axes3.scatter(table_corner[0], table_corner[1], table_corner[2], color='k')
    for tocchino in tocchini:
        axes3.scatter(tocchino[0], tocchino[1], tocchino[2], color='k')
    xlines_3d=[table_corners[0][0][0], table_corners[1][0][0]]
    ylines_3d=[table_corners[0][1][0], table_corners[1][1][0]]
    zlines_3d=[table_corners[0][2][0], table_corners[1][2][0]]
    axes3.plot(xlines_3d, ylines_3d, zlines_3d, color='k')
    xlines_3d=[table_corners[1][0][0], table_corners[2][0][0]]
    ylines_3d=[table_corners[1][1][0], table_corners[2][1][0]]
    zlines_3d=[table_corners[1][2][0], table_corners[2][2][0]]
    axes3.plot(xlines_3d, ylines_3d, zlines_3d, color='k')
    xlines_3d = [table_corners[2][0][0], table_corners[3][0][0]]
    ylines_3d = [table_corners[2][1][0], table_corners[3][1][0]]
    zlines_3d = [table_corners[2][2][0], table_corners[3][2][0]]
    axes3.plot(xlines_3d, ylines_3d, zlines_3d, color='k')
    xlines_3d = [table_corners[3][0][0], table_corners[0][0][0]]
    ylines_3d = [table_corners[3][1][0], table_corners[0][1][0]]
    zlines_3d = [table_corners[3][2][0], table_corners[0][2][0]]
    axes3.plot(xlines_3d, ylines_3d, zlines_3d, color='k')

    # Plot the labels for each body part
    for bpindex, bp in enumerate(bodyparts2plot):
        coord=[xyz_pts.iloc[k][scorer_3d][bp]['x'], xyz_pts.iloc[k][scorer_3d][bp]['y'], xyz_pts.iloc[k][scorer_3d][bp]['z']]
        p = axes3.scatter(coord[0], coord[1], coord[2], c=color(bodyparts2plot.index(bp)))
        if trailpoints > 0:
            for hist_idx in range(k-1,max(-1,k-trailpoints),-1):
                coord=[xyz_pts.iloc[hist_idx][scorer_3d][bp]['x'], xyz_pts.iloc[hist_idx][scorer_3d][bp]['y'], xyz_pts.iloc[hist_idx][scorer_3d][bp]['z']]
                p = axes3.scatter(coord[0], coord[1], coord[2], c=color(bodyparts2plot.index(bp)), alpha=.5*hist_idx/k)

    # Connecting the bodyparts specified in the config file.3d file is created based on the likelihoods of cam1 and cam2. Using 3d file and check if the body part is nan then dont plot skeleton
    if draw_skeleton:
        xlines_3d = []
        ylines_3d = []
        zlines_3d = []
        for i in range(len(bodyparts2connect)):
            if not np.isnan(xyz_pts.iloc[k][scorer_3d][bodyparts2connect[i][0]]['x']) and not np.isnan(xyz_pts.iloc[k][scorer_3d][bodyparts2connect[i][1]]['x']):
                xlines_3d.append(xyz_pts.iloc[k][scorer_3d][bodyparts2connect[i][0]]['x'])
                ylines_3d.append(xyz_pts.iloc[k][scorer_3d][bodyparts2connect[i][0]]['y'])
                zlines_3d.append(xyz_pts.iloc[k][scorer_3d][bodyparts2connect[i][0]]['z'])
                xlines_3d.append(xyz_pts.iloc[k][scorer_3d][bodyparts2connect[i][1]]['x'])
                ylines_3d.append(xyz_pts.iloc[k][scorer_3d][bodyparts2connect[i][1]]['y'])
                zlines_3d.append(xyz_pts.iloc[k][scorer_3d][bodyparts2connect[i][1]]['z'])

        if len(xlines_3d):
            axes3.plot(xlines_3d, ylines_3d, zlines_3d, color=skeleton_color, alpha=alphaValue)


    # Saving the frames
    # output_folder = Path(os.path.join(path_h5_file, 'temp_' + file_name))
    # output_folder.mkdir(parents=True, exist_ok=True)
    # num_frames = int(np.ceil(np.log10(numberFrames)))
    # img_name = str(output_folder) + '/img' + str(k).zfill(num_frames) + '.png'
    # plt.savefig(img_name)
    # plt.close('all')
    # return (output_folder, num_frames)
    frame=fig2data(fig)
    fig.clf()
    plt.close()
    return frame


def fig2data(fig):
    """
    @brief Convert a Matplotlib figure to a 4D numpy array with RGBA channels and return it
    @param fig a matplotlib figure
    @return a numpy 3D array of RGBA values
    """
    # draw the renderer
    fig.canvas.draw()

    # Get the RGBA buffer from the figure
    w, h = fig.canvas.get_width_height()
    buf = np.fromstring(fig.canvas.tostring_rgb(), dtype=np.uint8).reshape(h,w,3)
    #buf.shape = (w, h, 4)

    # canvas.tostring_argb give pixmap in ARGB mode. Roll the ALPHA channel to have it in RGBA mode
    #buf = np.roll(buf, 3, axis=2)
    return buf


def locate(cam_names, likelihoods, camera_coords, pcutoff, projections):
    location=np.zeros((3,1))
    pairs_used=0
    for idx1 in range(len(cam_names)):
        for idx2 in range(idx1+1,len(cam_names)):
            if likelihoods[cam_names[idx1]]>pcutoff and likelihoods[cam_names[idx2]]>pcutoff:
                upoint1=camera_coords[cam_names[idx1]]
                upoint2=camera_coords[cam_names[idx2]]
                p1=projections[idx1]
                p2=projections[idx2]

                point_3d=cv2.triangulatePoints(p1, p2, upoint1, upoint2)

                result=point_3d[0:3]*(1/point_3d[3])
                location=location+result
                pairs_used=pairs_used+1
    if pairs_used>0:
        location=location/pairs_used
    return [location,pairs_used]

if __name__=='__main__':
    subject = sys.argv[1]
    date = sys.argv[2]
    process_videos(subject, date)