import deeplabcut
import os

def create_dlc_project(name, coder, videos, working_directory):
    config_path=deeplabcut.create_new_project(name, coder, videos, working_directory, copy_videos=False)
    return config_path

def extract_frames(config_path):
    deeplabcut.extract_frames(config_path,'automatic','kmeans', crop=True, opencv=False)


def label_frames(config_path):
    deeplabcut.label_frames(config_path)

if __name__=='__main__':
    # create_dlc_project('motor_grasp_front', 'Jimmy',
    #                    ['/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example/motor_grasp/22508274/22508274_07-01-2019_12-03-57_11.avi',
    #                     '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example/motor_grasp/22508274/22508274_07-01-2019_12-05-09_20.avi',
    #                     '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example/motor_grasp/22508274/22508274_07-01-2019_12-05-28_22.avi',
    #                     '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/example/motor_grasp/22508274/22508274_27-02-2019_11-34-08_133.avi'],
    #                    '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/kinematics_tracking')

    config_path = os.path.join('/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/kinematics_tracking/motor_grasp_front-Jimmy-2019-05-18/config.yaml')

    #extract_frames(config_path)
    label_frames(config_path)

