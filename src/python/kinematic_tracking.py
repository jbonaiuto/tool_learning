import deeplabcut

config_path=deeplabcut.create_new_project('monkey_grasp_front','Jimmy',
                                          ['/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/front/22508274_19-09-2018_03-38-12_2.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/front/22508274_19-09-2018_03-38-49_3.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/front/22508274_19-09-2018_03-40-19_6.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/front/22508274_19-09-2018_03-41-29_7.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/front/22508274_19-09-2018_03-43-24_8.avi'],
                                          working_directory='/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/kinematics_tracking',
                                          copy_videos=False)

# config_path='/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/kinematics_tracking/monkey_grasp_front-Jimmy-2019-01-05/config.yaml'

deeplabcut.extract_frames(config_path,'automatic','kmeans', crop=True, checkcropping=True)

deeplabcut.label_frames(config_path, Screens=1)

deeplabcut.check_labels(config_path)

deeplabcut.create_training_dataset(config_path,num_shuffles=1)

deeplabcut.train_network(config_path)


config_path=deeplabcut.create_new_project('monkey_grasp_side','Jimmy',
                                          ['/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/side/22524011_19-09-2018_03-38-12_2.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/side/22524011_19-09-2018_03-38-49_3.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/side/22524011_19-09-2018_03-40-19_6.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/side/22524011_19-09-2018_03-41-29_7.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/side/22524011_19-09-2018_03-43-24_8.avi'],
                                          working_directory='/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/kinematics_tracking',
                                          copy_videos=False)

config_path='/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/kinematics_tracking/monkey_grasp_side-Jimmy-2019-01-27/config.yaml'

deeplabcut.extract_frames(config_path,'automatic','kmeans', crop=True, checkcropping=True)

deeplabcut.label_frames(config_path, Screens=1)

config_path=deeplabcut.create_new_project('monkey_grasp_top','Jimmy',
                                          ['/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/top/22524012_19-09-2018_03-38-12_2.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/top/22524012_19-09-2018_03-38-49_3.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/top/22524012_19-09-2018_03-40-19_6.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/top/22524012_19-09-2018_03-41-29_7.avi',
                                           '/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/videos/top/22524012_19-09-2018_03-43-24_8.avi'],
                                          working_directory='/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/kinematics_tracking',
                                          copy_videos=False)

deeplabcut.extract_frames(config_path,'automatic','kmeans', crop=True, checkcropping=True)