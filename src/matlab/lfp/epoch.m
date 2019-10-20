function epoch_data=epoch(exp_info, data, evt, limits, conditions, varargin)

% Parse optional arguments
defaults=struct('exclude_bad_trials',true);
params=struct(varargin{:});
for f=fieldnames(defaults)',
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

evt_idx=find(strcmp(exp_info.event_types,evt));

% Epoched data
epoch_data.label=data.label;
epoch_data.fsample=data.fsample;
epoch_data.time={};
epoch_data.trial={};
epoch_data.trialinfo=[];

trials_to_use=[1:length(data.trial)];
if ~strcmp(conditions,'all')
    trials_to_use=[];
    for i=1:length(conditions)
        cond_idx=find(strcmp(exp_info.conditions,conditions{i}));
        trials_to_use=union(trials_to_use, find(data.trialinfo(:,1)==cond_idx));
    end
end
if params.exclude_bad_trials
    trials_to_use=intersect(trials_to_use,find(data.trialinfo(:,2)==1));
end

for i=1:length(trials_to_use)
    t=trials_to_use(i);
    trial_data=data.trial{t};
    if ~isnan(data.trialinfo(t,evt_idx+2))
        zeroed_times=data.time{t}-data.trialinfo(t,evt_idx+2);
        if zeroed_times(1)>limits(1) || zeroed_times(end)<limits(2)
            disp(sprintf('Limits out of bounds for trial %d, %.2f-%.2f', t, zeroed_times(1), zeroed_times(end)));
        else
            idx=intersect(find(zeroed_times>=limits(1)),find(zeroed_times<=limits(2)));
            epoch_data.time{end+1}=zeroed_times(idx);
            epoch_data.trial{end+1}=trial_data(:,idx);
            epoch_data.trialinfo(end+1,:)=data.trialinfo(t,:);
            epoch_data.trialinfo(end,3:end)=epoch_data.trialinfo(end,3:end)-data.trialinfo(t,evt_idx+2);
        end
    end
end