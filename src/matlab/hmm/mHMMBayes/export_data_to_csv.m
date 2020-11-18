function data=export_data_to_csv(exp_info, subject, array, conditions, dates, dt)

%% Load and concatenate spike data
addpath('../../spike_data_processing');

dbstop if error

date_data={};
for i=1:length(dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dates{i},'multiunit','binned',...
        sprintf('fr_b_%s_%s_whole_trial.mat',array,dates{i})));
    data.electrodes=[1,2,3,4,5,6,7,9,13,18,25,27,29,31,32];
    date_data{i}=data;
    clear('datafr');
end

data=concatenate_data(date_data, 'spike_times', false);
clear('date_data');

% Filter data - RTs too fast or slow
data=filter_data(exp_info,data,'plot_corrs',true,'thresh_percentile', 10);
data=rebin_spikes(data,dt);

% Use data from "good" electrodes
good_electrodes=[1,2,3,4,5,6,7,9,13,18,25,27,29,31,32];
data.binned_spikes=data.binned_spikes(:,good_electrodes,:,:);
data.binned_baseline_spikes=data.binned_baseline_spikes(:,good_electrodes,:,:);
data.smoothed_firing_rate=data.smoothed_firing_rate(:,good_electrodes,:,:);

   
%% Figure out which trials to use and get trial data
trials=zeros(1,length(data.metadata.condition));
for i=1:length(conditions)
    trials = trials | (strcmp(data.metadata.condition,conditions{i}));
end

trials=find(trials);
trial_date=data.trial_date(trials);
trial_condition=data.metadata.condition(trials);

cond_data=squeeze(data.binned_spikes(1,:,trials,:));

trial_spikes={};

max_n_bins=0;

%% Get trial spikes
for g = 1:length(trials)
    % Get binned spikes for this trial from time 0 to time of reward
    trial_idx = trials(g);
    bin_idx=find((data.bins>=0) & (data.bins<=(data.metadata.place(trial_idx)+150)));
    trial_data=squeeze(cond_data(:,g,bin_idx));
    trial_spikes{end+1}=trial_data;
    max_n_bins=max([max_n_bins size(trial_data,2)]);
end
  
fid=fopen('hmm_data.csv','w');
%header='date,trial,electrode,timestep,value';
header='date,condition,trial,electrode,timestep,value';
fprintf(fid,'%s\n',header);

%loop without conditions
% for i=1:length(dates)
%     day_spikes=trial_spikes(trial_date==i);
%     for j=1:length(day_spikes)
%         trial=day_spikes{j};
%         for k=1:size(trial,1)
%             for l=1:size(trial,2)
%                 line=sprintf('%d,%d,%d,%d,%d',i,j,k,l,trial(k,l));
%                 fprintf(fid,'%s\n',line);
%             end
%         end
%     end
% end

%loop with conditions
for i=1:length(dates)
    for m=1:length(conditions)
        day_condition=trial_condition(trial_date==i);
        day_condition_idx=strcmp(day_condition,conditions{m});
        day_condition_spikes=trial_spikes(day_condition_idx);
        for j=1:length(day_condition_spikes)
            trial=day_condition_spikes{j};
            for k=1:size(trial,1)
                for l=1:size(trial,2)
                    line=sprintf('%d,%d,%d,%d,%d,%d',i,m,j,k,l,trial(k,l));
                    fprintf(fid,'%s\n',line);
                end
            end
        end    
    end
end
fclose(fid);