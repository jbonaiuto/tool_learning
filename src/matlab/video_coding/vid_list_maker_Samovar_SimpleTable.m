function [videopath, xlspath] = vid_list_maker(dateofrecording) %dateofrecording format 'dd-mm-yyyy'

dateofrecording = '15-06-2021';
%month = 'Aug'; %3 first letter of the month and the first letter in capital
subject = 'Samovar';

%videopath = ['C:\Users\kirchher\project\video_coding\', [dateofrecording 'rake\']];
videopath = ['E:\project\video_coding\rake_videos' '\' subject '\' dateofrecording];
xlspath = ['E:\project\video_coding\' subject '\table\rake_coding_grid_in_xlsx\'];

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
datname{1,3} = 'Rake starting';
datname{1,4} = 'Target starting';
datname{1,5} = 'beyond_trap';
datname{1,6} = 'Success';
datname{1,7} = 'Multiple attempts';
datname{1,8} = 'sliding';
datname{1,9} = 'pulled strongly';
datname{1,10} = 'Overshoot';
datname{1,11} = 'hand_after_trial';
datname{1,12} = 'exp_hand_Screen';
datname{1,13} = 'parasite_mvt';
datname{1,14} = 'comments';

if exist([xlspath 'motor_rake_' videopath(end-3:end) videopath(end-6:end-5) ...
        videopath(end-9:end-8)  '_' videopath(end-9:end) '.xlsx']) == 2
    disp('No! This file already exists!');
else
    xlswrite([xlspath 'motor_rake_' videopath(end-3:end) videopath(end-6:end-5) ...
        videopath(end-9:end-8)  '_' videopath(end-9:end) '.xlsx'], datname);
end