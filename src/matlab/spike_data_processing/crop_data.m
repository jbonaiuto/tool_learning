function cropped_data=crop_data(data, array_idx)

% Empty structure to store concatenated data (from all trials)
cropped_data=[];
cropped_data.dates=data.dates;
cropped_data.subject=data.subject;
cropped_data.arrays=[array_idx];
cropped_data.electrodes=data.electrodes;
cropped_data.ntrials=data.ntrials;
if isfield(data,'spikedata')
    cropped_data.spikedata=[];
    array_rows=find(data.spikedata.array==array_idx);
    cropped_data.spikedata.date=data.spikedata.date(array_rows);
    cropped_data.spikedata.trial=data.spikedata.trial(array_rows);
    cropped_data.spikedata.rel_trial=data.spikedata.rel_trial(array_rows);
    cropped_data.spikedata.time=data.spikedata.time(array_rows);
    cropped_data.spikedata.array=data.spikedata.array(array_rows);
    cropped_data.spikedata.electrode=data.spikedata.electrode(array_rows);
end
cropped_data.metadata=data.metadata;
if isfield(data,'bins')
    cropped_data.bins=data.bins;
    cropped_data.baseline_bins=data.baseline_bins;
    cropped_data.binned_spikes=data.binned_spikes(array_idx, :, :, :);
    cropped_data.binned_baseline_spikes=data.binned_baseline_spikes(array_idx, :, :, :);
    cropped_data.firing_rate=data.firing_rate(array_idx, :, :, :);
    cropped_data.baseline_type=data.baseline_type;
    cropped_data.smoothed_firing_rate=data.smoothed_firing_rate(array_idx, :, :, :);
end