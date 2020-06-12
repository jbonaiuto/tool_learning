addpath('..');
exp_info=init_exp_info();

subject='betta';
array='F1';
conditions={'motor_grasp_right'};
dates={'11.03.19','13.03.19','14.03.19','15.03.19'};

%% Load and concatenate spike data
addpath('../spike_data_processing');
date_data={};
for i=1:length(dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dates{i},'multiunit','binned',...
        sprintf('fr_b_%s_%s_whole_trial.mat',array,dates{i})));
    data=rebin_spikes(data, 10);
    date_data{i}=data;
    clear('datafr');
end
data=concatenate_data(date_data, 'spike_times', false);
clear('date_data');

% Filter data - RTs too fast or slow
data=filter_data(exp_info,data,'plot_corrs',true);
% Compute dt
dt=(data.bins(2)-data.bins(1))/1000;
   
%% Figure out which trials to use and get trial data
trials=zeros(1,length(data.metadata.condition));
for i=1:length(conditions)
    trials = trials | (strcmp(data.metadata.condition,conditions{i}));
end
trials=find(trials);
trial_date=data.trial_date(trials);
cond_data=squeeze(data.binned_spikes(1,:,trials,:));

trial_spikes={};

max_n_bins=0;
%% Get trial spikes
for g = 1:length(trials)
    % Get binned spikes for this trial from time 0 to time of reward
    trial_idx = trials(g);
    bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(trial_idx))));
    trial_data=squeeze(cond_data(:,g,bin_idx));
    trial_spikes{end+1}=trial_data;
    max_n_bins=max([max_n_bins size(trial_data,2)]);
end
  
fid=fopen('week1_motor-grasp-right_10ms-bins.csv','w');
header='date,trial,electrode';
for i=1:max_n_bins
    header=sprintf('%s,%d',header,i);
end
fprintf(fid,'%s\n',header);
for i=1:length(dates)
    day_spikes=trial_spikes(trial_date==i);
    for j=1:length(day_spikes)
        trial=day_spikes{j};
        for k=1:size(trial,1)
            line=sprintf('%d,%d,%d',i,j,k);
            for l=1:max_n_bins
                if l<size(trial,2)
                    line=sprintf('%s,%d',line,trial(k,l));
                else
                    line=sprintf('%s,NA',line);
                end
            end
            fprintf(fid,'%s\n',line);
        end
    end
end
fclose(fid);