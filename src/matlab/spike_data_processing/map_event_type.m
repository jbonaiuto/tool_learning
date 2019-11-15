function mapped_event_type=map_event_type(condition, event_type)
% MAP_EVENT_TYPE Maps event type from common label across conditions to
% specific event type for the given condition. For example, hand_mvmt_onset
% is mapped to exp_start_off in the visual conditions, and
% monkey_handle_off in the motor conditions
%
% Syntax: mapped_event_type=map_event_type(condition, event_type);
%
% Inputs:
%    condition - name of the condition
%    event_type - name of event type common to all conditions
%
% Outputs:
%    mapped_event_type - name of event type specific to given condition
%
% Example:
%     mapped_event_type=map_event_type('visual_grasp_left', 'hand_mvmt_onset')

mapped_event_type='';
if strcmp(condition,'visual_grasp_left')
    if strcmp(event_type,'obj_contact')
        mapped_event_type='exp_grasp_center';
    elseif strcmp(event_type,'place')
        mapped_event_type='exp_place_left';
    elseif strcmp(event_type,'reward')
        mapped_event_type='reward';
    elseif strcmp(event_type,'hand_mvmt_onset')
        mapped_event_type='exp_start_off';
    elseif strcmp(event_type,'fix_on')
        mapped_event_type='laser_exp_start_center';
    elseif strcmp(event_type,'go')
        mapped_event_type='go';
    elseif strcmp(event_type,'trial_start')
        mapped_event_type='trial_start';
    end
elseif strcmp(condition,'visual_grasp_right')
    if strcmp(event_type,'obj_contact')
        mapped_event_type='exp_grasp_center';
    elseif strcmp(event_type,'place')
        mapped_event_type='exp_place_right';
    elseif strcmp(event_type,'reward')
        mapped_event_type='reward';
    elseif strcmp(event_type,'hand_mvmt_onset')
        mapped_event_type='exp_start_off';
    elseif strcmp(event_type,'fix_on')
        mapped_event_type='laser_exp_start_center';
    elseif strcmp(event_type,'go')
        mapped_event_type='go';
    elseif strcmp(event_type,'trial_start')
        mapped_event_type='trial_start';
    end
elseif strcmp(condition,'motor_grasp_left') || strcmp(condition,'motor_grasp_center') || strcmp(condition,'motor_grasp_right')
    if strcmp(event_type,'obj_contact')
        mapped_event_type='trap_edge';
    elseif strcmp(event_type,'place')
        mapped_event_type='trap_bottom';
    elseif strcmp(event_type,'reward')
        mapped_event_type='reward';
    elseif strcmp(event_type,'hand_mvmt_onset')
        mapped_event_type='monkey_handle_off';
    elseif strcmp(event_type,'fix_on')
        mapped_event_type='laser_monkey_tool_center';
    elseif strcmp(event_type,'go')
        mapped_event_type='go';
    elseif strcmp(event_type,'trial_start')
        mapped_event_type='trial_start';
    end
elseif strcmp(condition,'visual_pliers_left') || strcmp(condition,'visual_rake_pull_left')
    if strcmp(event_type,'obj_contact')
        mapped_event_type='exp_grasp_center';
    elseif strcmp(event_type,'place')
        mapped_event_type='exp_place_left';
    elseif strcmp(event_type,'reward')
        mapped_event_type='reward';
    elseif strcmp(event_type,'hand_mvmt_onset')
        mapped_event_type='exp_start_off';
    elseif strcmp(event_type,'fix_on')
        mapped_event_type='laser_exp_start_center';
    elseif strcmp(event_type,'go')
        mapped_event_type='go';
    elseif strcmp(event_type,'trial_start')
        mapped_event_type='trial_start';
    elseif strcmp(event_type,'tool_mvmt_onset')
        mapped_event_type='tool_start_off';
    end
elseif strcmp(condition,'visual_pliers_right') || strcmp(condition,'visual_rake_pull_right')
    if strcmp(event_type,'obj_contact')
        mapped_event_type='exp_grasp_center';
    elseif strcmp(event_type,'place')
        mapped_event_type='exp_place_right';
    elseif strcmp(event_type,'reward')
        mapped_event_type='reward';
    elseif strcmp(event_type,'hand_mvmt_onset')
        mapped_event_type='exp_start_off';
    elseif strcmp(event_type,'fix_on')
        mapped_event_type='laser_exp_start_center';
    elseif strcmp(event_type,'go')
        mapped_event_type='go';
    elseif strcmp(event_type,'trial_start')
        mapped_event_type='trial_start';
    elseif strcmp(event_type,'tool_mvmt_onset')
        mapped_event_type='tool_start_off';
    end
elseif strcmp(condition,'fixation')
    if strcmp(event_type,'reward')
        mapped_event_type='reward';
    elseif strcmp(event_type,'fix_on')
        mapped_event_type='laser_exp_start_center';
    elseif strcmp(event_type,'trial_start')
        mapped_event_type='trial_start';                
    end
else
    disp(condition);
end