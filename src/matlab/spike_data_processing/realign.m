function data=realign(data, evt)
% REALIGN Realigns data based on the timing of a particular event
%
% Syntax: data=realign(data, evt);
%
% Inputs:
%    data - structure containing data (created by load_multiunit_data)
%    evt - name of the event to realign to
%
% Outputs:
%    data - data structure containing realigned data
%
% Example:
%     data=realign(data, 'hand_mvmt_onset');

% Realign times for each trial
evt_data=data.metadata.(evt);
evt_data(isnan(evt_data))=0;

% Realign times for each spike
trial_evts=evt_data(data.spikedata.trial);

% Realign spike times
data.spikedata.time=data.spikedata.time-trial_evts;

% Realign time of other events
for e_idx=1:length(data.metadata.event_types)
    event_type=data.metadata.event_types{e_idx};
    if ~strcmp(event_type,evt)
        data.metadata.(event_type)=data.metadata.(event_type)-evt_data;
    end
end
% Realign time of align event
data.metadata.(evt)=data.metadata.(evt)-evt_data;