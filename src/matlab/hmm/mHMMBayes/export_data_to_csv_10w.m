function data=export_data_to_csv_10w(exp_info, subject, array, conditions, dates, dt, output_path)

%% Load and concatenate spike data
addpath('../../spike_data_processing');

dbstop if error

data_file=fullfile(output_path, 'hmm_data.csv');
    fid=fopen(data_file,'w');
    header='date,trial,condition,electrode,timestep,value';
    fprintf(fid,'%s\n',header);

anchor=0;
anchor_length=0;

for d_idx=1:length(dates)
    date=dates{d_idx};

    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        date,'multiunit','binned',...
        sprintf('fr_b_%s_%s_whole_trial.mat',array,date)));
    data.electrodes=[1,2,3,4,5,6,7,9,13,18,25,27,29,31,32];

    data.trial_date=ones(1,data.ntrials);

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
  

    % fid=fopen('hmm_data.csv','w');
    % header='date,trial,electrode,timestep,value';
    % fprintf(fid,'%s\n',header);
    % 
    % %loop without conditions
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
    
    if d_idx==1
        for j=1:length(trial_spikes)
            trial=trial_spikes{j};
            condition_idx=find(strcmp(conditions,trial_condition{j}));
            for k=1:size(trial,1)
                for l=1:size(trial,2)
                    line=sprintf('%d,%d,%d,%d,%d,%d',1,j,condition_idx,k,l,trial(k,l));
                    fprintf(fid,'%s\n',line);
                    
                 end
            end
        anchor_length=anchor_length+1;
        end
    anchor = anchor_length;
    else
    anchor_length=0;
        for j=1:length(trial_spikes)
            trial=trial_spikes{j};
            condition_idx=find(strcmp(conditions,trial_condition{j}));
            j=j+anchor;
            for k=1:size(trial,1)
                for l=1:size(trial,2)
                    line=sprintf('%d,%d,%d,%d,%d,%d',1,j,condition_idx,k,l,trial(k,l));
                    fprintf(fid,'%s\n',line);
                 end
            end 
        anchor_length=anchor_length+1;
        end
    anchor = anchor + anchor_length;  
    end

end
fclose(fid);
