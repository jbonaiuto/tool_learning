import sys
from datetime import datetime
import glob
import json
import shutil
import subprocess

import numpy as np
import os
import cv2
from deeplabcut.utils import auxiliaryfunctions, auxiliaryfunctions_3d

from moviepy.video.VideoClip import ImageClip
from moviepy.video.compositing.concatenate import concatenate_videoclips
from moviepy.video.io.VideoFileClip import VideoFileClip
from skimage import img_as_ubyte, io
import matplotlib.pyplot as plt
import pandas as pd

from config import read_config
from video import select_crop_parameters
from video.video_processor import VideoProcessorCV

cfg = read_config()

"""
Copies videos to preprocessed_data directory and puts videos from different cameras in different folders
(based on CAMERA_SERIALS)
"""
def copy_and_rename_videos(subject, date):
    # Directory containing original videos
    orig_dir = os.path.join(cfg['video_dir'], subject, date)
    if not os.path.exists(orig_dir):
        os.mkdir(orig_dir)

    # Download videos from server
    cmd = 'rsync -avzhe ssh %s:/home/bonaiuto/tool_learning/video/%s/%s/*.avi %s/' % (cfg['data_server'], subject, date, orig_dir)
    #os.system(cmd)
    
    # Create directory for processed videos
    out_dir=os.path.join(cfg['preprocessed_data_dir'], subject, date,'video')
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)
    shutil.copy('/home/bonaiuto/Projects/tool_learning/src/python/video/default_config.json', os.path.join(out_dir, 'config.json'))

    for view in cfg['camera_views']:
        if not os.path.exists(os.path.join(out_dir, view)):
            os.mkdir(os.path.join(out_dir, view))
    
    for fname in os.listdir(os.path.join(orig_dir)):
        # Parse filename to get serial, timestamp, and trial number
        [base, ext] = os.path.splitext(fname)
        camera_serial=base.split('_')[0]
        timestamp = '_'.join(base.split('_')[1:3])
        trial=base.split('_')[3]

        # Figure out which view this video corresponds to and copy to appropriate folder (stripping serial from filename)
        for view,serial in cfg['camera_serials'].items():
            if camera_serial==serial:
                shutil.copy(os.path.join(orig_dir, fname),
                            os.path.join(os.path.join(out_dir, view), '%s_%s.avi' % (timestamp, trial)))


"""
Combines videos from different cameras into a single video
"""
def combine_videos(subject, date):

    # Create directory to put combined videos in
    base_video_path = os.path.join(cfg['preprocessed_data_dir'], subject, date, 'video')
    out_path=os.path.join(base_video_path,'combined')
    if not os.path.exists(out_path):
        os.mkdir(out_path)

    # Load trial info
    trial_info = pd.read_csv('%s/%s/%s/trial_info.csv' % (cfg['preprocessed_data_dir'], subject, date))

    for t_idx in range(len(trial_info.index)):

        # Get block, trial number, task, and condition
        block=trial_info.block[t_idx]
        task=trial_info.task[t_idx]
        condition=trial_info.condition[t_idx]
        trial_num=trial_info.trial[t_idx]

        # If there is a video corresponding to this trial
        if type(trial_info.video[t_idx])==str and len(trial_info.video[t_idx]):
            print(trial_info.video[t_idx])
            combine_video(base_video_path, {'front': trial_info.video[t_idx], 'side': trial_info.video[t_idx], 'top': trial_info.video[t_idx]},
                          out_path, '%d-%d_%s-%s.mp4' % (block, trial_num, task, condition))


def combine_video(base_video_path, fnames, out_path, out_fname):
    # Output video size
    out_size = [2040, 1084]
    frame_buffer = 10

    # Process videos
    front_video = VideoFileClip(os.path.join(base_video_path, 'front', fnames['front']))
    side_video = VideoFileClip(os.path.join(base_video_path, 'side', fnames['side']))
    top_video = VideoFileClip(os.path.join(base_video_path, 'top', fnames['top']))
    if '3d' in fnames:
        video_3d=VideoFileClip(os.path.join(base_video_path, fnames['3d']))

    fps = front_video.fps
    # Create new clip and write frames
    new_clip = VideoProcessorCV(
        sname=os.path.join(out_path, out_fname),
        fps=fps, codec='mp4v', sw=out_size[0], sh=out_size[1])

    n_frames_approx = int(np.ceil(front_video.duration * front_video.fps) + frame_buffer)
    n_frames = n_frames_approx
    front_video.reader.initialize()
    side_video.reader.initialize()
    top_video.reader.initialize()
    if '3d' in fnames:
        video_3d.reader.initialize()

    for index in range(n_frames_approx):
        front_image = img_as_ubyte(front_video.reader.read_frame())
        if index == int(n_frames_approx - frame_buffer * 2):
            last_front_image = front_image
        elif index > int(n_frames_approx - frame_buffer * 2):
            if (front_image == last_front_image).all():
                n_frames = index
                break

        side_image = img_as_ubyte(side_video.reader.read_frame())
        if index == int(n_frames_approx - frame_buffer * 2):
            last_side_image = side_image
        elif index > int(n_frames_approx - frame_buffer * 2):
            if (side_image == last_side_image).all():
                n_frames = index
                break

        top_image = img_as_ubyte(top_video.reader.read_frame())
        if index == int(n_frames_approx - frame_buffer * 2):
            last_top_image = top_image
        elif index > int(n_frames_approx - frame_buffer * 2):
            if (top_image == last_top_image).all():
                n_frames = index
                break

        if '3d' in fnames:
            image_3d = img_as_ubyte(video_3d.reader.read_frame())
            if index == int(n_frames_approx - frame_buffer * 2):
                last_3d_image = image_3d
            elif index > int(n_frames_approx - frame_buffer * 2):
                if (image_3d == last_3d_image).all():
                    n_frames = index
                    break

        # Resize frame
        front_factor = np.min([out_size[0] / 2.0 / front_image.shape[1], out_size[1] / 2.0 / front_image.shape[0]])
        front_image = cv2.resize(front_image, None, fx=front_factor, fy=front_factor)
        side_factor = np.min([out_size[0] / 2.0 / side_image.shape[1], out_size[1] / 2.0 / side_image.shape[0]])
        side_image = cv2.resize(side_image, None, fx=side_factor, fy=side_factor)
        top_factor = np.min([out_size[0] / 2.0 / top_image.shape[1], out_size[1] / 2.0 / top_image.shape[0]])
        top_image = cv2.resize(top_image, None, fx=top_factor, fy=top_factor)
        if '3d' in fnames:
            factor_3d = np.min([out_size[0] / 2.0 / image_3d.shape[1], out_size[1] / 2.0 / image_3d.shape[0]])
            image_3d = cv2.resize(image_3d, None, fx=factor_3d, fy=factor_3d)

        # Initialize new frame and add front image to it
        new_frame = np.zeros((out_size[1], out_size[0], 3))
        extra_x_space = out_size[0] / 2 - front_image.shape[1]
        extra_y_space = out_size[1] / 2 - front_image.shape[0]
        start_x=int(out_size[1] / 2 + extra_y_space / 2)
        end_x=int(out_size[1] / 2 + front_image.shape[0] + extra_y_space / 2)
        start_y=int(0 + extra_x_space / 2)
        end_y=int(front_image.shape[1] + extra_x_space / 2)
        new_frame[start_x:end_x,start_y:end_y, :] = front_image

        # Add side image to frame
        extra_x_space = out_size[0] / 2 - side_image.shape[1]
        extra_y_space = out_size[1] / 2 - side_image.shape[0]
        start_x=int(0 + extra_y_space / 2)
        end_x=int(side_image.shape[0] + extra_y_space / 2)
        start_y=int(out_size[0] / 2 + extra_x_space / 2)
        end_y=int(out_size[0] / 2 + side_image.shape[1] + extra_x_space / 2)
        new_frame[start_x:end_x,start_y:end_y,:] = side_image

        # Add top image to frame
        extra_x_space = out_size[0] / 2 - top_image.shape[1]
        extra_y_space = out_size[1] / 2 - top_image.shape[0]
        start_x=int(0 + extra_y_space / 2)
        end_x=int(top_image.shape[0] + extra_y_space / 2)
        start_y=int(0 + extra_x_space / 2)
        end_y=int(top_image.shape[1] + extra_x_space / 2)
        new_frame[start_x:end_x,start_y:end_y, :] = top_image

        if '3d' in fnames:
            extra_x_space = out_size[0] / 2 - image_3d.shape[1]
            extra_y_space = out_size[1] / 2 - image_3d.shape[0]
            start_x = int(out_size[1] / 2 + extra_y_space / 2)
            end_x = int(out_size[1] / 2 + image_3d.shape[0] + extra_y_space / 2)
            start_y = int(out_size[0] / 2 + extra_x_space / 2)
            end_y = int(out_size[0] / 2 + image_3d.shape[1] + extra_x_space / 2)
            new_frame[start_x:end_x, start_y:end_y, :] = image_3d


        new_clip.save_frame(np.uint8(new_frame))
    front_video.close()
    del front_video
    side_video.close()
    del side_video
    top_video.close()
    del top_video
    if '3d' in fnames:
        video_3d.close()
        del video_3d
    new_clip.close()


"""
Aligns videos based on blue LED onset times, crops videos, saves video info in json files
"""
def align_videos(subject, date):
    frame_buffer = 10

    base_video_path=os.path.join(cfg['preprocessed_data_dir'],subject, date,'video')
    with open(os.path.join(base_video_path,'config.json')) as json_file:
        vid_cfg=json.load(json_file)
    fnames=sorted(glob.glob(os.path.join(base_video_path, 'front', '%s*.avi' % date)))

    rois_checked={
        'front':False,
        'side':False,
        'top':False
    }
    crop_checked={
        'front':False,
        'side':False,
        'top':False
    }

    # For each file (filenames are same in each view directory)
    for fname in fnames:
        fname=os.path.split(fname)[-1]
        print('Processing %s' % fname)
        blue_onsets={}
        yellow_onsets={}
        blue_ts={}
        yellow_ts={}
        video_nframes={}

        # Whether or not to use LED for alignment
        led_based = True

        for view in cfg['camera_views']:
            video_path=os.path.join(base_video_path, view)
            clip = VideoFileClip(os.path.join(video_path, fname))
            n_frames_approx = int(np.ceil(clip.duration * clip.fps) + frame_buffer)
            n_frames = n_frames_approx
            clip.reader.initialize()

            # Initialize LED time series for this view
            blue_ts[view]=[]
            yellow_ts[view]=[]

            for index in range(n_frames_approx):
                image = img_as_ubyte(clip.reader.read_frame())

                # If not already set, show GUI to select blue LED ROI
                if not rois_checked[view]:
                    blue_led_roi_area=vid_cfg['blue_led_roi_areas'][view]
                    blue_cropped_img=image[blue_led_roi_area[2]:blue_led_roi_area[3],
                                     blue_led_roi_area[0]:blue_led_roi_area[1],:]
                    init_roi=None
                    if  view in vid_cfg['blue_led_rois'] and vid_cfg['blue_led_rois'][view] is not None:
                        init_roi=vid_cfg['blue_led_rois'][view]
                        init_roi[0] = init_roi[0] - blue_led_roi_area[0]
                        init_roi[1] = init_roi[1] - blue_led_roi_area[0]
                        init_roi[2] = init_roi[2] - blue_led_roi_area[2]
                        init_roi[3] = init_roi[3] - blue_led_roi_area[2]
                    vid_cfg['blue_led_rois'][view] = select_crop_parameters.show(blue_cropped_img, 'Select blue LED ROI', init_coords=init_roi)
                    vid_cfg['blue_led_rois'][view][0] = vid_cfg['blue_led_rois'][view][0] + blue_led_roi_area[0]
                    vid_cfg['blue_led_rois'][view][1] = vid_cfg['blue_led_rois'][view][1] + blue_led_roi_area[0]
                    vid_cfg['blue_led_rois'][view][2] = vid_cfg['blue_led_rois'][view][2] + blue_led_roi_area[2]
                    vid_cfg['blue_led_rois'][view][3] = vid_cfg['blue_led_rois'][view][3] + blue_led_roi_area[2]

                    yellow_led_roi_area = vid_cfg['yellow_led_roi_areas'][view]
                    yellow_cropped_img = image[yellow_led_roi_area[2]:yellow_led_roi_area[3],
                                       yellow_led_roi_area[0]:yellow_led_roi_area[1], :]
                    init_roi = None
                    if view in vid_cfg['yellow_led_rois'] and vid_cfg['yellow_led_rois'][view] is not None:
                        init_roi = vid_cfg['yellow_led_rois'][view]
                        init_roi[0] = init_roi[0] - yellow_led_roi_area[0]
                        init_roi[1] = init_roi[1] - yellow_led_roi_area[0]
                        init_roi[2] = init_roi[2] - yellow_led_roi_area[2]
                        init_roi[3] = init_roi[3] - yellow_led_roi_area[2]
                    vid_cfg['yellow_led_rois'][view] = select_crop_parameters.show(yellow_cropped_img, 'Select yellow LED ROI', init_coords=init_roi)
                    vid_cfg['yellow_led_rois'][view][0] = vid_cfg['yellow_led_rois'][view][0] + yellow_led_roi_area[0]
                    vid_cfg['yellow_led_rois'][view][1] = vid_cfg['yellow_led_rois'][view][1] + yellow_led_roi_area[0]
                    vid_cfg['yellow_led_rois'][view][2] = vid_cfg['yellow_led_rois'][view][2] + yellow_led_roi_area[2]
                    vid_cfg['yellow_led_rois'][view][3] = vid_cfg['yellow_led_rois'][view][3] + yellow_led_roi_area[2]

                    rois_checked[view]=True
                    
                if index == int(n_frames_approx - frame_buffer * 2):
                    last_image = image
                elif index > int(n_frames_approx - frame_buffer * 2):
                    if (image == last_image).all():
                        n_frames = index
                        break

                # Crop image around blue LED, get only blue channel
                blue_roi=vid_cfg['blue_led_rois'][view]
                blue_led_image = image[blue_roi[2]:blue_roi[3], blue_roi[0]:blue_roi[1], 2]
                # Add average of cropped image to blue LED timeseries
                blue_ts[view].append(np.mean(blue_led_image))

                # Crop image around yellow LED, average red and green channels
                yellow_roi=vid_cfg['yellow_led_rois'][view]
                yellow_led_image = np.mean(image[yellow_roi[2]:yellow_roi[3], yellow_roi[0]:yellow_roi[1], 0:1],axis=2)
                # Add average of cropped image to yellow LED timeseries
                yellow_ts[view].append(np.mean(yellow_led_image))

            blue_ts[view] = np.array(blue_ts[view])
            yellow_ts[view] = np.array(yellow_ts[view])

            # Normalize based on first 10 time steps
            if len(blue_ts[view])>10:
                blue_ts[view]=(blue_ts[view]-np.mean(blue_ts[view][0:10]))/np.mean(blue_ts[view][0:10])
            if len(yellow_ts[view])>10:
                yellow_ts[view]=(yellow_ts[view]-np.mean(yellow_ts[view][0:10]))/np.mean(yellow_ts[view][0:10])
            blue_ts[view]=blue_ts[view]/np.max(blue_ts[view])
            yellow_ts[view]=yellow_ts[view]/np.max(yellow_ts[view])

            # plt.figure()
            # plt.subplot(2,1,1)
            # plt.plot(video_blue_brightness)
            # plt.subplot(2, 1, 2)
            # plt.plot(video_yellow_brightness)
            # plt.show()

            # Get derivative of blue and yellow ts
            #blue_diff=np.diff(blue_ts[view])
            #yellow_diff=np.diff(yellow_ts[view])

            # Get peak blue and yellow LED change times
            #blue_peak=np.max(blue_diff)
            blue_peak = np.max(blue_ts[view])
            #yellow_peak=np.max(yellow_diff)
            yellow_peak = np.max(yellow_ts[view])

            # If none above 0.05, don't use LEDs for aligning
            #if blue_peak<.05 or yellow_peak<.05:
            if len(blue_ts[view])<10 or np.max(blue_ts[view][10:]) < .25 or np.max(yellow_ts[view])<.25:
                led_based=False
                print('Cant figure out LED onset - not using')
            # Otherwise, use the first time point after 25 time points where LED diff exceeds 0.05
            else:
                #blue_onsets[view] = np.where(blue_diff >= 0.05)[0][0]
                #np.where(blue_ts[view] >= 0.25)[0][0]
                blue_onsets[view] = 10 + np.where(blue_ts[view][10:] >= 0.25)[0][0]
                #yellow_onsets[view] = np.where(yellow_diff >= 0.05)[0][0]
                yellow_onsets[view] = np.where(yellow_ts[view] >= 0.25)[0][0]

            video_nframes[view]=n_frames

        # Use first view where blue LED exceeds threshold as reference to align to
        if len(blue_onsets.values())>0:
            min_blue_onset=min(blue_onsets.values())

        # if fname=='15-05-2019_10-34-15_11.avi':
        #     plt.figure()
        #     for view in cfg['camera_views']:
        #         plt.plot(blue_ts[view], label='%s: blue' % view)
        #         plt.plot(yellow_ts[view], label='%s: yellow' % view)
        #     plt.legend()
        #     plt.show()

        # Compute trial duration based on each view
        trial_durations={}
        for view in cfg['camera_views']:
            if view in blue_onsets and view in yellow_onsets:
                # Trial duration (in ms)
                trial_duration=(yellow_onsets[view]-blue_onsets[view])*1.0/clip.fps*1000.0
                # there is an 850ms delay before blue LED comes on
                if trial_duration>0:
                    trial_duration=trial_duration+850.0
                trial_durations[view]=trial_duration
                print('%s: %.2fms' % (view, trial_duration))
        #assert(len(trial_durations)>0 and all(x == trial_durations[0] for x in trial_durations))

        start_frames_to_cut={}
        n_frames_after_cutting = {}
        # Cut frames to align videos and crop
        for idx,view in enumerate(cfg['camera_views']):

            # using LED to align
            if led_based:
                start_frames_to_cut[view]=blue_onsets[view]-min_blue_onset
            # otherwise - use standard # of frames to crop (order of video triggering is top, side, front)
            if not led_based or start_frames_to_cut[view]>5:
                start_frames_to_cut[view] = 0
                if view=='front':
                    start_frames_to_cut[view]=2
                elif view=='side':
                    start_frames_to_cut[view]=1
            n_frames_after_cutting[view]=video_nframes[view]-start_frames_to_cut[view]
        new_nframes=min(n_frames_after_cutting.values())

        intrinsic_files = {}
        for view in cfg['camera_views']:
            dlc3d_cfg = os.path.join('/data/tool_learning/preprocessed_data/dlc_projects',
                                     'visual_grasp_3d-Jimmy-2019-08-19-3d', 'config.yaml')

            cfg_3d = auxiliaryfunctions.read_config(dlc3d_cfg)
            img_path, path_corners, path_camera_matrix, path_undistort = auxiliaryfunctions_3d.Foldernames3Dproject(
                cfg_3d)
            path_intrinsic_file = os.path.join(path_camera_matrix, '%s_intrinsic_params.pickle' % view)
            intrinsic_file = auxiliaryfunctions.read_pickle(path_intrinsic_file)
            intrinsic_files[view] = intrinsic_file[view]

        for idx, view in enumerate(cfg['camera_views']):
            camera_matrix = intrinsic_files[view]['mtx']
            distortion_coefficients = intrinsic_files[view]['dist']

            end_frames_to_cut=n_frames_after_cutting[view]-new_nframes
            print('cutting %d frames from beginning and %d frames from end of %s' % (start_frames_to_cut[view], end_frames_to_cut, view))

            # Cut frames from blue and yellow LED time series and onsets
            if end_frames_to_cut>0:
                blue_ts[view]=blue_ts[view][start_frames_to_cut[view]:-end_frames_to_cut]
                yellow_ts[view] = yellow_ts[view][start_frames_to_cut[view]:-end_frames_to_cut]
            else:
                blue_ts[view] = blue_ts[view][start_frames_to_cut[view]:]
                yellow_ts[view] = yellow_ts[view][start_frames_to_cut[view]:]
            if view in blue_onsets:
                blue_onsets[view]=blue_onsets[view]-start_frames_to_cut[view]
            if view in yellow_onsets:
                yellow_onsets[view]=yellow_onsets[view]-start_frames_to_cut[view]

            # Load video and cut frames from beginning
            video_path = os.path.join(base_video_path, view)
            clip = VideoFileClip(os.path.join(video_path, fname))

            # Crop limits based on view
            frames=[]
            n_frames_approx = int(np.ceil(clip.duration * clip.fps)+frame_buffer)
            for index in range(n_frames_approx):
                image = img_as_ubyte(clip.reader.read_frame())
                image = cv2.undistort(image, camera_matrix, distortion_coefficients)
                if index>=start_frames_to_cut[view]:
                    if not crop_checked[view]:
                        init_crop_lims = None
                        if view in vid_cfg['crop_limits'] and vid_cfg['crop_limits'][view] is not None:
                            init_crop_lims = vid_cfg['crop_limits'][view]
                        vid_cfg['crop_limits'][view] = select_crop_parameters.show(image, 'Select crop limits',
                                                                                   init_coords=init_crop_lims)
                        crop_checked[view]=True
                    # Crop image and save to video
                    crop_lims=vid_cfg['crop_limits'][view]
                    image=image[crop_lims[2]:crop_lims[3], crop_lims[0]:crop_lims[1], :]
                    frames.append(image)
                if len(frames)==new_nframes:
                    break

            clip.close()

            # Check that have the right number of frames
            assert(len(frames)==new_nframes)

            # Create new video clip (cropped and aligned)
            video_path = os.path.join(base_video_path, view)
            new_clip = VideoProcessorCV(sname=os.path.join(video_path, fname), fps=clip.fps, codec='mp4v',
                                        sw=crop_lims[1] - crop_lims[0], sh=crop_lims[3] - crop_lims[2])
            for frame in frames:
                new_clip.save_frame(np.uint8(frame))
            new_clip.close()

        # Make everything hashable
        for view in cfg['camera_views']:
            blue_ts[view]=blue_ts[view].tolist()
            yellow_ts[view] = yellow_ts[view].tolist()
            if view in blue_onsets:
                blue_onsets[view]=int(blue_onsets[view])
            if view in yellow_onsets:
                yellow_onsets[view]=int(yellow_onsets[view])
            if view in trial_durations:
                trial_durations[view]=float(trial_durations[view])

        # Save video info to JSON
        data = {
            'blue_roi': vid_cfg['blue_led_rois'],
            'yellow_roi': vid_cfg['yellow_led_rois'],
            'blue_ts': blue_ts,
            'yellow_ts': yellow_ts,
            'blue_onset': blue_onsets,
            'yellow_onset': yellow_onsets,
            'trial_duration': trial_durations,
            'fname': fname
        }
        [base, ext] = os.path.splitext(fname)
        with open(os.path.join(base_video_path, '%s.json' % base), 'w') as outfile:
            json.dump(data, outfile)

        print('')

    with open(os.path.join(base_video_path,'config.json'),'w') as outfile:
        json.dump(vid_cfg, outfile)

"""
Match videos to recorded trial data
"""
def match_video_trials(subject, date):
    # Read video information
    base_video_path = os.path.join(cfg['preprocessed_data_dir'], subject, date, 'video')
    fnames = sorted(glob.glob(os.path.join(base_video_path, 'front', '*.avi')))

    # Read video data
    videos=[]
    video_names=[]
    for fname in fnames:
        [pth,file] = os.path.split(fname)
        [base, ext] = os.path.splitext(file)

        datetime_parts=base.split('_')
        time_parts=datetime_parts[1].split('-')
        hour_str=time_parts[0]
        if int(hour_str)<9:
            hour_str=str(int(hour_str)+12)
        time_parts[0]=hour_str
        datetime_parts[1]='-'.join(time_parts)
        video_names.append('_'.join(datetime_parts))

        if os.path.exists(os.path.join(base_video_path, '%s.json' % base)):
            with open(os.path.join(base_video_path, '%s.json' % base)) as json_file:
                data=json.load(json_file)
                videos.append(data)

    sorted_idx=np.argsort(video_names)
    video_names = [video_names[idx] for idx in sorted_idx]
    videos = [videos[idx] for idx in sorted_idx]
    fnames = [fnames[idx] for idx in sorted_idx]
    # for i in range(6):
    #     fnames.insert(0,'')
    #     videos.insert(0,None)

    # Transfer trial info file
    local_date = datetime.strptime(date, '%d-%m-%Y')
    remote_date_str = datetime.strftime(local_date, '%d.%m.%y')
    cmd='rsync -avzhe ssh %s:/home/bonaiuto/tool_learning/preprocessed_data/%s/%s/trial_info.csv %s/%s/%s/trial_info.csv' % (cfg['preproc_data_server'], subject, remote_date_str, cfg['preprocessed_data_dir'], subject, date)
    os.system(cmd)
    trial_info=pd.read_csv('%s/%s/%s/trial_info.csv' % (cfg['preprocessed_data_dir'], subject, date))

    # For each intan file - the video filename and duration (if matched)
    trial_video = []
    trial_video_duration = []

    start_video_idx=0
    # Go through each intan file
    for idx in range(len(trial_info.intan_file)):
        intan_file=trial_info.intan_file[idx]
        intan_dur = trial_info.intan_duration[idx]
        (root,ext)=os.path.splitext(intan_file)
        root_parts=root.split('_')
        date_time_str='%s %s' % (root_parts[-2], root_parts[-1])
        date_time_obj=datetime.strptime(date_time_str, '%y%m%d %H%M%S')

        matched=False
        for video_idx in range(start_video_idx,len(videos)):
            video_name=video_names[video_idx]
            video_name_parts = video_name.split('_')
            video_date_time_str='%s %s' % (video_name_parts[0],video_name_parts[1])
            video_date_time_obj=datetime.strptime(video_date_time_str, '%d-%m-%Y %H-%M-%S')
            if (video_date_time_obj-date_time_obj).seconds>=321 and (video_date_time_obj-date_time_obj).seconds<=323:
                video_info = videos[video_idx]
                if video_info is not None:
                    video_durations = []
                    for view in cfg['camera_views']:
                        if view in video_info['trial_duration']:
                            video_durations.append(video_info['trial_duration'][view])
                    video_durations=np.array(video_durations)
                    if len(video_durations):
                        dur_delta = np.abs(video_durations - intan_dur)
                        video_duration=video_durations[np.where(dur_delta == np.nanmin(dur_delta))[0][0]]
                    else:
                        video_duration=float('NaN')
                else:
                    video_duration = float('NaN')
                # Add filename and duration to list
                [pth, file] = os.path.split(fnames[video_idx])
                trial_video.append(file)
                trial_video_duration.append(video_duration)
                matched=True
                start_video_idx=video_idx+1
                break
        if not matched:
            trial_video.append('')
            trial_video_duration.append(float('NaN'))

    # # If the number of videos = the number of intan files - just match corresponding videos/intan files
    # if len(fnames)==len(np.where(~np.isnan(trial_info.plexon_duration))[0]):
    #
    #     t_idx=0
    #     # Go through each intan file
    #     for idx in range(len(trial_info.intan_duration)):
    #
    #         # Find video view duration most closely matching intan duration
    #         intan_dur = trial_info.intan_duration[idx]
    #         if not np.isnan(trial_info.plexon_duration[idx]):
    #             video_info = videos[t_idx]
    #             if video_info is not None:
    #                 video_durations = []
    #                 for view in cfg['camera_views']:
    #                     if view in video_info['trial_duration']:
    #                         video_durations.append(video_info['trial_duration'][view])
    #                 video_durations=np.array(video_durations)
    #                 if len(video_durations):
    #                     dur_delta = np.abs(video_durations - intan_dur)
    #                     video_duration=video_durations[np.where(dur_delta == np.nanmin(dur_delta))[0][0]]
    #                 else:
    #                     video_duration=float('NaN')
    #             else:
    #                 video_duration = float('NaN')
    #             # Add filename and duration to list
    #             [pth, file] = os.path.split(fnames[t_idx])
    #             trial_video.append(file)
    #             trial_video_duration.append(video_duration)
    #             t_idx = t_idx + 1
    #
    #         else:
    #             trial_video.append('')
    #             trial_video_duration.append(float('NaN'))
    #
    #
    #
    # # Otherwise - need to match based on trial duration (error-prone! check results!)
    # else:
    #     print('********** ALERT: different number of videos and trials - check mapping *************')
    #     # Currently mapped trial
    #     current_rec_trial_num = -1
    #
    #     video_trials=[]
    #     video_trial_durations=[]
    #
    #     for video_idx in range(len(videos)):
    #         # Try to match to video trial
    #         matched = False
    #
    #         # Look if video duration from at least 2 views is within 200ms of intan duration
    #         video_info = videos[video_idx]
    #         video_durations = []
    #         for view in cfg['camera_views']:
    #             if view in video_info['trial_duration']:
    #                 video_durations.append(video_info['trial_duration'][view])
    #         video_durations = np.array(video_durations)
    #
    #         # Go through each intan file
    #         for t_idx in range(current_rec_trial_num + 1, len(trial_info.index)):
    #             # Get duration and task
    #             intan_dur = trial_info.intan_duration[t_idx]
    #
    #             if len(video_durations)>1:
    #                 dur_delta = np.abs(video_durations - intan_dur)
    #                 within_range=np.where(dur_delta<500)[0]
    #                 if current_rec_trial_num==-1:
    #                     within_range = np.where(dur_delta < 50)[0]
    #                 if len(within_range)>0:
    #                     matched = True
    #                     # Start search from here in video list for next intan file
    #                     current_rec_trial_num = t_idx
    #
    #                     # Add filename and duration to list
    #                     video_trials.append(t_idx)
    #                     video_trial_durations.append(video_durations[np.where(dur_delta==np.nanmin(dur_delta))[0][0]])
    #                     break
    #             else:
    #                 matched = True
    #                 # Start search from here in video list for next intan file
    #                 current_rec_trial_num = t_idx
    #
    #                 # Add filename and duration to list
    #                 video_trials.append(t_idx)
    #                 if len(video_durations)==1:
    #                     video_trial_durations.append(video_durations[0])
    #                 else:
    #                     video_trial_durations.append(float('NaN'))
    #                 break
    #
    #         # Add to trial info even if not matched
    #         if not matched:
    #             video_trials.append(float('NaN'))
    #             video_trial_durations.append(float('NaN'))
    #
    #     video_trials=np.array(video_trials)
    #
    #     trial_video=[]
    #     trial_video_duration=[]
    #     for t_idx in range(len(trial_info.index)):
    #         if len(np.where(video_trials==t_idx)[0]):
    #             vid_idx=np.where(video_trials==t_idx)[0][0]
    #             [pth, file] = os.path.split(fnames[vid_idx])
    #             trial_video.append(file)
    #             trial_video_duration.append(video_trial_durations[vid_idx])
    #         else:
    #             trial_video.append('')
    #             trial_video_duration.append(float('NaN'))


    # Add video and video duration columns to trial info
    trial_info['video'] = trial_video
    trial_info['video_duration']=trial_video_duration

    # Save and transfer trial info back
    trial_info.to_csv('%s/%s/%s/trial_info.csv' % (cfg['preprocessed_data_dir'], subject, date), index=False)
    cmd = 'rsync -avzhe ssh %s/%s/%s/trial_info.csv %s:/home/bonaiuto/tool_learning/preprocessed_data/%s/%s/trial_info.csv' % (cfg['preprocessed_data_dir'], subject, date, cfg['preproc_data_server'], subject, remote_date_str)
    os.system(cmd)


if __name__=='__main__':
    subject = sys.argv[1]
    date = sys.argv[2]
    copy_and_rename_videos(subject,date)
    align_videos(subject, date)
    match_video_trials(subject,date)
    combine_videos(subject,date)
