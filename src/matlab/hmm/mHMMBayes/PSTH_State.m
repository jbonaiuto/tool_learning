% PSTH_State
addpath('../../');
exp_info=init_exp_info();
rmpath('../../');
% LOAD THE DATA WITH 1MS BIN SIZE
dt=1;
subject='betta';
array='F1';
%condition='motor_grasp_right';
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};

%state_nbr=5;
win_len=100;

dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
    '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19',...
    '13.03.19','14.03.19','15.03.19','18.03.19','19.03.19',...
    '20.03.19','21.03.19','25.03.19'};
    
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '5w_multiday_condHMM', array);

model=get_best_model(output_path, 'type', 'condition_covar');

load(fullfile(output_path,'data.mat'));
data10ms=data;

data_fname=fullfile(output_path,'data1ms.mat');
if exist(data_fname,'file')~=2
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
    data=remove_trials(concat_data,trials_to_remove);
    save(data_fname,'data','-v7.3');
else
    load(data_fname);
end

good_electrodes=[1,2,3,5,6,7,9,10,13,14,17,18,21,25,27,28,29,30,31,32];

%for each state
for state_nbr=1:model.n_states
    
    state=model.forward_probs.(sprintf('fw_prob_S%d',state_nbr));
    
    % For each condition
    for c_idx=1:length(conditions)

        f=figure();
        set(f, 'WindowState', 'maximized');
        condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
        trial_date=data.trial_date(condition_trials);
        
        % Go through each good electrode
        for elec_idx=1:length(good_electrodes)
            % Get the electrode number
            good_elect=good_electrodes(elec_idx);

            %subplot(4,8,elec_idx);
            subplot(3,7,elec_idx);

            % Spikes surrounding (before and after) each transition to this state
            % across all trials from all days
            StateElectrodeSpikes=[];

            % For every date
            for d=1:length(dates)
                % Find trials from this date for this condition
                day_trials=condition_trials(trial_date==d);
            
                % For each trial from this day in this condition
                for n=1:length(day_trials)
                
                    % Rows of forward probabilities for this trial
                    trial_rows=find((model.forward_probs.subj==day_trials(n)));
                    if strcmp(model.type,'multilevel')
                        trial_rows=find((model.forward_probs.subj==d) & (model.forward_probs.rm==n));
                    end
                    DayTrialSTATE=state(trial_rows);
                            
                    % Get the bins that we used in the HMM (time>0 and up to reward)
                    bin_idx=find((data10ms.bins>=0) & (data10ms.bins<=data10ms.metadata.reward(day_trials(n))));
                
                    % Offset state transition probabilities for this trial
                    offsetDayTrialSTATE = [DayTrialSTATE(2:end); NaN];
                    % Find where this state crosses threshold
                    DaySTATE_idx = find(DayTrialSTATE<0.5 & offsetDayTrialSTATE>0.5); % find a way to cut the state in consecutive time bin, find threshold (1, 2, 3 bin ?)

                    % For each threshold crossing
                    for i=1:length(DaySTATE_idx)
                        % Find the time (from the downsampled multiunit data) where the threshold is crossed
                        threshCrossIdx=DaySTATE_idx(i);
                        threshCrossTime=data10ms.bins(bin_idx(threshCrossIdx));

                        % WOI start and end time
                        start_time=threshCrossTime-50;
                        end_time=threshCrossTime+50;

                        % Find bins from non-downsampled data for the WOI
                        woi_bins=[knnsearch(data.bins',start_time):knnsearch(data.bins',end_time)];

                        % Add spikes from this WOI to list
                        woi_spikes_electrode=squeeze(data.binned_spikes(1,good_elect,day_trials(n),woi_bins));
                        StateElectrodeSpikes(end+1,:)=woi_spikes_electrode;
                    end
                end
            end
            bar([-50:dt:50],mean(StateElectrodeSpikes,1));
            hold all
            plot([0 0],ylim(),'r--');
            xlabel('Time (ms)');
            ylabel('Firing Rate');
            %ylim([0 0.08]);
            title(sprintf('Electrode %d', good_elect));   
        end
        condition_title=replace(conditions{c_idx},'_',' ');
        sgtitle(sprintf('State: %d      Condition: %s',state_nbr, condition_title));
            
        saveas(f,fullfile(exp_info.base_output_dir,'figures','HMM',subject,'psth', array,...
            [sprintf('State%d_%s_',state_nbr, conditions{c_idx}) '2w_MuldiDayMultiCond' '.png']));
        saveas(f,fullfile(exp_info.base_output_dir,'figures','HMM',subject,'psth', array,...
            [sprintf('State%d_%s_',state_nbr, conditions{c_idx}) '2w_MuldiDayMultiCond' '.eps']),'epsc');
    end
end