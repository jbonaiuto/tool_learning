function concat_data=export_data_to_csv_electrodeshuffle(exp_info, subject, array,...
    conditions, dates, dt, output_path, good_electrodes)

addpath('../../spike_data_processing');

shuffle_nbr=3;
  
for shuff_idx=1:shuffle_nbr
    %create csv file to exporte data
    data_file=fullfile(output_path, sprintf('hmm_data_electrodeshuffle_trials_%d.csv',shuff_idx));
    fid=fopen(data_file,'w');
    header='date,trial,condition,electrode,timestep,value';
    fprintf(fid,'%s\n',header);

    % Create a cell array with the data structure of each day to concatenate them
    % into one big structure
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
        data=filter_data(data);
        data=rebin_spikes(data,dt);

        % Save to cell array
        all_data{d_idx}=data;
    end

    %concatenate all the data structure per day in one big data structure for the period
    concat_data=concatenate_data(all_data, 'spike_times',false);
    clear all_data;

    % Figure out which trials to use
    condition_trials=zeros(1,length(concat_data.metadata.condition));
    for i=1:length(conditions)
        condition_trials = condition_trials | (strcmp(concat_data.metadata.condition,conditions{i}));
    end
    condition_trials=find(condition_trials);
    % Remove extra trials - makes the following bit a lot simpler
    all_trials=[1:length(concat_data.metadata.condition)];
    trials_to_remove=setdiff(all_trials,condition_trials);
    concat_data=remove_trials(concat_data,trials_to_remove);

    % Get trial spikes
    for trial_idx = 1:length(condition_trials)
        % Get binned spikes for this trial from time 0 to reward time
        bin_idx=find((concat_data.bins>=0) & (concat_data.bins<=concat_data.metadata.reward(trial_idx)));
%         shuff_idx=randperm(length(bin_idx));
%         shuff_bin_idx=bin_idx(:,shuff_idx);
        trial_spikes=squeeze(concat_data.binned_spikes(1,:,trial_idx,bin_idx));

        % Trial date index
        trial_date_idx=concat_data.trial_date(trial_idx);
        condition_idx=find(strcmp(conditions,concat_data.metadata.condition{trial_idx}));
        
        shuff_idx=randperm(length(good_electrodes));
        shuff_electrode_idx=good_electrodes(:,shuff_idx);
        
        %for electrode_idx=1:size(trial_spikes,1)
        for electrode_idx=1:length(good_electrodes)
            for time_idx=1:size(trial_spikes,2)
                time_spikes=trial_spikes(shuff_electrode_idx(electrode_idx),time_idx);
                line=sprintf('%d,%d,%d,%d,%d,%d',...
                    trial_date_idx,...
                    trial_idx,...
                    condition_idx,...
                    shuff_electrode_idx(electrode_idx),...
                    time_idx,...
                    time_spikes);
                fprintf(fid,'%s\n',line);
            end
        end
    end

    fclose(fid);
end