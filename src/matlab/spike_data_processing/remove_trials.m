function data=remove_trials(data, bad_trials)

% Figure out good trials
good_trials=setdiff([1:data.ntrials],unique(bad_trials));

% Create list of new trial numbers (NaN for bad trials)
new_trials=[1:data.ntrials];
new_trials(bad_trials)=nan;
new_trials(~isnan(new_trials))=[1:data.ntrials-length(bad_trials)];

% Update number of trials
data.ntrials=data.ntrials-length(bad_trials);
data.trial_date=data.trial_date(good_trials);

% Remove bad trials from metadata
for evt_idx=1:length(data.metadata.event_types)
    evt_type=data.metadata.event_types{evt_idx};
    event_data=data.metadata.(evt_type);
    event_data(bad_trials)=[];
    data.metadata.(evt_type)=event_data;
end
data.metadata.condition(bad_trials)=[];

% Remove spike data from bad trials
if isfield(data,'spikedata')
    good_spikes=find(ismember(data.spikedata.trial,good_trials));
    data.spikedata.time=data.spikedata.time(good_spikes);
    data.spikedata.array=data.spikedata.array(good_spikes);
    data.spikedata.electrode=data.spikedata.electrode(good_spikes);
    data.spikedata.trial=data.spikedata.trial(good_spikes);
    data.spikedata.trial=new_trials(data.spikedata.trial);
end

% Remove binned data from bad trials
if isfield(data,'binned_spikes')
    data.binned_spikes=data.binned_spikes(:,:,good_trials,:);
end
if isfield(data,'binned_baseline_spikes')
    data.binned_baseline_spikes=data.binned_baseline_spikes(:,:,good_trials,:);
end

% Remove firing rate data from bad trials
if isfield(data,'firing_rate')
    data.firing_rate=data.firing_rate(:,:,good_trials,:);
end
if isfield(data,'smoothed_firing_rate')
    data.smoothed_firing_rate=data.smoothed_firing_rate(:,:,good_trials,:);
end
