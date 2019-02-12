import os
from glob import glob

import numpy as np
from moviepy.video.io.VideoFileClip import VideoFileClip
from skimage import img_as_ubyte, io
import matplotlib.pyplot as plt

def test_leds(folder, prefix, blue_roi, yellow_roi):
    frame_buffer=10

    files=glob(os.path.join(folder,'%s*.avi' % prefix))
    blue_led_brightness={}
    yellow_led_brightness={}
    vid_frames={}

    for file in files:
        clip=VideoFileClip(file)

        # filefolder=os.path.join(folder,os.path.splitext(file)[0])
        # os.mkdir(filefolder)
        n_frames_approx=int(np.ceil(clip.duration*clip.fps)+frame_buffer)
        n_frames=n_frames_approx
        clip.reader.initialize()

        blue_led_brightness[file] = []
        yellow_led_brightness[file]=[]

        for index in range(n_frames_approx):
            image=img_as_ubyte(clip.reader.read_frame())

            if index==int(n_frames_approx-frame_buffer*2):
                last_image=image
            elif index>int(n_frames_approx-frame_buffer*2):
                if(image==last_image).all():
                    n_frames=index
                    break

            # io.imsave(os.path.join(filefolder,'img'+str(index)+'.png'),image)

            blue_led_image = image[blue_roi[2]:blue_roi[3], blue_roi[0]:blue_roi[1],2]
            #blue_led_image_gray=np.mean(blue_led_image,axis=2)
            blue_led_image_gray =blue_led_image
            blue_led_brightness[file].append(np.mean(blue_led_image_gray))

            yellow_led_image = image[yellow_roi[2]:yellow_roi[3], yellow_roi[0]:yellow_roi[1], 0:1]
            yellow_led_image_gray = np.mean(yellow_led_image, axis=2)
            yellow_led_brightness[file].append(np.mean(yellow_led_image_gray))

        vid_frames[file]=n_frames

    plt.figure()
    for file in files:
        plt.plot(range(vid_frames[file]),blue_led_brightness[file],label=file)
    #plt.legend()

    plt.figure()
    for file in files:
        plt.plot(range(vid_frames[file]),yellow_led_brightness[file],label=file)
    #plt.legend()
    plt.show()


if __name__=='__main__':
    # test_leds('/home/bonaiuto/Projects/trigger_record/data/18-10-2018',['22508274_18-10-2018_12-56-10_4.avi',
    #                                                                     '22508274_18-10-2018_12-56-24_5.avi',
    #                                                                     '22508274_18-10-2018_12-56-38_6.avi'],
    #           [1734,1753,867,891],
    #           [1713,1733,862,889])

    # test_leds('/home/bonaiuto/Projects/trigger_record/data/18-10-2018', ['22524011_18-10-2018_12-56-10_4.avi',
    #                                                                      '22524011_18-10-2018_12-56-24_5.avi',
    #                                                                      '22524011_18-10-2018_12-56-38_6.avi'],
    #           [496,510,916,935],
    #           [503,512,902,916])

    # test_leds('/home/bonaiuto/Projects/trigger_record/data/18-10-2018', ['22524012_18-10-2018_12-56-10_4.avi',
    #                                                                      '22524012_18-10-2018_12-56-24_5.avi',
    #                                                                      '22524012_18-10-2018_12-56-38_6.avi'],
    #           [310,327,32,45],
    #           [327,343,36,49])

    test_leds('/home/bonaiuto/Projects/tool_learning/video/test/07-12-2018', '22508274', [1837, 1856, 977, 1000],
              [1816, 1836, 977, 1000])