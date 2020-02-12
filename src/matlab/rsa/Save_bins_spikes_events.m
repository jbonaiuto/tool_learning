clear all
close all
datefile = '19.04.19'
chosen_array = 'F1'
unit = 'multiunit';
%unit = 'spikes';
defaultmulti = 'MultiUnitfromSingle'; % 'MultiUnitfromTDC'

if contains(unit,'multiunit') & contains(defaultmulti,'MultiUnitfromSingle')
    unitdirectoryinput = 'spikes';
    unitdirectoryoutput = 'MultiUnitfromSingle';
end
if contains(unit,'spikes')
    unitdirectoryinput = 'spikes';
    unitdirectoryoutput = 'SingleUnit';
end
if contains(unit,'multiunit') & contains(defaultmulti,'MultiUnitfromSingle')==0
    unitdirectoryinput = 'multiunit';
    unitdirectoryoutput = 'MultiUnitfromTDC';
end

trial_events = readtable(['D:\Data\Tooltask\preprocessed_data\betta\' datefile '\trial_events.csv']);
trial_info = readtable(['D:\Data\Tooltask\preprocessed_data\betta\' datefile '\trial_info.csv']);
trial_number_unsorted = readtable(['D:\Data\Tooltask\preprocessed_data\betta\' datefile '\trial_numbers.csv']);
trial_number = sortrows(trial_number_unsorted); %Sort alphabetically condnames for having always the same sequence

channel_number = 0:31;
trial_end_time = ones(1,20)*1000;% for each condition
bins=[-3000:20:1000];
kernel_width=6;
kernel=gausswin(kernel_width);
overall_condnames = {'motor_grasp_left';'motor_grasp_center';'motor_grasp_right';
    'visual_grasp_left';'visual_grasp_right';
    'visual_rake_pull_left';'visual_rake_pull_right';
    'visual_pliers_left';'visual_pliers_right';
    'motor_rake_center';'motor_rake_left';'motor_rake_right';
    'motor_rake_food_left';'motor_rake_food_center';'motor_rake_food_right';
    'fixation';
    'visual_rake_push_left';'visual_rake_push_right';
    'stick_left';'stick_right'};

go_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
laser_exp_start_center_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
laser_exp_start_center_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
reward_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
monkey_handle_off_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
grasping_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
placing_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
hand_release_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
monkey_rake_handle_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
tool_release_time(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;

go_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
laser_exp_start_center_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
laser_exp_start_center_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
reward_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
monkey_handle_off_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
grasping_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
placing_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
hand_release_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
monkey_rake_handle_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;
tool_release_tr(1:size(trial_info.condition,1),1:size(overall_condnames,1)) = nan;

for i = 1:size(trial_number.condition,1)
    
    if isempty(trial_number.trials(i))==0 & trial_number.trials(i) > 0
        condnames{i} = trial_number.condition{i};
        
        for j = 1:size(trial_info.condition,1)
            
            if trial_info.status{j}(1,1) == 'g'...
                    & strcmp(trial_number.condition{i},trial_info.condition{j}) == 1% checking if trial is good
                
                if strcmp(condnames{i},overall_condnames{2})==1% motor_grasp_left
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,2) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,2) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,2) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_handle_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,2) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_handle_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,2) = grasping_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_edge'));
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,2) = grasping_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_edge'));
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,2) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_bottom'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,2) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_bottom'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,2) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,2) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    
                end
                
                if strcmp(condnames{i},overall_condnames{1})==1% motor_grasp_center
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,1) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,1) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,1) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_handle_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,1) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_handle_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,1) = grasping_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_edge'));
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,1) = grasping_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_edge'));
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,1) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_bottom'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,1) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_bottom'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,1) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,1) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                end
                
                if strcmp(condnames{i},overall_condnames{3})==1% motor_grasp_right
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,3) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,3) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,3) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_handle_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,3) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_handle_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,3) = grasping_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_edge'));
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,3) = grasping_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_edge'));
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,3) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_bottom'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,3) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_bottom'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,3) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,3) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    
                end
                
                if strcmp(condnames{i},overall_condnames{4})==1% visual_grasp_left
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,4) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,4) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    laser_exp_start_center_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_time(j,4) = laser_exp_start_center_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    laser_exp_start_center_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_tr(j,4) = laser_exp_start_center_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,4) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,4) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,4) = grasping_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,4) = grasping_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,4) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_left'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,4) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_left'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,4) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,4) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                end
                
                if strcmp(condnames{i},overall_condnames{5})==1% visual_grasp_right
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,5) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,5) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    laser_exp_start_center_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_time(j,5) = laser_exp_start_center_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    laser_exp_start_center_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_tr(j,5) = laser_exp_start_center_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,5) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,5) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,5) = grasping_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,5) = grasping_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,5) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_right'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,5) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_right'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,5) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,5) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    
                end
                
                if strcmp(condnames{i},overall_condnames{6})==1% visual_rake_pull_left
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,6) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,6) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    laser_exp_start_center_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_time(j,6) = laser_exp_start_center_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    laser_exp_start_center_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_tr(j,6) = laser_exp_start_center_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,6) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,6) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,6) = grasping_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,6) = grasping_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,6) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_left'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,6) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_left'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,6) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,6) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    
                    tool_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    tool_release_time(j,6) = tool_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'tool_start_off'));
                    tool_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    tool_release_tr(j,6) = tool_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'tool_start_off'));
                    
                    
                end
                
                if strcmp(condnames{i},overall_condnames{7})==1% visual_rake_pull_right
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,7) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,7) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    laser_exp_start_center_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_time(j,7) = laser_exp_start_center_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    laser_exp_start_center_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_tr(j,7) = laser_exp_start_center_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,7) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,7) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,7) = grasping_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,7) = grasping_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,7) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_right'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,7) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_right'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,7) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,7) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    
                    tool_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    tool_release_time(j,7) = tool_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'tool_start_off'));
                    tool_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    tool_release_tr(j,7) = tool_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'tool_start_off'));
                end
                
                if strcmp(condnames{i},overall_condnames{8})==1% visual_pliers_left
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,8) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,8) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    laser_exp_start_center_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_time(j,8) = laser_exp_start_center_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    laser_exp_start_center_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_tr(j,8) = laser_exp_start_center_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,8) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,8) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,8) = grasping_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,8) = grasping_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,8) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_left'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,8) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_left'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,8) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,8) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    
                    tool_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    tool_release_time(j,8) = tool_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'tool_start_off'));
                    tool_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    tool_release_tr(j,8) = tool_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'tool_start_off'));
                    
                end
                
                if strcmp(condnames{i},overall_condnames{9})==1% visual_pliers_right
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,9) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,9) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    laser_exp_start_center_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_time(j,9) = laser_exp_start_center_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    laser_exp_start_center_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    laser_exp_start_center_tr(j,9) = laser_exp_start_center_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'laser_exp_start_center'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,9) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,9) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_start_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,9) = grasping_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,9) = grasping_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_grasp_center'));
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,9) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_right'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,9) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'exp_place_right'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,9) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,9) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    
                    tool_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    tool_release_time(j,9) = tool_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'tool_start_off'));
                    tool_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    tool_release_tr(j,9) = tool_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'tool_start_off'));
                    
                end
                
                if strcmp(condnames{i},overall_condnames{10})==1 & isempty(grasping_time_tmp(strncmpi(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_tool',11)))==0 ...
                        & isempty(placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_edge')))==0
                    % motor rake mid left center mid right
                    
                    go_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    go_time(j,10) = go_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    go_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    go_tr(j,10) = go_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'go'));
                    
                    monkey_rake_handle_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    monkey_rake_handle_time(j,10) = monkey_rake_handle_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_rake_handle'));
                    monkey_rake_handle_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    monkey_rake_handle_tr(j,10) = monkey_rake_handle_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_rake_handle'));
                    
                    hand_release_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_time(j,10) = hand_release_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_handle_off'));
                    hand_release_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    hand_release_tr(j,10) = hand_release_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_handle_off'));
                    
                    grasping_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    grasping_time(j,10) = max(grasping_time_tmp(strncmpi(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_tool',11)));% note 11 first characters
                    grasping_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    grasping_tr(j,10) = max(grasping_tr_tmp(strncmpi(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'monkey_tool',11)));% note 11 first characters
                    
                    placing_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    placing_time(j,10) = placing_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_edge'));
                    placing_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    placing_tr(j,10) = placing_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'trap_edge'));
                    
                    reward_time_tmp = trial_events.time(trial_events.trial==trial_info.overall_trial(j));
                    reward_time(j,10) = reward_time_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                    reward_tr_tmp = trial_events.trial(trial_events.trial==trial_info.overall_trial(j));
                    reward_tr(j,10) = reward_tr_tmp(strcmp(trial_events.event...
                        (trial_events.trial==trial_info.overall_trial(j)),'reward'));
                end
                
                cond_trial(j,i)=nan;
                
            end
        end
    end
end
alignment = [];
alignrow = 0;
%aligncol = 0;
for jj = 1:size(grasping_time,2) % number of conditions
    %aligncol = aligncol+1;
    alignrow = 0;
    for ii = 1:size(grasping_time,1) % overall trials
        if isnan(grasping_time(ii,jj))==0
            dataaligntime = grasping_time(ii,jj);           
            dataaligntr = grasping_tr(ii,jj);
            releasetime = hand_release_time(ii,jj);
            gosignal = go_time(ii,jj);
            placingtime = placing_time(ii,jj);
            rewardtime = reward_time(ii,jj);
            alignrow = alignrow+1;
            toolreleasetime = tool_release_time(ii,jj);
            monkeyrakehandletime = monkey_rake_handle_time(ii,jj);

            
            alignment{jj}(alignrow,1) = dataaligntime(isnan(grasping_time(ii,jj))==0);
            grasping_trials{jj}(alignrow,1) = dataaligntr(isnan(grasping_time(ii,jj))==0);
            release_time{jj}(alignrow,1) = releasetime(isnan(grasping_time(ii,jj))==0);
            grasp_time{jj}(alignrow,1) = alignment{jj}(alignrow,1);
            go_signal_time{jj}(alignrow,1) = gosignal(isnan(grasping_time(ii,jj))==0);
            object_placing_time{jj}(alignrow,1) = placingtime(isnan(grasping_time(ii,jj))==0);
            reward_delivery_time{jj}(alignrow,1) = rewardtime(isnan(grasping_time(ii,jj))==0);
            raketool_monkey_handle_time{jj}(alignrow,1) = monkeyrakehandletime(isnan(grasping_time(ii,jj))==0);
            
            tool_start_release_time{jj}(alignrow,1) = toolreleasetime(isnan(grasping_time(ii,jj))==0);
            %end
        end
    end
    if jj == 20
        alignment{jj}=[];
        grasping_trials{jj}=[];
        release_time{jj}=[];
        grasp_time{jj}=[];
        go_signal_time{jj}=[];
        object_placing_time{jj}=[];
        reward_delivery_time{jj}=[];
        tool_start_release_time{jj}=[];
        raketool_monkey_handle_time{jj}=[];
    end
end


condition_name = condnames;

for i = 1:32 %channel number
    cellnumber = [];
    spiketable = readtable(['D:\Data\Tooltask\preprocessed_data\betta\' datefile '\' unitdirectoryinput '\' chosen_array '_' num2str(channel_number(i)) '_spikes.csv']);
    if contains(unitdirectoryinput,'spikes') & contains(unitdirectoryoutput,'spikes')
        cellnumber = unique(spiketable.cell);
    else
        cellnumber = 0;
    end
    
    for k = 1:length(cellnumber)  % cell number
        
        firing_rate_directory = ['D:\Data\Tooltask\' unitdirectoryoutput '\betta\firing_rate\' datefile '\t0_is_graspminus3000\' chosen_array '\channel_' num2str(channel_number(i)) '\cell_' num2str(cellnumber(k)) '\'];
        event_directory = ['D:\Data\Tooltask\' unitdirectoryoutput '\betta\firing_rate\' datefile '\t0_is_graspminus3000\events\'];
        spike_directory = ['D:\Data\Tooltask\' unitdirectoryoutput '\betta\firing_rate\' datefile '\t0_is_graspminus3000\' chosen_array '\channel_' num2str(channel_number(i))  '\cell_' num2str(cellnumber(k)) '\spike_time\'];
        
        
        if exist(firing_rate_directory) == 7
        else
            mkdir(firing_rate_directory);
        end
        if exist(event_directory) == 7
        else
            mkdir(event_directory);
        end
        if exist(spike_directory) == 7
        else
            mkdir(spike_directory);
        end
        
        firing_rate_data={};
        %for m = 5:5%length(condition_name) % condition number
        for m = 1:length(overall_condnames)
            if isempty(grasping_trials{m})==0% condition number 
                %for m = 1:length(condition_name) % condition number
                bin_counts_all = [];
                bin_counts_allbaseline = [];
                %for j = 1:length(grasping_time(:,m))% trial number
                for j = 1:length(grasping_trials{m})% trial number
                    
                    bin_counts = [];
                    % single unit
                    if contains(unitdirectoryinput,'spikes') == 1
                    spikes_unaligned = spiketable.time((spiketable.cell == cellnumber(k) & spiketable.trial == grasping_trials{m}(j)),1);
                    end
                    % multiunit based on single unit
                    if contains(unitdirectoryinput,'spikes') == 1 & contains(defaultmulti,'MultiUnitfromSingle') == 1
                     spikes_unaligned = spiketable.time((spiketable.cell >= 0 & spiketable.trial == grasping_trials{m}(j)),1);
                    end
                    if contains(unitdirectoryinput,'spikes') == 0 & contains(defaultmulti,'MultiUnitfromSingle') == 0
                    % multiunit based on TDC
                    spikes_unaligned = spiketable.time((spiketable.trial == grasping_trials{m}(j)),1);
                    end
                    spikes = [];
                    spikes = (spikes_unaligned*1000) - alignment{m}(j); % grasping touch
                    bins=[-3000:20:trial_end_time(m)];
                    
                    if size(spikes,1) < 2
                        bin_counts = zeros(length(bins),1);
                    else
                        bin_counts=histc(spikes,bins);
                    end
                    bin_counts_all = [bin_counts bin_counts_all];
                    firing_rate=mean(bin_counts_all,2)*(1000/20);
                    
                    %*******************************************************************************
                    %*************for baseline
                    
                    spikesbaseline = spikes_unaligned*1000 - go_signal_time{m}(j); % baseline is aligned on go signal
                    binsbaseline=[-3000:20:trial_end_time(m)];
                    %
                    if size(spikesbaseline,1) < 2
                        bin_countsbaseline = zeros(length(binsbaseline),1);
                    else
                        bin_countsbaseline=histc(spikesbaseline,binsbaseline);
                    end
                    bin_counts_allbaseline = [bin_countsbaseline bin_counts_allbaseline];
                    firing_ratebaseline=mean(bin_counts_allbaseline,2)*(1000/20);
                    
                    %******************************************************************************
                    
                    
                    firing_rate_data{1,m} = bin_counts_all;
                    firing_rate_baseline{1,m} = bin_counts_allbaseline;
                    smooth_firing_rate=filter(kernel,1,firing_rate);
                    %smooth_firing_rate=smoothdata(firing_rate,1);
                    spikes_trials{j,1} = spikes;
                    
                    csvwrite([spike_directory 'spike_time_for_trial_' num2str(j) '_' overall_condnames{m} '.csv'], spikes);
                                    
                end
                
                %hold off
                
                csvwrite([firing_rate_directory 'fr_' overall_condnames{m} '.csv'],bin_counts_all);
                csvwrite([firing_rate_directory 'frb_' overall_condnames{m} '.csv'],bin_counts_allbaseline);
            end
            if i == 2
                csvwrite([event_directory 'release_time_' overall_condnames{m} '.csv'], release_time{m});
                csvwrite([event_directory 'object_placing_time_' overall_condnames{m} '.csv'], object_placing_time{m});
                csvwrite([event_directory 'go_signal_time_' overall_condnames{m} '.csv'], go_signal_time{m});
                csvwrite([event_directory 'grasp_time_' overall_condnames{m} '.csv'], grasp_time{m});
                csvwrite([event_directory 'reward_' overall_condnames{m} '.csv'], reward_delivery_time{m});
                csvwrite([event_directory 'tool_start_release_time_' overall_condnames{m} '.csv'], tool_start_release_time{m});
                csvwrite([event_directory 'raketool_monkey_handle_time_' overall_condnames{m} '.csv'], tool_start_release_time{m});
            end
            
        end
    end
end




