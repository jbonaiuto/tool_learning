function data=filter_data(data)
% FILTER_DATA Filters data by removing trials based on some criteria
% (currently trials with RT <200 or >1000ms)
%
% Syntax: data=filter_data(data);
%
% Inputs:
%    data - structure containing data (created by load_multiunit_data)
%
% Outputs:
%    data - data structure containing filtered data
%
% Example:
%     data=filter_data(data);

% Figure out RT of each trial
rts=data.metadata.hand_mvmt_onset-data.metadata.go;

% Bad trials where RT<200 or >1000
bad_trials=union(find(rts<200),find(rts>1000));
good_trials=setdiff([1:data.ntrials],bad_trials);

% Create list of new trial numbers (NaN for bad trials)
new_trials=[1:data.ntrials];
new_trials(bad_trials)=nan;
new_trials(~isnan(new_trials))=[1:data.ntrials-length(bad_trials)];

% Update number of trials
data.ntrials=data.ntrials-length(bad_trials);

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
    spike_rts=rts(data.spikedata.trial);
    bad_spikes=union(find(spike_rts<200),find(spike_rts>1000));
    data.spikedata.trial(bad_spikes)=[];
    data.spikedata.time(bad_spikes)=[];
    data.spikedata.array(bad_spikes)=[];
    data.spikedata.electrode(bad_spikes)=[];
    data.spikedata.trial=new_trials(data.spikedata.trial);
end
if isfield(data,'binned_spikes')
    data.binned_spikes=data.binned_spikes(:,:,good_trials,:);
end
if isfield(data,'binned_baseline_spikes')
    data.binned_baseline_spikes=data.binned_baseline_spikes(:,:,good_trials,:);
end
if isfield(data,'firing_rate')
    data.firing_rate=data.firing_rate(:,:,good_trials);
end
if isfield(data,'smoothed_firing_rate')
    data.smoothed_firing_rate=data.smoothed_firing_rate(:,:,good_trials);
end