function concat_data=export_data_to_csv_10w(exp_info, subject, array, conditions, dates, dt, output_path)

% 
%OUTPUT: 
%concat_data : concatenated data strucures of several days to have
%              a data structure for the period of interest 
%
%INPUTS :
%
%

addpath('../../spike_data_processing');
dbstop if error

%create csv file to exporte data
data_file=fullfile(output_path, 'hmm_data.csv');
fid=fopen(data_file,'w');
header='date,trial,condition,electrode,timestep,value';
fprintf(fid,'%s\n',header);

%create a cell array with a data strcuture of each day to concatenate them one big structure
all_data={};

for d_idx=1:length(dates)
    date=dates{d_idx};
    
    % Load and concatenate spike data
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        date,'multiunit','binned',...
        sprintf('fr_b_%s_%s_whole_trial.mat',array,date)));
    
    %create a vector of 1 with the length equal to number of the trail of the day for this condition
    data.trial_date=ones(1,data.ntrials);
    
    % Filter data - RTs too fast or slow
    data=filter_data(exp_info,data,conditions,'plot_corrs',true,'thresh_percentile', 10);
    data=rebin_spikes(data,dt);
    
    % Isn't it useless?
    data.binned_spikes=data.binned_spikes(:,:,:,:);
    data.binned_baseline_spikes=data.binned_baseline_spikes(:,:,:,:);
    data.smoothed_firing_rate=data.smoothed_firing_rate(:,:,:,:);
    
    %export the csv file just for the first loop in runHMM_grasp_10w (i=1:length(dates)
    all_data{d_idx}=data;
end

%concatenate all the data structure per day in one big data structure for the period
concat_data=concatenate_data(all_data, 'spike_times',false);
clear all_data;

% Figure out which trials to use and get trial data
trials=zeros(1,length(concat_data.metadata.condition));

for i=1:length(conditions)
    trials = trials | (strcmp(concat_data.metadata.condition,conditions{i}));
end

%identify trial's date and condition
trials=find(trials);
trial_date=concat_data.trial_date(trials);
trial_condition=concat_data.metadata.condition(trials);

cond_data=squeeze(concat_data.binned_spikes(1,:,trials,:));

trial_spikes={};

max_n_bins=0;

% Get trial spikes
for g = 1:length(trials)
    % Get binned spikes for this trial from time 0 to time of reward
    trial_idx = trials(g);
    bin_idx=find((concat_data.bins>=0) & (concat_data.bins<=(concat_data.metadata.place(trial_idx)+150)));
    trial_data=squeeze(cond_data(:,g,bin_idx));
    trial_spikes{end+1}=trial_data;
    %I don't understand max_n_bins purpose
    max_n_bins=max([max_n_bins size(trial_data,2)]);
end

% fill hmm_data.csv file with binned spikes for each electrodes, trials, days
for d_idx=1:length(dates)
    date_trials=find(trial_date==d_idx);
    for j=1:length(date_trials)
        trial=trial_spikes{date_trials(j)};
        condition_idx=find(strcmp(conditions,trial_condition{date_trials(j)}));
        for k=1:size(trial,1)
            for l=1:size(trial,2)
                line=sprintf('%d,%d,%d,%d,%d,%d',d_idx,j,condition_idx,k,l,trial(k,l));
                fprintf(fid,'%s\n',line);
            end
        end
    end
end

fclose(fid);
