%% trials info
%
% get information from trials
%
%% Thomas Quettier 

clc
clear all
close all

%% Parameters

arrays = {'F1','F5hand'}; 
electrode = 1:32;
period = 'fix_on';
condition =0; % 1: motor, 0: visual

%% loading data 

datapath = '/Users/thomasquettier/Desktop/multiunit_binned_data/output/functional_connectivity'; % data folder path
addpath('../../spike_data_processing'); 

weeks=[1:14 16:24 26];
table = zeros(length(weeks),7);

for week_number = 1:length(weeks)

 if condition == 1
        foldername = sprintf('Week_%d_motor_grasp_%s', weeks(week_number),period); 
        cond = 'motor';
    elseif condition == 0      
        foldername = sprintf('Week_%d_visual_grasp_%s',weeks(week_number),period);
        cond = 'visual';
    end

date = week(weeks(week_number)); 




%data
load(fullfile(datapath, foldername,sprintf('granger_glm_results.mat')));
[CHN SMP TRL] = size(granger_glm_results.X);
X=granger_glm_results.X(:,:,:);

size_trial = zeros(1,TRL);
for itrial = 1:TRL
size_trial(itrial) = length(find(~isnan(X(1,:,itrial))));
end

table(weeks(week_number), 1) = weeks(week_number);
%table(week_number, 2) = cond;
%table(week_number, 3) = period;
table(weeks(week_number), 4) = min(size_trial);
table(weeks(week_number), 5) = max(size_trial);
table(weeks(week_number), 6) = mean(size_trial);
table(weeks(week_number), 7) = TRL;


end

foldername = fullfile(datapath,sprintf('trial_table_%s_%s.csv', cond,period));
csvwrite(foldername,table)

