function state_trial_stats=extract_state_trial_stats(model, data, dates)

state_trial_stats.state_onsets={};
state_trial_stats.state_offsets={};
state_trial_stats.state_durations={};

all_t_idx=1;
thresh=0.9;

% Date index of each trial for this condition
trial_date=data.trial_date;
    
% For every date
for d=1:length(dates)
    % Find trials from this date for this condition
    day_trials=find(trial_date==d);
            
    % For each trial from this day in this condition
    for n=1:length(day_trials)
                
        % Rows of forward probabilities for this trial
        trial_rows=find((model.forward_probs.subj==day_trials(n)));
        if strcmp(model.type,'multilevel')
            trial_rows=find((model.forward_probs.subj==d) & (model.forward_probs.rm==n));
        end
                            
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data.bins>=0) & (data.bins<=data.metadata.reward(day_trials(n))));
        sub_bin_idx=find(data.bins(bin_idx)-data.metadata.go(day_trials(n))>=-500);
        trial_times=data.bins(bin_idx(sub_bin_idx));
        
        % Save p states within this window
        for i=1:model.n_states
            sprobs=model.forward_probs.(sprintf('fw_prob_S%d',i));
            trial_fwd_probs = sprobs(trial_rows);   
            
            trial_state_probs=trial_fwd_probs(sub_bin_idx);
            mask=(trial_state_probs>thresh);
            state_on=zeros(size(trial_state_probs));
            state_on(mask)=1;
            state_diff=diff([0; state_on; 0]);
            onsets=trial_times(find(state_diff==1));
            offsets=trial_times(find(state_diff==-1)-1);
            durations=offsets-onsets+(trial_times(2)-trial_times(1));
            state_trial_stats.state_onsets{i,all_t_idx}=onsets;
            state_trial_stats.state_offsets{i,all_t_idx}=offsets;
            state_trial_stats.state_durations{i,all_t_idx}=durations;
        end
        all_t_idx=all_t_idx+1;
    end
end
