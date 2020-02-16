function plot_eyedata(exp_info, subject, date)

conditions=[];
conditions(1).name='fixation';
conditions(1).sub_conditions={'fixation'};
conditions(1).event_pairs={{'fix_on','reward'}};
conditions(2).name='motor grasp';
conditions(2).sub_conditions={'motor_grasp_left','motor_grasp_center','motor_grasp_right'};
conditions(2).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','obj_contact'},{'obj_contact','place'},{'place','reward'}};
conditions(3).name='motor rake';
conditions(3).sub_conditions={'motor_rake_left','motor_rake_center','motor_rake_right'};
conditions(3).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','obj_contact'},{'obj_contact','place'},{'place','reward'}};
conditions(4).name='visual grasp';
conditions(4).sub_conditions={'visual_grasp_left','visual_grasp_right'};
conditions(4).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','obj_contact'},{'obj_contact','place'},{'place','reward'}};
conditions(5).name='visual pliers';
conditions(5).sub_conditions={'visual_pliers_left','visual_pliers_right'};
conditions(5).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','tool_mvmt_onset'},{'tool_mvmt_onset','obj_contact'},...
    {'obj_contact','place'},{'place','reward'}};
conditions(6).name='visual rake pull';
conditions(6).sub_conditions={'visual_rake_pull_left','visual_rake_pull_right'};
conditions(6).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','tool_mvmt_onset'},{'tool_mvmt_onset','obj_contact'},...
    {'obj_contact','place'},{'place','reward'}};

% Coordinates of the table corners
table_corner_1=[-32.25 0 76.9];
table_corner_2=[32.25 0 76.9];
table_corner_3=[32.25 0 18];
table_corner_4=[-32.25 0 18];

% Laser coordinates
monkey_tool_right_pos=table_corner_4+[49.5 0 13.8];
monkey_tool_left_pos=table_corner_4+[15.25 0 14.2];
laser_exp_start_right_pos=table_corner_4+[60.3 0 46];
laser_exp_start_left_pos=table_corner_4+[5.5 0 46];
laser_exp_grasp_center_pos=table_corner_4+[32.6 0 47.2];

out_path=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, date, 'eyetracking');
out_fname=sprintf('%s_%s_eyedata.mat', subject, date);
load(fullfile(out_path, out_fname));

for c_idx=1:length(conditions)
    figure();
    condition=conditions(c_idx);
    
    for cs_idx=1:length(condition.sub_conditions)
        sub_condition=condition.sub_conditions{cs_idx};
        
        trials=find(strcmp(data.metadata.condition,sub_condition));
        
        for ep_idx=1:length(condition.event_pairs)
            evt_pair=condition.event_pairs{ep_idx};
            
            subplot(length(condition.sub_conditions),length(condition.event_pairs),...
                (cs_idx-1)*length(condition.event_pairs)+ep_idx);
            colors=get(gca,'ColorOrder');
            hold all
    
            evt1_times=data.metadata.(evt_pair{1});
            evt2_times=data.metadata.(evt_pair{2});
            for k = 1:length(trials)
                t_idx=trials(k);
                transformed_gaze=[data.eyedata.x{t_idx} data.eyedata.y{t_idx}];
                in_table_bounds=(transformed_gaze(:,1)>=table_corner_1(1)) & (transformed_gaze(:,1)<=table_corner_2(1)) & (transformed_gaze(:,2)>=table_corner_3(3)) & (transformed_gaze(:,2)<=table_corner_1(3));
                
                in_bounds=in_table_bounds & (data.eyedata.t{t_idx}>=evt1_times(t_idx)) & (data.eyedata.t{t_idx}<=evt2_times(t_idx));
                plot(transformed_gaze(in_bounds,1),transformed_gaze(in_bounds,2),'k.');
            end
            circle(laser_exp_start_right_pos(1),laser_exp_start_right_pos(3),5,colors(1,:));
            circle(laser_exp_start_left_pos(1),laser_exp_start_left_pos(3),5,colors(2,:));
            circle(laser_exp_grasp_center_pos(1),laser_exp_grasp_center_pos(3),5,colors(3,:));
            circle(monkey_tool_right_pos(1),monkey_tool_right_pos(3),5,colors(4,:));
            circle(monkey_tool_left_pos(1),monkey_tool_left_pos(3),5,colors(5,:));
            axis equal
            title(sprintf('%s: %s-%s',strrep(sub_condition,'_',' '),...
                strrep(evt_pair{1},'_',' '),strrep(evt_pair{2},'_',' ')));
        end
    end    
end
