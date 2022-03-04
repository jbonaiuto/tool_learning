%function [videopath, xlspath] = vid_list_maker_4(dateofrecording) %dateofrecording format 'dd-mm-yyyy'

% dbstop if error
% clear all

dateofrecording = '11-10-2019';

%videopath = ['F:\Tool_project\VideoFotTable_Seb\', [dateofrecording 'rake\']];
%videopath = ['F:\Tool_project\videos\new_videos_august_september\' dateofrecording '\'];
%videopath = ['E:\video_coding\' dateofrecording];
videopath = ['E:\video_coding\' dateofrecording '\'];
xlspath = ['C:\Users\kirchher\project\video_coding\table\rake_coding_grid_in_xlsx\'];

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
d = dir([videopath '*.avi']);
%d = dir([videopath '.avi']);
%d = dir(videopath);

datname = [];
for i = 1:length(d)
    filename = d(i).name;
    datname{i+1,1} = filename;
    datname{i+1,2} = 0;
    if isempty(logical_trial)
        disp('    *****  no rake data!!!')
    else
        for j = 1:6
            if logical_trial(i,j)==1
                datname{i+1,2} = motor_rake_trial.condition{j};
            end
        end
    end
    datname{i+1,26} = '-';
    datname{i+1,27} = '-';
    datname{i+1,28} = '-';
    datname{i+1,29} = '-';
    datname{i+1,30} = '-';
    datname{i+1,31} = '-';
    datname{i+1,32} = '-';
    datname{i+1,33} = '-';
    datname{i+1,34} = '-';
end
datname{1,1} = 'Date';
datname{1,2} = 'Neural data';
datname{1,3} = 'Valid trial';
datname{1,4} = 'Does the task';
datname{1,5} = 'With cube';
datname{1,6} = 'Rake starting';
datname{1,7} = 'Target starting';
datname{1,8} = 'Success';
datname{1,9} = 'Miss target';
datname{1,10} = 'Multiple attempts';
datname{1,11} = 'Exp interv';
datname{1,12} = 'Rake guidance';
datname{1,13} = 'Stereotyped pulling';
datname{1,14} = 'Rake pulled';
datname{1,15} = 'Rake only touched or grasped';
datname{1,16} = 'Touch rake head';
datname{1,17} = 'Not pulled all the way';
datname{1,18} = 'Pulled in steps';
datname{1,19} = 'Shaft correction';
datname{1,20} = 'Move toward target';
datname{1,21} = 'Leave target reachable';
datname{1,22} = 'Place target';
datname{1,23} = 'Touch target';
datname{1,24} = 'Screen';
datname{1,25} = 'Volte';
datname{1,26} = 'Hit target';%
datname{1,27} = 'Release the rake';%
datname{1,28} = 'Wrong grasp on the shaft';%
datname{1,29} = 'Shaft orientation';%
datname{1,30} = 'Groove/grasp priority';%
datname{1,31} = 'Spasm handle';%
datname{1,32} = 'Retract arm';%
datname{1,33} = 'Momentum gain';%
datname{1,34} = 'Comments';

if exist([xlspath 'xmotor_rake_' videopath(end-4:end-1) videopath(end-7:end-6) ...
        videopath(end-10:end-9)  '_' videopath(end-10:end-1) '.xlsx']) == 2;
    disp('No! This file already exists!');
else
    xlswrite([xlspath 'motor_rake_' videopath(end-4:end-1) videopath(end-7:end-6) ...
        videopath(end-10:end-9)  '_' videopath(end-10:end-1) '.xlsx'], datname);
end
