function exp_info=init_exp_info()

exp_info=[];
exp_info.event_types={'exp_place_right', 'exp_grasp_center', 'exp_place_left',...
    'monkey_handle_on', 'monkey_tool_right', 'monkey_tool_mid_right',...
    'monkey_tool_center', 'monkey_tool_mid_left', 'monkey_tool_left',...
    'trap_edge', 'trap_bottom', 'monkey_rake_handle',...
    'monkey_rake_blade', 'reward', 'error', 'exp_start_off',...
    'monkey_handle_off', 'laser_exp_start_right', 'laser_exp_start_left',...
    'laser_exp_start_center', 'go', 'laser_monkey_tool_center',...
    'trial_start', 'trial_stop'};

exp_info.array_names={'F1','F5hand','F5mouth','46v12r', '45a', 'F2'};
exp_info.ch_per_array=32;

exp_info.conditions={'visual_grasp_left','visual_grasp_right','motor_grasp_left',...
    'motor_grasp_center','motor_grasp_right','visual_pliers_left','visual_pliers_right',...
    'visual_rake_pull_left','visual_rake_pull_right','fixation','motor_rake_left',...
    'motor_rake_center','motor_rake_right','motor_rake_center_catch',''};

exp_info.base_data_dir='/data/tool_learning';
exp_info.base_output_dir='/data/tool_learning/output';