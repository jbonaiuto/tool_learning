%% Working script
%
%% Fixation task
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
condition= {'fixation'};
weeks=[4:14 16:24 26];


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

foldername = fullfile(parentdir,sprintf('trial_table_%s_%s.csv', condition{1},event));
csvwrite(foldername,table)

table=table(table(:,3)>0,:);
weeks=[table(:,1)];


for week_number = 1:length(weeks) 
dates = week(weeks(week_number)); 


foldername = sprintf('Week_%d_%s_%s', week_number,condition{1},event); 
  
newfolder = fullfile(parentdir, foldername);
    if ~exist(newfolder, 'dir')
       mkdir(newfolder)
    end
output = sprintf('%s/%s',parentdir,foldername);





%% function
func_connectivity_within_array(data_dir, dates, array, electrodes, condition,event, 'output_path', output)

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
%weeks=[1:14 16:24 26];
%plot_table(weeks,'visual_grasp_fix_on', 'input_path',parentdir, 'output_path',parentdir);

%% END