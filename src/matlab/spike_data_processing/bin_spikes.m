function data=bin_spikes(data, woi, binwidth, varargin)
% BIN_SPIKES Bin spikes of multiunit data
%
% Syntax: data=bin_spikes(data, woi, binwidth, 'baseline_evt', 'go',...
%                         'baseline_woi', [-500 0])
%
% Inputs:
%    data - structure containing data (created by load_multiunit_data)
%    woi - two element vector containing the time limits to bin spikes
%          within (in ms)
%    binwidth - width of each bin (in ms)
%
% Optional inputs:
%    baseline_evt - event type to align baseline to (go by default)
%    baseline_woi - two element vector containing the time limits to bin
%                   baseline spikes, relative to baseline_evt in ms 
%                   ([-500 0] by default)
%
% Outputs:
%    data - structure containing the following new fields:
%           bins - time of each bin
%           baseline_bins - time of each baseline bin
%           binned_spikes - arrays x electrodes x trials x bins matrix
%                           containing the number of spikes in each bin
%           binned_baseline_spikes - arrays x electrodes x trials x
%                                    baseline_bins matrix containing the
%                                    number of spikes in each baseline bin
% 
% Example:
%     data=bin_spikes(data, [-1000 2000], 20, 'baseline_evt', 'go',...
%                     'baseline_woi', [-500 0]);

%define default values
defaults = struct('baseline_evt','go', 'baseline_woi', [-500 0]);
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

tic

% Time of baseline event in each trial
baseline_evt_times=data.metadata.(params.baseline_evt);

% Add new fields to data
data.bins=[woi(1):binwidth:woi(2)];
data.baseline_bins=[params.baseline_woi(1):binwidth:params.baseline_woi(2)];
binned_spikes=zeros(length(data.arrays), length(data.electrodes),...
    data.ntrials, length(data.bins));
binned_baseline_spikes=zeros(length(data.arrays),...
    length(data.electrodes), data.ntrials, length(data.baseline_bins));

% Bin all spikes from all trials, electrodes, and arrays
[~,bin_idx]=histc(data.spikedata.time,data.bins);
% Realign spikes to baseline event times and bin all spikes from all
% trials, electrodes, and arrays
bc_aligned_spikes=data.spikedata.time-baseline_evt_times(data.spikedata.trial);
[~,baseline_bin_idx]=histc(bc_aligned_spikes,data.baseline_bins);

arrays=data.arrays;
spikedata_array=data.spikedata.array;
electrodes=data.electrodes;
spikedata_electrode=data.spikedata.electrode;
ntrials=data.ntrials;
spikedata_trial=data.spikedata.trial;

% For each array
for a_idx=1:length(data.arrays)
    % Find rows for this array in list of spikes
    array_idx=arrays(a_idx);
    array_rows=spikedata_array==array_idx;
    
    % For each electrode
    parfor e_idx=1:length(electrodes)
        
        electrode_binned_spikes=zeros(data.ntrials, length(data.bins));
        electrode_binned_baseline_spikes=zeros(data.ntrials, length(data.baseline_bins));
    
        % Find rows for this electrode in list of spikes
        electrode_rows=array_rows & spikedata_electrode==e_idx;
        
        % For each trial
        for t_idx=1:ntrials
            
            % Find rows for this trial in list of spikes
            trial_rows= electrode_rows & spikedata_trial==t_idx;
            
            % Add to binned_spikes based on bin_idx
            trial_bins=bin_idx(trial_rows);
            [uvals, ~, uidx] = unique(trial_bins(trial_bins>0)');
            electrode_binned_spikes(t_idx,uvals)=accumarray(uidx, 1);
            
            % Add to binned_baseline_spikes based on baseline_bin_idx
            trial_bins=baseline_bin_idx(trial_rows);
            [uvals, ~, uidx] = unique(trial_bins(trial_bins>0)');
            electrode_binned_baseline_spikes(t_idx,uvals)=accumarray(uidx, 1);
        end        
        binned_spikes(a_idx,e_idx,:,:)=electrode_binned_spikes;
        binned_baseline_spikes(a_idx,e_idx,:,:)=electrode_binned_baseline_spikes;
    end    
end
data.binned_spikes=binned_spikes;
data.binned_baseline_spikes=binned_baseline_spikes;

toc
