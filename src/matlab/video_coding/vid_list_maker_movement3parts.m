function [videopath, xlspath] = vid_list_maker(dateofrecording) %dateofrecording format 'dd-mm-yyyy'

dateofrecording = '12-08-2021';
month = 'Aug'; %3 first letter of the month and the first letter in capital

%videopath = ['C:\Users\kirchher\project\video_coding\', [dateofrecording 'rake\']];
videopath = ['E:\project\video\Samovar','\', month,'\',dateofrecording];
xlspath = ['E:\project\video\Samovar\table\rake_coding_grid_in_xlsx\'];

load('motor_rake_trial_ID_for_video_coding.mat');

logical_trial = [];

for date_idx = 1:size(motor_rake_trial.date,1)
    if strcmp(cell2mat(motor_rake_trial.date{date_idx}),strrep(dateofrecording,'-','.'))
        logical_trial(:,1) = motor_rake_trial.logictrial{date_idx,1};
        logical_trial(:,2) = motor_rake_trial.logictrial{date_idx,2};
        logical_trial(:,3) = motor_rake_trial.logictrial{date_idx,3};
        logical_trial(:,4) = motor_rake_trial.logictrial{date_idx,4};
        logical_trial(:,5) = motor_rake_trial.logictrial{date_idx,5};
        logical_trial(:,6) = motor_rake_trial.logictrial{date_idx,6};
    end
end

%d = dir([videopath '*.avi']);
%d = dir([videopath '.avi']);
d = dir(videopath);

% for i = 1:length(d)
%     filename = d(i).name;
%     datname{i+1,1} = filename;
% end

datname = [];
for i = 1:length(d)
    filename = d(i).name;
    datname{i+1,1} = filename;
%    datname{i+1,2} = 0;
%     if isempty(logical_trial)
%         disp('    *****  no rake data!!!')
%     else
%         for j = 1:6
%             if logical_trial(i,j)==1
%                 datname{i+1,2} = motor_rake_trial.condition{j};
%             end
%         end
%     end
end


datname{1,1} = 'Date';
datname{1,2} = 'Valid video';
datname{1,3} = 'Success';
datname{1,4} = 'exp_hand_Screen';
%% hand to rake (columns in blue)
datname{1,5} = 'Rake starting';
datname{1,6} = 'Target starting';
datname{1,7} = 'Shaft orientation';
datname{1,8} = 'beyond_trap';
datname{1,9} = 'shaft_stumble';
datname{1,10} = 'slap_rake';
%% rake before tool-target contact (columns in yellow)
datname{1,11} = 'direction'; 
datname{1,12} = 'Miss target';
datname{1,13} = 'grasp_type';
datname{1,14} = 'hand_movement';
datname{1,15} = 'Stereotyped pulling';
datname{1,16} = 'sliding';
datname{1,17} = 'Multiple attempts';
datname{1,18} = 'pulled strongly';
datname{1,19} = 'Move toward target';
datname{1,20} = 'Shaft correction';
datname{1,21} = 'Volte';
datname{1,22} = 'Overshoot';
%% rake after tool-target contact (columns in red)
datname{1,23} = 'rake_movement_with_target';
datname{1,24} = 'pulled_not_strong/long_enough';
datname{1,25} = 'kick target';
datname{1,26} = 'rake released';
datname{1,27} = 'grasp_type';
datname{1,28} = 'Multiple attempts_after_contact';
datname{1,29} = 'not pulled all the way';
%% placing to end of the trial (columns in purple)
datname{1,30} = 'Leave target reachable';
datname{1,31} = 'hand_after_trial';
datname{1,32} = 'Groove/grasp priority';
%%
datname{1,33} = 'comments';


if exist([xlspath 'motor_rake_' videopath(end-3:end) videopath(end-6:end-5) ...
        videopath(end-9:end-8)  '_' videopath(end-9:end) '.xlsx']) == 2
    disp('No! This file already exists!');
else
    xlswrite([xlspath 'motor_rake_' videopath(end-3:end) videopath(end-6:end-5) ...
        videopath(end-9:end-8)  '_' videopath(end-9:end) '.xlsx'], datname);
end