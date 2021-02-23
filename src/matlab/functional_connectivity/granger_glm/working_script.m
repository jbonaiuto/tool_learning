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
condition= {'fixation'};


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
data_dir = '/Users/thomasquettier/Documents/GitHub/tool_learning/preprocessed_data/betta'; % data folder path
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


%% effective weeks 

weeks = weekIncondition(condition);


%% function

for week_number = 1:length(weeks) 
dates = dateInweek(parentdir,weeks(week_number));


foldername = sprintf('Week_%d_%s_%s', weeks(week_number),condition{1},event); 
  
newfolder = fullfile(parentdir, foldername);
    if ~exist(newfolder, 'dir')
       mkdir(newfolder)
    end
output = sprintf('%s/%s',parentdir,foldername);

func_connectivity_within_array(data_dir, dates, array, electrodes, condition,event, 'output_path', output)

end


%plots
dir = '/Users/thomasquettier/Documents/GitHub/tool_learning/output/functional_connectivity/';
fcc_dataset('output_path',dir);

fixation = suffled_frobenius({'fixation'},{'fixation'},'output_path',dir)
visual_grasp = suffled_frobenius({'visual_grasp_left'},{'fixation'},'output_path',dir)
visual_pliers = suffled_frobenius({'visual_pliers_left'},{'fixation'},'output_path',dir)
visual_rake_pull = suffled_frobenius({'visual_rake_pull_left'},{'fixation'},'output_path',dir)
visual_rake_push = suffled_frobenius({'visual_rake_push_left'},{'fixation'},'output_path',dir)
visual_stick = suffled_frobenius({'visual_stick_left'},{'fixation'},'output_path',dir)
motor_grasp = suffled_frobenius({'motor_grasp_left'},{'fixation'},'output_path',dir)
motor_rake = suffled_frobenius({'motor_rake_left'},{'fixation'},'output_path',dir)
motor_rake_center = suffled_frobenius({'motor_rake_center_catch'},{'fixation'},'output_path',dir)
motor_rake_food = suffled_frobenius({'motor_rake_food_left'},{'fixation'},'output_path',dir)

cor_comp_trials({'fixation'},{'fixation'},'output_path',dir)
cor_comp_trials({'visual_grasp_left'},{'fixation'},'output_path',dir)
cor_comp_trials({'visual_pliers_left'},{'fixation'},'output_path',dir)
cor_comp_trials({'visual_rake_pull_left'},{'fixation'},'output_path',dir)
cor_comp_trials({'visual_rake_push_left'},{'fixation'},'output_path',dir)
cor_comp_trials({'visual_stick_left'},{'fixation'},'output_path',dir)
cor_comp_trials({'motor_grasp_left'},{'fixation'},'output_path',dir)
cor_comp_trials({'motor_rake_left'},{'fixation'},'output_path',dir)
cor_comp_trials({'motor_rake_center_catch'},{'fixation'},'output_path',dir)
cor_comp_trials({'motor_rake_food_left'},{'fixation'},'output_path',dir)



mdl_full({'F1F1'},{'fixation'},'output_path',dir)
mdl_full({'F1F5'},{'fixation'},'output_path',dir)
mdl_full({'F5F1'},{'fixation'},'output_path',dir)
mdl_full({'F5F5'},{'fixation'},'output_path',dir)


binimial = [fixation;
visual_grasp;
visual_pliers;
visual_rake_pull;
visual_rake_push;
visual_stick;
motor_grasp;
motor_rake;
motor_rake_center;
motor_rake_food]

ref = {'fixation'};
condition ={'fixation'};
slcs = {'F1F1'};
params.output_fname = 'granger_glm_results.mat';
params.output_path = '../../../../output/functional_connectivity';
params.nb_simulation = 1000;
params.CI_p = .05;


%% END
