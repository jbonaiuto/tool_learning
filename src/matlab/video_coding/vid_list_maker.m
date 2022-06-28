function [videopath, xlspath] = vid_list_maker(dateofrecording) %dateofrecording format 'dd-mm-yyyy'

%videopath = ['C:\Users\kirchher\project\video_coding\', [dateofrecording 'rake\']];
videopath = ['E:\video_coding\Samovar', dateofrecording];
xlspath = ['E:\video_coding\Samovar\table\rake_coding_grid_in_xlsx\'];

d = dir([videopath '*.avi']);

for i = 1:length(d)
    filename = d(i).name;
    datname{i+1,1} = filename;
end

datname{1,1} = 'Date';
datname{1,2} = 'Neural data';
datname{1,3} = 'Valid trial';
datname{1,4} = 'Does the task';
datname{1,5} = 'With cube';
datname{1,6} = 'Rake starting'; 
datname{1,7} = 'Target starting';
datname{1,8} = 'direction';
datname{1,9} = 'Success';
datname{1,10} = 'Miss target';
datname{1,11} = 'Multiple attempts';
datname{1,12} = 'Exp interv';
datname{1,13} = 'Rake guidance';
datname{1,14} = 'Stereotyped pulling';
datname{1,15} = 'Rake pulled';
datname{1,16} = 'Rake only touched or grasped';
datname{1,17} = 'Touch rake head';
datname{1,18} = 'Not pulled all the way';
datname{1,19} = 'Pulled in steps';
datname{1,20} = 'Shaft correction';
datname{1,21} = 'Move toward target';
datname{1,22} = 'Leave target reachable';
datname{1,23} = 'Release the rake';
datname{1,24} = 'Place target';
datname{1,25} = 'Touch target';
datname{1,26} = 'Screen';
datname{1,27} = 'Volte';
datname{1,28} = 'hit target';
datname{1,29} = 'Wrong grasp on the shaft';
datname{1,30} = 'Shaft orientation';
datname{1,31} = 'Groove/grasp priority';
datname{1,32} = 'Spasm handle';
datname{1,33} = 'Retract arm';
datname{1,34} = 'momentum gain';
datname{1,35} = 'comments';


if exist([xlspath 'Rake_object_beside_' videopath(end-8:end-5) videopath(end-11:end-10) ...
        videopath(end-14:end-13) '_' videopath(end-14:end-5) '.xlsx']) == 2
    disp(' ');disp(' ');
    disp('No! This file already exists! Dumbass!');
    disp('*****Quel con!!!');
else
    xlswrite([xlspath 'motor_rake_' videopath(end-8:end-5) videopath(end-11:end-10) ...
        videopath(end-14:end-13) '_' videopath(end-14:end-5) '.xlsx'], datname);
end