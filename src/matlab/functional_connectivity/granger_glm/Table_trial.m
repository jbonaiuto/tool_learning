%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% Working script
%
% analysis of functional connectivity of spykes train
% INPUT:     preprocess data (set path in laoding data)
% OUTPUT:    Plot and table (set path in saving data)
%
% Thomas Quettier 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all

%% Parameters

array = {'F1','F5hand'}; 
electrodes = 1:32;
event = 'whole_trial';

condition= {'visual_stick_left'    , ' visual_stick_right'};
% {'fixation'};
% {'visual_grasp_left'    , 'visual_grasp_right'};
% {'visual_pliers_left'   , 'visual_pliers_right'};
% {'visual_rake_pull_left', 'visual_rake_pull_right'}; 
% {'visual_rake_push_left', ' visual_rake_push_right'}; 
% {'visual_stick_left'    , ' visual_stick_right'};
% {'motor_grasp_left'     , 'motor_grasp_center'    , 'motor_grasp_right'};
% {'motor_rake_left'      , 'motor_rake_center'     , 'motor_rake_right'};
% {'motor_rake_center_catch'};
% {'motor_rake_food_left' , 'motor_rake_food_center', 'motor_rake_food_right'}; 



% Available weeks (number_of_trials_per_day_table_betta.csv)
weeks=[1:17 19:27 29:44 46:47 50:57]; 
%no data weeks 18,28,45,48,49. 
%stage1: 1:7
%stage2: 8:32
%stage3: 33:57

%% loading data
%
% %loading data SERVEUR
% data_dir = '/home/bonaiuto/tool_learning/preprocessed_data/betta/'; % data folder path
% addpath('/home/tquettier/Desktop/spm12/'); 
% parentdir = '/home/tquettier/output/functional_connectivity/';% output folder
% 
% %loading data ICS
% data_dir = 'C:\Users\quettier\Documents\GitHub\tool_learning\preprocessed_data\betta'; % data folder path
% addpath('C:\Users\quettier\Documents\GitHub\tool_learning\src\matlab\spm12'); 
% parentdir = 'C:\Users\quettier\Documents\GitHub\tool_learning\output\functional_connectivity';
%
% %loading data mac
data_dir = '/Users/thomasquettier/Documents/GitHub/tool_learning/preprocessed_data/betta/'; % data folder path
addpath('/Users/thomasquettier/Documents/GitHub/tool_learning/src/matlab/spm12'); 
parentdir = '/Users/thomasquettier/Documents/GitHub/tool_learning/output/functional_connectivity';

%% exp_info.base_data_dir 
%
% %CHANGE row 23 !!!!!!!!!!!
%
% %serveur
% exp_info.base_data_dir='/home/bonaiuto/tool_learning/'; %trial selection cor file pathway
%
% %ISC
% exp_info.base_data_dir='C:\Users\quettier\Documents\GitHub\tool_learning\';
%
% %mac
% exp_info.base_data_dir='/Users/thomasquettier/Documents/GitHub/tool_learning';


%% week selection (find available trials and create a table)
 
table = zeros(length(weeks),5);
for week_number = 1:length(weeks)  
   date=dateInweek(parentdir,weeks(week_number));

X=select_week_trials(data_dir, date, array, electrodes, condition,event);
[CHN SMP TRL] = size(X);
size_trial = zeros(1,TRL);
for itrial = 1:TRL
size_trial(itrial) = length(find(~isnan(X(1,:,itrial))));
end
table(weeks(week_number), 1) = weeks(week_number);
table(weeks(week_number), 5) = TRL;
if TRL == 0
else   
table(weeks(week_number), 2) = round(min(size_trial));
table(weeks(week_number), 3) = round(max(size_trial));
table(weeks(week_number), 4) = round(mean(size_trial));
end
end

foldername = fullfile(parentdir,sprintf('trial_table_%s_%s.csv', condition{1},event));
csvwrite(foldername,table)

%% effective weeks 

table=table(table(:,5)>0 & table(:,5)<10000 ,:);
weeks=[table(:,1)];

%% END