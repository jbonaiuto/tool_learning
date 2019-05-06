function split_by_condition(exp_info, orig_data, subject, recording_date)

output_dir=fullfile('/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/output/data/lfp',subject,recording_date);
mkdir(output_dir);

visual_grasp_trials=union(find(orig_data.trialinfo(:,1)==1), find(orig_data.trialinfo(:,1)==2));
data=[];
data.label={};
for a=1:length(exp_info.array_names)
    for c=1:32
        data.label{end+1}=sprintf('%s_%d',exp_info.array_names{a},c);
    end
end
data.fsample=orig_data.fsample;
data.time=orig_data.time(visual_grasp_trials);
data.trial=orig_data.trial(visual_grasp_trials);
data.trialinfo=orig_data.trialinfo(visual_grasp_trials,:);
save(fullfile(output_dir, sprintf('%s_%s_lfp_visual_grasp.mat', subject, recording_date)), 'data');

motor_grasp_trials=union(union(find(orig_data.trialinfo(:,1)==3), find(orig_data.trialinfo(:,1)==4)), find(orig_data.trialinfo(:,1)==5));
data=[];
data.label={};
for a=1:length(exp_info.array_names)
    for c=1:32
        data.label{end+1}=sprintf('%s_%d',exp_info.array_names{a},c);
    end
end
data.fsample=orig_data.fsample;
data.time=orig_data.time(motor_grasp_trials);
data.trial=orig_data.trial(motor_grasp_trials);
data.trialinfo=orig_data.trialinfo(motor_grasp_trials,:);
save(fullfile(output_dir, sprintf('%s_%s_lfp_motor_grasp.mat', subject, recording_date)), 'data');