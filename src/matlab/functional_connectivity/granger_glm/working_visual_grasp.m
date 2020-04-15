%% Working script
%
%% Visual grasping task
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

array = {'F1'}; % ,'F5hand'
electrodes = 1:2;
event = 'whole_trial';
condition= {'visual_grasp_left','visual_grasp_right'};
condition_name = 'visual_grasp';
weeks=[1:14 16:24 26];



%% loading data 

data_dir = '/Users/thomasquettier/Desktop/multiunit_binned_data/betta'; % data folder path
addpath('/Users/thomasquettier/Documents/GitHub/tool_learning/src/matlab/spm12'); 
parentdir = '/Users/thomasquettier/Desktop/multiunit_binned_data/output/functional_connectivity';


 %% week selection
 

table = zeros(length(weeks),5);
for week_number = 1:length(weeks)  
date = week(weeks(week_number));   
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

foldername = fullfile(parentdir,sprintf('%s_%s_table.csv', condition_name,event));
csvwrite(foldername,table)

table=table(table(:,3)>0,:);
weeks=[table(:,1)];

%% function
for week_number = 1:length(weeks) 
dates = week(weeks(week_number)); 


foldername = sprintf('Week_%d_%s_%s', week_number,condition_name,event); 
  
newfolder = fullfile(parentdir, foldername);
    if ~exist(newfolder, 'dir')
       mkdir(newfolder)
    end
output = sprintf('%s/%s',parentdir,foldername);

func_connectivity_within_array(data_dir, dates, array, electrodes, condition,event, 'output_path', output)

end

%file plot

plot_table(weeks,sprintf('%s_%s',condition_name,event), 'input_path',parentdir, 'output_path',parentdir);

%% END