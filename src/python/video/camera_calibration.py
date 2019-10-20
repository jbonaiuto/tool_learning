import cv2
import os
import re

from deeplabcut.utils import auxiliaryfunctions, pickle, auxiliaryfunctions_3d

import deeplabcut
import yaml
import numpy as np

cameras=['front','side','top']
camera_pairs=[['front','side'],['front','top'],['side','top']]

def opencv_matrix(loader, node):
    mapping=loader.construct_mapping(node, deep=True)
    mat=np.array(mapping['data'])
    mat.resize(mapping['rows'],mapping['cols'])
    return mat
yaml.add_constructor(u"tag:yaml.org,2002:opencv-matrix", opencv_matrix)

def readYAMLFile(filename):
    ret={}
    skip_lines=1
    with open(filename) as fin:
        for i in range(skip_lines):
            fin.readline()
        yamlFileOut=fin.read()
        myRe=re.compile(r":([^ ])")
        yamlFileOut=myRe.sub(r': \1', yamlFileOut)
        ret=yaml.load(yamlFileOut)
    return ret

def convert_doveeye_to_dlc(config, doveeye_calib_file):
    cfg_3d = auxiliaryfunctions.read_config(config)
    img_path, path_corners, path_camera_matrix, path_undistort = auxiliaryfunctions_3d.Foldernames3Dproject(cfg_3d)
    cam_names = cfg_3d['camera_names']

    dist_pickle = {}
    stereo_params = {}
    for cam in cam_names:
        dist_pickle.setdefault(cam, [])

    doveye_calib=readYAMLFile(doveeye_calib_file)
    for cam in cam_names:
        cam_idx=cameras.index(cam)
        # Save the camera calibration result for later use (we won't use rvecs / tvecs)
        dist_pickle[cam] = {'mtx': doveye_calib['C'][cam_idx], 'dist': doveye_calib['D'][cam_idx], 'objpoints': [], 'imgpoints': []}
        pickle.dump(dist_pickle, open(os.path.join(path_camera_matrix, cam + '_intrinsic_params.pickle'), "wb"))

    for i in range(len(cam_names)):
        cam1_idx=cameras.index(cam_names[i])
        for j in range(i + 1, len(cam_names)):
            cam2_idx=cameras.index(cam_names[j])
            pair = [cam_names[i], cam_names[j]]
            pair_idx=-1
            for potential_pair_idx,potential_pair in enumerate(camera_pairs):
                if (potential_pair[0]==cam_names[i] and potential_pair[1]==cam_names[j]) or (potential_pair[0]==cam_names[j] and potential_pair[1]==cam_names[i]):
                    pair_idx=potential_pair_idx
                    break

            # Stereo Rectification
            rectify_scale = 0.4  # Free scaling parameter check this https://docs.opencv.org/2.4/modules/calib3d/doc/camera_calibration_and_3d_reconstruction.html#fisheye-stereorectify
            R1, R2, P1, P2, Q, roi1, roi2 = cv2.stereoRectify(doveye_calib['C'][cam1_idx], doveye_calib['D'][cam2_idx],
                                                              doveye_calib['C'][cam2_idx], doveye_calib['D'][cam1_idx],
                                                              (1086, 2040),
                                                              doveye_calib['R'][pair_idx],
                                                              doveye_calib['T'][pair_idx],
                                                              alpha=rectify_scale)

            stereo_params[pair[0] + '-' + pair[1]] = {"cameraMatrix1": doveye_calib['C'][cam1_idx],
                                                      "cameraMatrix2": doveye_calib['C'][cam2_idx],
                                                      "distCoeffs1": doveye_calib['D'][cam1_idx],
                                                      "distCoeffs2": doveye_calib['D'][cam2_idx],
                                                      "R": doveye_calib['R'][pair_idx],
                                                      "T": doveye_calib['T'][pair_idx],
                                                      "E": [],
                                                      "F": doveye_calib['F'][pair_idx],
                                                      "R1": R1,
                                                      "R2": R2,
                                                      "P1": P1,
                                                      "P2": P2,
                                                      "roi1": roi1,
                                                      "roi2": roi2,
                                                      "Q": Q,
                                                      "image_shape": [(1086,2040),(1086,2040)]}

    print('Saving the stereo parameters for every pair of cameras as a pickle file in %s' % str(
        os.path.join(path_camera_matrix)))

    auxiliaryfunctions.write_pickle(os.path.join(path_camera_matrix, 'stereo_params.pickle'), stereo_params)
    print("Camera calibration done! Use the function ``check_undistortion`` to check the check the calibration")

    pass

if __name__=='__main__':
    cfg='/home/bonaiuto/Projects/tool_learning/preprocessed_data/dlc_projects/motor_grasp_3d-Jimmy-2019-08-13-3d/config.yaml'

    #convert_doveeye_to_dlc(cfg, '/home/bonaiuto/Projects/tool_learning/data/video/calibrated_25.10.18.yaml')

    #deeplabcut.calibrate_cameras(cfg,cbrow=8,cbcol=6,calibrate=False,alpha=0.9)
    #deeplabcut.calibrate_cameras(cfg, cbrow=8, cbcol=6, calibrate=True, alpha=0.9)

    deeplabcut.check_undistortion(cfg)