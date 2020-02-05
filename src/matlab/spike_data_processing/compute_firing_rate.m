function data=compute_firing_rate(data, varargin)
% COMPUTE_FIRING_RATE Compute baseline-corrected and smoothed firing rates
% based on binned multiunit data. bin_spikes must have been already called
% on the data structure.
%
% Syntax: data=compute_firing_rate(data, 'baseline_type', 'condition',...
%                                  'win_len', 6)
%
% Inputs:
%    data - structure containing data (created by load_multiunit_data)
%
% Optional inputs:
%    baseline_type - 'trial', 'condition', or 'global' baseline correction.
%                    (condition by default)
%                    trial = baseline correct each trial based on spikes
%                            during the baseline period in that trial
%                    condition = baseline correct each trial based on the
%                                mean number of spikes during the baseline
%                                period over all trials in that condition
%                    global = baseline correct each trial based on the mean
%                             number of spikes during the baseline period
%                             over all trials in all conditions
%    win_len - length of the Gaussian window for smoothing (6 by default)
%
% Outputs:
%    data - structure containing the following new fields:
%           baseline_type - type of baseline correction applied
%           firing_rate - arrays x electrodes x trials x bins matrix
%                         containing the baseline-corrected firing rate in 
%                         each time bin
%           smoothed_firing_rate - arrays x electrodes x trials x bins matrix
%                         containing the smoothed baseline-corrected firing
%                         rate in each time bin
% 
% Example:
%     data=compute_firing_rate(data, 'baseline_type', 'condition',...
%                              'win_len', 6);

%define default values
defaults = struct('baseline_type','condition','win_len',6);  
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

% Convert binned spikes to firing rate
data.firing_rate=data.binned_spikes./((data.bins(2)-data.bins(1))/1000);

%% Baseline correct
data.baseline_type=params.baseline_type;

% Trial-specific baseline
if strcmp(params.baseline_type,'trial')
    % Number of spikes during the baseline period in each trial
    trial_baseline_spikes=sum(data.binned_baseline_spikes,4);
    % Convert number of baseline spikes to firing rate
    trial_baseline_rate=trial_baseline_spikes./((data.baseline_bins(end)-data.baseline_bins(1))/1000);
    % Baseline-correct each trial
    trial_baseline_rep=repmat(trial_baseline_rate,1,1,1,size(data.firing_rate,4));    
    data.firing_rate=(data.firing_rate-trial_baseline_rep)./trial_baseline_rep;                                

% Condition-specific baseline
elseif strcmp(params.baseline_type,'condition')
    
    % Do separately for each condition
    unique_conditions=unique(data.metadata.condition);
    for c_idx=1:length(unique_conditions)
        condition=unique_conditions{c_idx};
        % Find all trials for this condition
        condition_trials=find(strcmp(data.metadata.condition,condition));        
        % Number of spikes during baseline period in each trial in this
        % condition
        condition_baseline_spikes=sum(data.binned_baseline_spikes(:,:,condition_trials,:),4);
        % Convert number of baseline spikes to firing rate
        condition_baseline_rate=condition_baseline_spikes/((data.baseline_bins(end)-data.baseline_bins(1))/1000);
        % Average over all trials in this condition
        condition_baseline_mean_rate=mean(condition_baseline_rate,3);
        % Baseline-correct each trial in this condition
        condition_baseline_rep=repmat(condition_baseline_mean_rate,[1,1,length(condition_trials),size(data.firing_rate,4)]);
        data.firing_rate(:,:,condition_trials,:)=(data.firing_rate(:,:,condition_trials,:)-condition_baseline_rep)./condition_baseline_rep;                  
    end
    
% Global baseline
elseif strcmp(params.baseline_type,'global')
    % Number of spikes during baseline period in each trial over all
    % conditions
    baseline_spikes=sum(data.binned_baseline_spikes,4);
    % Convert number of baseline spikes to firing rate
    baseline_rate=baseline_spikes./((data.baseline_bins(end)-data.baseline_bins(1))/1000);
    % Average over all trials
    baseline_mean_rate=mean(baseline_rate,3);
    % Baseline-correct each trial
    baseline_rep=repmat(baseline_mean_rate,[1,1,size(data.firing_rate,3),size(data.firing_rate,4)]);    
    data.firing_rate=(data.firing_rate-baseline_rep)./baseline_rep;    
end

% Smooth each trial firing rate using Gaussian filter
data.win_len=params.win_len;
data.smoothed_firing_rate=zeros(size(data.firing_rate));
w=gausswin(params.win_len);
for a_idx=1:size(data.firing_rate,1)
    for e_idx=1:size(data.firing_rate,2)
        for t_idx=1:size(data.firing_rate,3)
            data.smoothed_firing_rate(a_idx,e_idx,t_idx,:)=filter(w,1,squeeze(data.firing_rate(a_idx,e_idx,t_idx,:)));
        end
    end
end
