%% CSV file for R
%
% Thomas Quettier

clear all


destination_dir = '/Users/thomasquettier/Desktop/latex report'; % set where you want to creat the .CSV



load weeks.mat
csvwrite(fullfile(destination_dir,'available_weeks.csv'),daylist) %cf update_dataset.m


% End