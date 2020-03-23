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


array = {'F1','F5hand'}; % ,'F5hand'
electrodes = 1:32;
event = 'whole_trial';
condition= {'fixation'};
weeks=[4:14 16:24 26];



%% loading data 

datapath = '/Users/quettier/Desktop/multiunit_binned_data/betta'; % data folder path
addpath('C:\Users\quettier\Documents\GitHub\tool_learning\src\matlab\spm12'); 



%% END