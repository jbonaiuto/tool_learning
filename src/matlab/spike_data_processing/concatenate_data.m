function concat_data=concatenate_data(data, varargin)

% Parse optional arguments
defaults=struct('spike_times',true);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end


spm('defaults','eeg');

% Empty structure to store concatenated data (from all trials)
concat_data=[];
concat_data.dates={};
concat_data.subject=data{1}.subject;
concat_data.arrays=data{1}.arrays;
concat_data.electrodes=data{1}.electrodes;
concat_data.ntrials=0;
if params.spike_times
    concat_data.spikedata=[];
    concat_data.spikedata.date=[];
    concat_data.spikedata.trial=[];
    concat_data.spikedata.rel_trial=[];
    concat_data.spikedata.time=[];
    concat_data.spikedata.array=[];
    concat_data.spikedata.electrode=[];
end
concat_data.metadata=[];
concat_data.metadata.event_types=data{1}.metadata.event_types;
concat_data.metadata.condition={};
concat_data.metadata.trial_start=[];
concat_data.metadata.fix_on=[];
concat_data.metadata.go=[];
concat_data.metadata.hand_mvmt_onset=[];
concat_data.metadata.tool_mvmt_onset=[];
concat_data.metadata.obj_contact=[];
concat_data.metadata.place=[];
concat_data.metadata.reward=[];
concat_data.bins=data{1}.bins;
concat_data.baseline_bins=data{1}.baseline_bins;
concat_data.binned_spikes=[];
concat_data.binned_baseline_spikes=[];
concat_data.firing_rate=[];
concat_data.baseline_type=data{1}.baseline_type;
concat_data.smoothed_firing_rate=[];

trial_offset=0;

for i=1:length(data)
    curr_data=data{i};
    if curr_data.ntrials>0        
        if params.spike_times
            n_spikes=length(curr_data.spikedata.date);
            concat_data.spikedata=[];
            concat_data.spikedata.date(end+1:end+n_spikes)=curr_data.spikedata.date;
            concat_data.spikedata.trial(end+1:end+n_spikes)=curr_data.spikedata.trial+trial_offset;
            trial_offset=trial_offset+curr_data.ntrials;
            concat_data.spikedata.rel_trial(end+1:end+n_spikes)=curr_data.spikedata.rel_trial;
            concat_data.spikedata.time(end+1:end+n_spikes)=curr_data.spikedata.time;
            concat_data.spikedata.array(end+1:end+n_spikes)=curr_data.spikedata.array;
            concat_data.spikedata.electrode(end+1:end+n_spikes)=curr_data.spikedata.electrode;
        end
        concat_data.metadata.trial_start(end+1:end+curr_data.ntrials)=curr_data.metadata.trial_start;
        concat_data.metadata.fix_on(end+1:end+curr_data.ntrials)=curr_data.metadata.fix_on;
        concat_data.metadata.go(end+1:end+curr_data.ntrials)=curr_data.metadata.go;
        concat_data.metadata.hand_mvmt_onset(end+1:end+curr_data.ntrials)=curr_data.metadata.hand_mvmt_onset;
        concat_data.metadata.tool_mvmt_onset(end+1:end+curr_data.ntrials)=curr_data.metadata.tool_mvmt_onset;
        concat_data.metadata.obj_contact(end+1:end+curr_data.ntrials)=curr_data.metadata.obj_contact;
        concat_data.metadata.place(end+1:end+curr_data.ntrials)=curr_data.metadata.place;
        concat_data.metadata.reward(end+1:end+curr_data.ntrials)=curr_data.metadata.reward;
        concat_data.metadata.condition(end+1:end+curr_data.ntrials)=curr_data.metadata.condition;
           
        concat_data.binned_spikes(:,:,concat_data.ntrials+1:concat_data.ntrials+curr_data.ntrials,:)=curr_data.binned_spikes;     
        concat_data.binned_baseline_spikes(:,:,concat_data.ntrials+1:concat_data.ntrials+curr_data.ntrials,:)=curr_data.binned_baseline_spikes;     
        concat_data.firing_rate(:,:,concat_data.ntrials+1:concat_data.ntrials+curr_data.ntrials,:)=curr_data.firing_rate;     
        concat_data.smoothed_firing_rate(:,:,concat_data.ntrials+1:concat_data.ntrials+curr_data.ntrials,:)=curr_data.smoothed_firing_rate;     
        
        concat_data.ntrials=concat_data.ntrials+curr_data.ntrials;
        
    end   
end
