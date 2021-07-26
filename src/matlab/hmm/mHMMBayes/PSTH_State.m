% PSTH_State
addpath('../../');
exp_info=init_exp_info();
rmpath('../../');
% LOAD THE DATA WITH 1MS BIN SIZE
dt=10;
subject='betta';
array='F1';
condition='motor_grasp_right';
%conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};

state_nbr=5;
win_len=100;

dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
    '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19'};

output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '2w_multiday_condHMM', array);

model=get_best_model(output_path, 'type', 'condition_covar');

load(fullfile(output_path,'data.mat'));

% Read data from each day in week 4
date_data={};

state=model.forward_probs.(sprintf('fw_prob_S%d',state_nbr));

loop_idx=0;

figure()

% For each condition
%for c_idx=1:length(conditions)

    %condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
    condition_trials = find(strcmp(data.metadata.condition,condition));

    % Go through each good electrode
    % WE ARE NOT USING ALL 32 ELECTRODES NOW - SEE R code
    for elec_idx=1:length(data.electrodes)
        % Get the electrode number
        good_elect=data.electrodes(elec_idx);

        subplot(4,8,elec_idx);

        % Spikes surrounding (before and after) each transition to this state
        % across all trials from all days
        StateElectrodeSpikes=[];

        % Go through each day
        for d_idx=1:length(dates)
            
            % Trials in the multiunit data corresponding to this day
            day_trials=find(data.trial_date==d_idx);
            day_cond_trials=zeros(1,length(day_trials));
                
            for dt_idx=1:length(day_trials)
                for ct_idx=1:length(condition_trials)
                    if day_trials(dt_idx)==condition_trials(ct_idx)
                        day_cond_trials(dt_idx)=day_trials(dt_idx);
                    end
                end
            end
            day_cond_trials=nonzeros(day_cond_trials)';
            
            % Go through each trial in this day
            
            for t_idx=min(day_cond_trials):max(day_cond_trials)
                if ismember(t_idx,day_cond_trials)==0
                    continue
                else
                    TOI_idx=find(day_cond_trials==t_idx);
                    % Forward probability rows for this trial
                    DayTrial_idx = find(model.forward_probs.subj==day_cond_trials(TOI_idx));
                    % State transition probabilties for this trial
                    DayTrialSTATE=state(DayTrial_idx);
                    % Offset state transition probabilities for this trial
                    offsetDayTrialSTATE = [DayTrialSTATE(2:end); NaN];
                    % Find where this state crosses threshold
                    DaySTATE_idx = find(DayTrialSTATE<0.5 & offsetDayTrialSTATE>0.5); % find a way to cut the state in consecutive time bin, find threshold (1, 2, 3 bin ?)

                    % For each threshold crossing
                    for i=1:length(DaySTATE_idx)
                        % Find the time (from the downsampled multiunit data) where the threshold is crossed
                        threshCrossIdx=DaySTATE_idx(i);
                        % THIS IS NOT THE RIGHT BIN IDX - SEE
                        % EXPORT_DATA_TO_CSV
                        bin_idx=find((data.bins>=0) & (data.bins<=(data.metadata.place(day_cond_trials(TOI_idx))+150)));
                        threshCrossTime=data.bins(bin_idx(threshCrossIdx));

                        % WOI start and end time
                        start_time=threshCrossTime-50;
                        end_time=threshCrossTime+50;

                        % Find bins from non-downsampled data for the WOI
                        woi_bins=[knnsearch(data.bins',start_time):knnsearch(data.bins',end_time)];
                        
                        % Add spikes from this WOI to list
                        %woi_spikes_electrode=squeeze(data.binned_spikes(1,good_elect,day_trials(t_idx),woi_bins));
                        woi_spikes_electrode=squeeze(data.binned_spikes(1,good_elect,day_cond_trials(TOI_idx),woi_bins));
                        StateElectrodeSpikes(end+1,:)=woi_spikes_electrode;
                    end
                    %something is missing here to have the trial equivalent
                    %of stateElectrodeSpikes. I don't undetstand why the 
                    %StateElectrodeSpike doesn'tsrc/ concatenate the threshold crossing, the trials and the day 
                end
            end
        end
        %bar([-50:50],mean(StateElectrodeSpikes));
        bar([-50:dt:50],mean(StateElectrodeSpikes,1));
        hold all
        plot([0 0],ylim(),'r--');
        xlabel('Time (ms)');
        ylabel('Firing Rate');
        title(sprintf('Electrode %d', good_elect));
        condition_title=replace(condition,'_',' ');
        %sgtitle(sprintf('State: %d      Condition: %s',state_nbr, condition_title));
    end
%end