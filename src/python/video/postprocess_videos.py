import glob
import json
import subprocess

import numpy as np
import os
import cv2

from moviepy.video.VideoClip import ImageClip
from moviepy.video.compositing.concatenate import concatenate_videoclips
from moviepy.video.io.VideoFileClip import VideoFileClip
from skimage import img_as_ubyte, io
import matplotlib.pyplot as plt

CAMERA_VIEWS=['front', 'side', 'top']
CAMERA_SERIALS={'front':    '22508274',
                'side':     '22524011',
                'top':      '22524012'}
BLUE_LED_ROIS={'front': [1845, 1862, 972, 996],
               'side':  [579,603,929,956],#[579,593,929,949],#[589,603,934,953],
               'top':   [411,467,20,37]}#[453,467,24,37]}
YELLOW_LED_ROIS={'front':   [1825, 1845, 972, 996],
                'side':     [583,604,920,938],#[583,595,920,933],#[592,604,922,933],
                 'top':     [425,482,22,37]}#[468,482,23,37]}
CROP_LIMITS={'front':   [540, 1900, 0, 1084],
             'side':    [570, 2040, 280, 1050],
             'top':     [350, 1490, 0, 1084]}


def combine_videos(video_path, output_path, timestamp, trial_num):

    out_size=[2040, 1084]
    frame_buffer = 10
    clips=[]

    front_video=VideoFileClip(os.path.join(video_path, CAMERA_SERIALS['front'], '%s_%s_%d.mp4' % (CAMERA_SERIALS['front'], timestamp, trial_num)))
    side_video = VideoFileClip(os.path.join(video_path, CAMERA_SERIALS['side'], '%s_%s_%d.mp4' % (CAMERA_SERIALS['side'], timestamp, trial_num)))
    top_video = VideoFileClip(os.path.join(video_path, CAMERA_SERIALS['top'], '%s_%s_%d.mp4' % (CAMERA_SERIALS['top'], timestamp, trial_num)))

    n_frames_approx = int(np.ceil(front_video.duration * front_video.fps) + frame_buffer)
    n_frames = n_frames_approx

    front_video.reader.initialize()
    side_video.reader.initialize()
    top_video.reader.initialize()

    for index in range(n_frames_approx):
        front_image = img_as_ubyte(front_video.reader.read_frame())
        side_image = img_as_ubyte(side_video.reader.read_frame())
        top_image = img_as_ubyte(top_video.reader.read_frame())

        if index == int(n_frames_approx - frame_buffer * 2):
            last_front_image = front_image
        elif index > int(n_frames_approx - frame_buffer * 2):
            if (front_image == last_front_image).all():
                n_frames = index
                break

        if index == int(n_frames_approx - frame_buffer * 2):
            last_side_image = side_image
        elif index > int(n_frames_approx - frame_buffer * 2):
            if (side_image == last_side_image).all():
                n_frames = index
                break

        if index == int(n_frames_approx - frame_buffer * 2):
            last_top_image = top_image
        elif index > int(n_frames_approx - frame_buffer * 2):
            if (top_image == last_top_image).all():
                n_frames = index
                break

        new_frame = np.zeros((out_size[1], out_size[0], 3))

        # Resize
        top_factor=np.min([out_size[0]/2.0/top_image.shape[1], out_size[1]/2.0/top_image.shape[0]])
        top_image=cv2.resize(top_image, None, fx=top_factor, fy=top_factor)

        front_factor = np.min([out_size[0] / 2.0 / front_image.shape[1], out_size[1] / 2.0 / front_image.shape[0]])
        front_image = cv2.resize(front_image, None, fx=front_factor, fy=front_factor)

        side_factor = np.min([out_size[0] / 2.0 / side_image.shape[1], out_size[1] / 2.0 / side_image.shape[0]])
        side_image = cv2.resize(side_image, None, fx=side_factor, fy=side_factor)

        extra_x_space=out_size[0]/2-top_image.shape[1]
        extra_y_space=out_size[1]/2-top_image.shape[0]
        new_frame[0+extra_y_space/2:top_image.shape[0]+extra_y_space/2,0+extra_x_space/2:top_image.shape[1]+extra_x_space/2,:]=top_image

        extra_x_space = out_size[0] / 2 - front_image.shape[1]
        extra_y_space = out_size[1] / 2 - front_image.shape[0]
        new_frame[out_size[1]/2+extra_y_space/2:out_size[1]/2+front_image.shape[0]+extra_y_space/2,0+extra_x_space/2:front_image.shape[1]+extra_x_space/2,:]=front_image

        extra_x_space = out_size[0] / 2 - side_image.shape[1]
        extra_y_space = out_size[1] / 2 - side_image.shape[0]
        new_frame[0+extra_y_space/2:side_image.shape[0]+extra_y_space/2,out_size[0]/2+extra_x_space/2:out_size[0]/2+side_image.shape[1]+extra_x_space/2,:]=side_image

        clips.append(ImageClip(new_frame).set_duration(1.0/front_video.fps))

    new_clip=concatenate_videoclips(clips, method='chain')

    nframes=len(clips)
    nframes_digits = int(np.ceil(np.log10(nframes)))
    fps = front_video.fps

    new_clip.write_images_sequence(os.path.join(output_path,'frame%04d.png'),fps=fps)

    new_clip.close()
    front_video.close()
    top_video.close()
    side_video.close()

    subprocess.call(['ffmpeg', '-framerate', str(fps), '-i', os.path.join(video_path, 'frame%04d.png'),
                     '-r', str(fps), os.path.join(output_path, '%s_%d.mp4' % (timestamp, trial_num))])
    frame_imgs=glob.glob(os.path.join(video_path, 'frame*.png'))
    for frame_img in frame_imgs:
        try:
            os.remove(frame_img)
        except:
            pass


def align_videos(video_path, output_path, timestamp, trial_num, plot_led_ts=False):
    frame_buffer = 10
    led_based = False

    blue_led_ts=[]
    yellow_led_ts=[]
    blue_onsets=[]
    yellow_onsets=[]

    for view in CAMERA_VIEWS:
        clip = VideoFileClip(os.path.join(video_path, CAMERA_SERIALS[view], '%s_%s_%d.avi' % (CAMERA_SERIALS[view], timestamp, trial_num)))
        n_frames_approx = int(np.ceil(clip.duration * clip.fps) + frame_buffer)
        n_frames = n_frames_approx
        clip.reader.initialize()

        blue_led_brightness=[]
        yellow_led_brightness=[]
        blue_roi = BLUE_LED_ROIS[view]
        yellow_roi=YELLOW_LED_ROIS[view]

        for index in range(n_frames_approx):
            image = img_as_ubyte(clip.reader.read_frame())

            if index == int(n_frames_approx - frame_buffer * 2):
                last_image = image
            elif index > int(n_frames_approx - frame_buffer * 2):
                if (image == last_image).all():
                    n_frames = index
                    break

            #io.imsave(os.path.join(output_path,'img'+str(index)+'.png'),image)

            blue_led_image = image[blue_roi[2]:blue_roi[3], blue_roi[0]:blue_roi[1], 2]
            # blue_led_image_gray=np.mean(blue_led_image,axis=2)
            blue_led_image_gray = blue_led_image
            blue_led_brightness.append(np.mean(blue_led_image_gray))

            yellow_led_image = image[yellow_roi[2]:yellow_roi[3], yellow_roi[0]:yellow_roi[1], 0:1]
            yellow_led_image_gray = np.mean(yellow_led_image, axis=2)
            yellow_led_brightness.append(np.mean(yellow_led_image_gray))

        blue_led_brightness=np.array(blue_led_brightness)
        yellow_led_brightness=np.array(yellow_led_brightness)
        blue_led_ts.append(blue_led_brightness)
        yellow_led_ts.append(yellow_led_brightness)

        if len(blue_led_brightness)>10:
            blue_led_brightness=(blue_led_brightness-np.mean(blue_led_brightness[0:10]))/np.mean(blue_led_brightness[0:10])
        if len(yellow_led_brightness)>10:
            yellow_led_brightness=(yellow_led_brightness-np.mean(yellow_led_brightness[0:10]))/np.mean(yellow_led_brightness[0:10])

        blue_diff=np.diff(blue_led_brightness)
        yellow_diff=np.diff(yellow_led_brightness)

        if plot_led_ts:
            plt.figure()
            plt.plot(range(n_frames), blue_led_brightness, label='blue')
            plt.plot(range(n_frames), yellow_led_brightness, label='yellow')
            plt.legend()
            plt.show()

        blue_peak=np.max(blue_diff)
        yellow_peak=np.max(yellow_diff)
        blue_onsets.append(np.where(blue_diff==blue_peak)[0][0])
        yellow_onsets.append(np.where(yellow_diff==yellow_peak)[0][0])

        if blue_peak<.1 or yellow_peak<.1:
            led_based=False
            print('Cant figure out LED onset - not using')

    min_blue_onset=min(blue_onsets)
    for idx,view in enumerate(CAMERA_VIEWS):
        if led_based:
            frames_to_cut=blue_onsets[idx]-min_blue_onset
        else:
            if view=='front':
                frames_to_cut=2
            elif view=='side':
                frames_to_cut=1
            elif view=='top':
                frames_to_cut=0
        print('cutting %d frames from beginning of %s' % (frames_to_cut,view))
        clip = VideoFileClip(os.path.join(video_path, CAMERA_SERIALS[view], '%s_%s_%d.avi' % (CAMERA_SERIALS[view], timestamp, trial_num)))
        if not os.path.exists(os.path.join(output_path, CAMERA_SERIALS[view])):
            os.mkdir(os.path.join(output_path, CAMERA_SERIALS[view]))
        clip=clip.subclip(1.0/clip.fps*frames_to_cut)

        n_frames_approx = int(np.ceil(clip.duration * clip.fps) + frame_buffer)
        n_frames = n_frames_approx
        clips = []

        for index in range(n_frames_approx):
            image = img_as_ubyte(clip.reader.read_frame())

            if index == int(n_frames_approx - frame_buffer * 2):
                last_image = image
            elif index > int(n_frames_approx - frame_buffer * 2):
                if (image == last_image).all():
                    n_frames = index
                    break

            crop_lims=CROP_LIMITS[view]
            image=image[crop_lims[2]:crop_lims[3], crop_lims[0]:crop_lims[1], :]
            clips.append(ImageClip(image).set_duration(1.0 / clip.fps))

        new_clip = concatenate_videoclips(clips, method='chain')

        new_clip.write_videofile(os.path.join(output_path, CAMERA_SERIALS[view], '%s_%s_%d.mp4' % (CAMERA_SERIALS[view], timestamp, trial_num)), fps=clip.fps)
        data={
            'view': view,
            'serial': CAMERA_SERIALS[view],
            'blue_led_onset': blue_onsets[idx]-frames_to_cut,
            'yellow_led_onset': yellow_onsets[idx]-frames_to_cut,
        }
        with open(os.path.join(output_path, CAMERA_SERIALS[view], '%s_%s_%d.json' % (CAMERA_SERIALS[view], timestamp, trial_num)), 'w') as outfile:
            json.dump(data, outfile)

    print('')


if __name__=='__main__':
    tasks=['bloopers','motor_grasp','motor_rake','visual_grasp','visual_pliers','visual_rake']
    base_input_dir='/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example'
    base_output_dir='/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example/output'
    for task in tasks:
        task_input_dir=os.path.join(base_input_dir,task)
        task_output_dir=os.path.join(base_output_dir,task)
        for fname in os.listdir(os.path.join(task_input_dir,'22508274')):
            [base,ext]=os.path.splitext(fname)
            timestamp_trial='_'.join(base.split('_')[1:])
            if not os.path.exists(os.path.join(task_output_dir,'%s.mp4' % timestamp_trial)):
                timestamp='_'.join(timestamp_trial.split('_')[0:2])
                trial=int(timestamp_trial.split('_')[-1])
                align_videos(task_input_dir, task_output_dir, timestamp, trial)
                combine_videos(task_output_dir, task_output_dir, timestamp, trial)

    # align_videos('/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example/rake',
    #              '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example/output/rake',
    #              '28-03-2019_10-44-49', 2)
    # combine_videos('/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example/output/rake',
    #                '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example/output/rake',
    #                '28-03-2019_10-44-49', 2)