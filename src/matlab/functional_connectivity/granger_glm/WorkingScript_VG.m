%% Working script 01/2020
%
%% VISUAL GRASPING
%
% analysis of functional connectivity of spykes train
% INPUT:     preprocess data (set path in laoding data)
% OUTPUT:    Plot and table (set path in saving data)
%
% Thomas Quettier 

clc
clear all
close all

%% Parameters

arrays = {'F1'}; % ,'F5hand'
electrode = 1:2;
week_number = 14; % 1 to 14 , cf function week(x)
condition =0; % 1: motor, 0: visual

%% loading data 

datapath = '/Users/thomasquettier/Desktop/multiunit_binned_data'; % data folder path
addpath('../../../../src/matlab/spm12'); 


%% saving data

dates = week(week_number); 

parentdir = '../../../../output/functional_connectivity';
    if condition == 1
        foldername = sprintf('Week_%d_motor_X', week_number); 
    elseif condition == 0      
        foldername = sprintf('Week_%d_visual_X',week_number);
    end
newfolder = fullfile(parentdir, foldername);
    if ~exist(newfolder, 'dir')
       mkdir(newfolder)
    end
output = sprintf('%s/%s',parentdir,foldername);


%% function
% full trial
if condition == 0
    conditions={'visual_grasp_left','visual_grasp_right'};
elseif condition == 1
    conditions={'motor_grasp_left','motor_grasp_center','motor_grasp_right'};
end

func_connectivity_within_array_X(datapath, dates, arrays, electrode, conditions, 'output_path', output)


% 0 sec  to 2 sec
%     if condition == 1
%         foldername = sprintf('Week_%d_motor_Z', week_number); 
%     elseif condition == 0      
%         foldername = sprintf('Week_%d_visual_Z',week_number);
%     end
% newfolder = fullfile(parentdir, foldername);
%     if ~exist(newfolder, 'dir')
%        mkdir(newfolder)
%     end
% output = sprintf('%s/%s',parentdir,foldername);
% 
% func_connectivity_within_array_Z(datapath, dates, arrays, electrode, conditions, 'output_path', output)

% file plot
% weeks=[1,2,3]
% plotF1F5(weeks,0);

%% END