function exp_info=init_exp_info()

exp_info=[];
exp_info.event_types={'exp_place_right', 'exp_grasp_center', 'exp_place_left',...
    'monkey_handle_on', 'monkey_tool_right', 'monkey_tool_mid_right',...
    'monkey_tool_center', 'monkey_tool_mid_left', 'monkey_tool_left',...
    'trap_edge', 'trap_bottom', 'monkey_rake_handle',...
    'monkey_rake_blade', 'reward', 'error', 'exp_start_off',...
    'monkey_handle_off', 'laser_exp_start_right', 'laser_exp_start_left',...
    'laser_exp_start_center', 'go', 'laser_monkey_tool_center',...
    'trial_start', 'trial_stop', 'tool_start_off'};

exp_info.array_names={'F1','F5hand','F5mouth','46v-12r', '45a', 'F2'};
exp_info.ch_per_array=32;

exp_info.conditions={'visual_grasp_left','visual_grasp_right','motor_grasp_left',...
    'motor_grasp_center','motor_grasp_right','visual_pliers_left','visual_pliers_right',...
    'visual_rake_pull_left','visual_rake_pull_right','fixation','motor_rake_left',...
    'motor_rake_center','motor_rake_right','motor_rake_center_catch','',...
    'motor_rake_food_left','motor_rake_food_center','motor_rake_food_right',...
    'visual_rake_push_left','visual_rake_push_right','visual_stick_left','visual_stick_right'};

exp_info.base_data_dir='/data/tool_learning';
exp_info.base_output_dir='C:\Users\jbonaiuto\Projects\tool_learning\output';

% Position of the monkey's eye
exp_info.eye_pos=[4.1 23 -13.1];
% Position of the eyetracker
exp_info.eyetracker_pos=[4.1 29.5 138.1];
% Coordinates of the table corners
exp_info.table_corner_1=[-32.25 0 60.2];
exp_info.table_corner_2=[32.25 0 60.2];
exp_info.table_corner_3=[32.25 0 2];
exp_info.table_corner_4=[-32.25 0 2];
% Laser coordinates
exp_info.monkey_tool_right_laser_pos=exp_info.table_corner_4+[49.5 0 13.8];
exp_info.monkey_tool_left_laser_pos=exp_info.table_corner_4+[15.25 0 14.2];
exp_info.laser_exp_start_right_laser_pos=exp_info.table_corner_4+[60.3 0 46];
exp_info.laser_exp_start_left_laser_pos=exp_info.table_corner_4+[5.5 0 46];
exp_info.laser_exp_grasp_center_laser_pos=exp_info.table_corner_4+[32.6 0 47.2];
% Tocchini
exp_info.exp_start_platform_left=(exp_info.table_corner_4+[5 0 48.1]);
exp_info.exp_start_platform_right=(exp_info.table_corner_4+[60 0 48.1]);
exp_info.exp_place_left=(exp_info.table_corner_4+[24.5 0 48.1]);
exp_info.exp_place_right=(exp_info.table_corner_4+[40.5 0 48.1]);
exp_info.exp_grasp_center=(exp_info.table_corner_4+[32.5 0 48.1]);
exp_info.monkey_handle=[0 0 0];
exp_info.monkey_tool_right=(exp_info.table_corner_4+[49.3 0 12.4]);
exp_info.monkey_tool_mid_right=(exp_info.table_corner_4+[41.3 0 18]);
exp_info.monkey_tool_center=(exp_info.table_corner_4+[32.5 0 20.5]);
exp_info.monkey_tool_mid_left=(exp_info.table_corner_4+[23.2 0 18]);
exp_info.monkey_tool_left=(exp_info.table_corner_4+[15.5 0 12.4]);




