function [data,bad_trials]=filter_data(data, varargin)

% FILTER_DATA Filters data by removing trials based on some criteria
% 
%
% Syntax: data=filter_data(exp_info, data, conditions, varargin);
%
% Inputs:
%    exp_info - experimental info data structure (created with
%               init_exp_info.m)
%    data - structure containing data (created by load_multiunit_data)
%    conditions - list of conditions
%
% Outputs:
%    data - data structure containing filtered data
%
% Example:
%     data=filter_data(exp_info, data, conditions);

defaults = struct();  %define default values
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

bad_trials=[];

motor_grasp_conditions={'motor_grasp_left','motor_grasp_center','motor_grasp_right'};
motor_grasp_trials=zeros(1,length(data.metadata.condition));
for i=1:length(motor_grasp_conditions)
  motor_grasp_trials = motor_grasp_trials | (strcmp(data.metadata.condition,motor_grasp_conditions{i}));
end
motor_grasp_trials=find(motor_grasp_trials);
motor_grasp_bad_trials=[];

% Figure out RT of each trial
rts=data.metadata.hand_mvmt_onset(motor_grasp_trials)-data.metadata.go(motor_grasp_trials);
% Figure out MT of each trial
mts=data.metadata.obj_contact(motor_grasp_trials)-data.metadata.hand_mvmt_onset(motor_grasp_trials);
% Figure out PT of each trial
pts=data.metadata.place(motor_grasp_trials)-data.metadata.obj_contact(motor_grasp_trials);
      
rt_bad_trials=union(find(rts<200),find(rts>1000));
disp(sprintf('Removing %d motor grasp trials based on RT', length(rt_bad_trials)));
motor_grasp_bad_trials=union(motor_grasp_bad_trials,motor_grasp_trials(rt_bad_trials));

mt_bad_trials=union(find(mts<200),find(mts>1000));
disp(sprintf('Removing %d motor grasp trials based on MT', length(mt_bad_trials)));
motor_grasp_bad_trials=union(motor_grasp_bad_trials,motor_grasp_trials(mt_bad_trials));

pt_bad_trials=union(find(pts<200),find(pts>1000));
disp(sprintf('Removing %d motor grasp trials based on PT', length(pt_bad_trials)));
motor_grasp_bad_trials=union(motor_grasp_bad_trials,motor_grasp_trials(pt_bad_trials));

disp(sprintf('Removing %d motor grasp trials total', length(motor_grasp_bad_trials)));

bad_trials=union(bad_trials, motor_grasp_bad_trials);


visual_grasp_conditions={'visual_grasp_left','visual_grasp_right'};
visual_grasp_trials=zeros(1,length(data.metadata.condition));
for i=1:length(visual_grasp_conditions)
  visual_grasp_trials = visual_grasp_trials | (strcmp(data.metadata.condition,visual_grasp_conditions{i}));
end
visual_grasp_trials=find(visual_grasp_trials);
visual_grasp_bad_trials=[];

% Figure out RT of each trial
rts=data.metadata.hand_mvmt_onset(visual_grasp_trials)-data.metadata.go(visual_grasp_trials);
% Figure out MT of each trial
mts=data.metadata.obj_contact(visual_grasp_trials)-data.metadata.hand_mvmt_onset(visual_grasp_trials);
% Figure out PT of each trial
pts=data.metadata.place(visual_grasp_trials)-data.metadata.obj_contact(visual_grasp_trials);
      
rt_bad_trials=union(find(rts<200),find(rts>1000));
disp(sprintf('Removing %d visual grasp trials based on RT', length(rt_bad_trials)));
visual_grasp_bad_trials=union(visual_grasp_bad_trials,visual_grasp_trials(rt_bad_trials));

mt_bad_trials=union(find(mts<200),find(mts>1000));
disp(sprintf('Removing %d visual grasp trials based on MT', length(mt_bad_trials)));
visual_grasp_bad_trials=union(visual_grasp_bad_trials,visual_grasp_trials(mt_bad_trials));

pt_bad_trials=union(find(pts<200),find(pts>1000));
disp(sprintf('Removing %d visual grasp trials based on PT', length(pt_bad_trials)));
visual_grasp_bad_trials=union(visual_grasp_bad_trials,visual_grasp_trials(pt_bad_trials));

disp(sprintf('Removing %d visual grasp trials total', length(visual_grasp_bad_trials)));

bad_trials=union(bad_trials, visual_grasp_bad_trials);

visual_pliers_conditions={'visual_pliers_left','visual_pliers_right'};
visual_pliers_trials=zeros(1,length(data.metadata.condition));
for i=1:length(visual_pliers_conditions)
  visual_pliers_trials = visual_pliers_trials | (strcmp(data.metadata.condition,visual_pliers_conditions{i}));
end
visual_pliers_trials=find(visual_pliers_trials);
visual_pliers_bad_trials=[];

% Figure out RT of each trial
rts=data.metadata.hand_mvmt_onset(visual_pliers_trials)-data.metadata.go(visual_pliers_trials);
% Figure out TT of each trial
tts=data.metadata.tool_mvmt_onset(visual_pliers_trials)-data.metadata.hand_mvmt_onset(visual_pliers_trials);
% Figure out MT of each trial
mts=data.metadata.obj_contact(visual_pliers_trials)-data.metadata.tool_mvmt_onset(visual_pliers_trials);
% Figure out PT of each trial
pts=data.metadata.place(visual_pliers_trials)-data.metadata.obj_contact(visual_pliers_trials);
      
rt_bad_trials=union(find(rts<200),find(rts>1000));
disp(sprintf('Removing %d visual pliers trials based on RT', length(rt_bad_trials)));
visual_pliers_bad_trials=union(visual_pliers_bad_trials,visual_pliers_trials(rt_bad_trials));

tt_bad_trials=union(find(tts<500),find(tts>1000));
disp(sprintf('Removing %d visual pliers trials based on MT', length(tt_bad_trials)));
visual_pliers_bad_trials=union(visual_pliers_bad_trials,visual_pliers_trials(tt_bad_trials));

mt_bad_trials=union(find(mts<200),find(mts>1000));
disp(sprintf('Removing %d visual pliers trials based on MT', length(mt_bad_trials)));
visual_pliers_bad_trials=union(visual_pliers_bad_trials,visual_pliers_trials(mt_bad_trials));

pt_bad_trials=union(find(pts<200),find(pts>1000));
disp(sprintf('Removing %d visual pliers trials based on PT', length(pt_bad_trials)));
visual_pliers_bad_trials=union(visual_pliers_bad_trials,visual_pliers_trials(pt_bad_trials));

disp(sprintf('Removing %d visual pliers trials total', length(visual_pliers_bad_trials)));

bad_trials=union(bad_trials, visual_pliers_bad_trials);

disp(sprintf('Removing %d trials total', length(bad_trials)));

data=remove_trials(data, bad_trials);