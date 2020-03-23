%% Working script
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
period = 'fix_on';
test=1; %git test
condition =0; % 1: motor, 0: visual

%% loading data 

datapath = '/Users/quettier/Desktop/multiunit_binned_data/betta'; % data folder path
addpath('C:\Users\quettier\Documents\GitHub\tool_learning\src\matlab\spm12'); 


%% saving data
for week_number = 1:2
dates = week(week_number); 

parentdir = '/Users/quettier/Desktop/multiunit_binned_data/output/functional_connectivity';
 if condition == 1
        foldername = sprintf('Week_%d_motor_%s', week_number,period); 
    elseif condition == 0      
        foldername = sprintf('Week_%d_visual_%s',week_number,period);
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

func_connectivity_within_array(datapath, dates, arrays, electrode, conditions,period, 'output_path', output)

end
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
weeks=[1:14 16:24];
weeks=[1:2];
plot_table(weeks,'visual_fix_on', 'input_path',parentdir, 'output_path',parentdir);

%% END