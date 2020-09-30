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
fcc_dataset('output_path',dir)

fcc_barplot_stage({'fixation' ,'visual_grasp_left' ,'visual_pliers_left',  'visual_rake_push_left',...
'visual_stick_left', 'motor_grasp_left' ,'motor_rake_left'},{'1'},'output_path',dir)
fcc_barplot_stage({'fixation' ,'visual_grasp_left' ,'visual_pliers_left',  'visual_rake_push_left',...
'visual_stick_left', 'motor_grasp_left' ,'motor_rake_left'},{'2'},'output_path',dir)
fcc_barplot_stage({'fixation' ,'visual_grasp_left' ,'visual_pliers_left',  'visual_rake_push_left',...
'visual_stick_left', 'motor_grasp_left' ,'motor_rake_left'},{'3'},'output_path',dir)

fcc_barplot_condition({'fixation'},2,'output_path',dir)

% full condition
fcc_full_conditions({'F1','F5hand'},{'F1','F5hand'},'fixation',{'1','2','3'},'output_path',dir)
fcc_full_conditions({'F1','F5hand'},{'F1'},'fixation',{'1','2','3'},'output_path',dir)
fcc_full_conditions({'F1','F5hand'},{'F5hand'},'fixation',{'1','2','3'},'output_path',dir)
fcc_full_conditions({'F1'},{'F1','F5hand'},'fixation',{'1','2','3'},'output_path',dir)
fcc_full_conditions({'F1'},{'F1'},'fixation',{'1','2','3'},'output_path',dir)
fcc_full_conditions({'F1'},{'F5hand'},'fixation',{'1','2','3'},'output_path',dir)
fcc_full_conditions({'F5hand'},{'F1','F5hand'},'fixation',{'1','2','3'},'output_path',dir)
fcc_full_conditions({'F5hand'},{'F1'},'fixation',{'1','2','3'},'output_path',dir)
fcc_full_conditions({'F5hand'},{'F5hand'},'fixation',{'1','2','3'},'output_path',dir)

% full source/target 
fcc_full_electrodes('fixation','fixation',{'1','2','3'},'output_path',dir)
fcc_full_electrodes( 'visual_grasp_left','fixation',{'1','2','3'},'output_path',dir)
fcc_full_electrodes('visual_pliers_left','fixation',{'1','2','3'},'output_path',dir)
fcc_full_electrodes('visual_rake_push_left','fixation',{'1','2','3'},'output_path',dir)
fcc_full_electrodes( 'visual_stick_left','fixation',{'1','2','3'},'output_path',dir)
fcc_full_electrodes('motor_grasp_left','fixation',{'1','2','3'},'output_path',dir)
fcc_full_electrodes('motor_rake_left','fixation',{'1','2','3'},'output_path',dir)

% ref condition itself
fcc_full_electrodes( 'visual_grasp_left','visual_grasp_left',{'1','2','3'},'output_path',dir)
fcc_full_electrodes('visual_pliers_left','visual_pliers_left',{'1','2','3'},'output_path',dir)
fcc_full_electrodes('visual_rake_push_left','visual_rake_push_left',{'1','2','3'},'output_path',dir)
fcc_full_electrodes( 'visual_stick_left','visual_stick_left',{'1','2','3'},'output_path',dir)
fcc_full_electrodes('motor_grasp_left','motor_grasp_left',{'1','2','3'},'output_path',dir)
fcc_full_electrodes('motor_rake_left','motor_rake_left',{'1','2','3'},'output_path',dir)
  
%% END