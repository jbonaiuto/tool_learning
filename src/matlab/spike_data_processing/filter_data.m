function data=filter_data(exp_info, data, varargin)
% FILTER_DATA Filters data by removing trials based on some criteria
% (currently trials with RT <200 or >1000ms, or correlations less than 10%
% of the correlation range for that condition)
%
% Syntax: data=filter_data(exp_info, data, varargin);
%
% Inputs:
%    exp_info - experimental info data structure (created with
%               init_exp_info.m)
%    data - structure containing data (created by load_multiunit_data)
%
% Optional inputs:
%    min_rt - minimum response time in  ms (excluding fixation; 
%             default=200)
%    max_rt - maximum response time in ms (excluding fixation;
%             default=1000)
%    thresh_percentile - percentile of the correlation range to use as the
%                        threshold (default=10)
%    plot_corrs - whether or not to plot the correlation distribution and
%                 computed threshold (default=false)
%
% Outputs:
%    data - data structure containing filtered data
%
% Example:
%     data=filter_data(data);

defaults = struct('min_rt',200,'max_rt',1000,'max_obj_contact',5000,...
    'thresh_percentile', 10, 'plot_corrs', false);  %define default values
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

% Figure out RT of each trial
rts=data.metadata.hand_mvmt_onset-data.metadata.go;

bad_trials=[];
% if length(conditions)
%     condition_trials=zeros(1,length(data.metadata.condition));
%     for i=1:length(conditions)
%         condition_trials = condition_trials | (strcmp(data.metadata.condition,conditions{i}));
%     end
%     condition_trials=find(condition_trials);
%     bad_trials=setdiff([1:length(data.metadata.condition)],condition_trials);
% end
% 
% Bad trials where RT<200 or >1000
rt_bad_trials=union(find(rts<params.min_rt),find(rts>params.max_rt));

disp(sprintf('Removing %d trials based on RT', length(rt_bad_trials)));
bad_trials=union(bad_trials,rt_bad_trials);

oc_bad_trials=find(data.metadata.obj_contact>=params.max_obj_contact);
disp(sprintf('Removing %d trials based on object contact', length(oc_bad_trials)));

bad_trials=union(bad_trials, oc_bad_trials);

% Find trials with correlations less than threshold
corr_bad_trials=[];

% Go through each condition
conditions=unique(data.metadata.condition);
for cond_idx=1:length(conditions)
    condition=conditions{cond_idx};
    if find(strcmp(conditions,condition))    
        % File containing correlations for this condition
        corr_file=fullfile(exp_info.base_data_dir,'preprocessed_data',...
            data.subject,sprintf('corr_days_F1_F5hand_%s.mat',condition));

        % If the correlation file exists
        if exist(corr_file,'file')==2
            load(corr_file);

            % Figure out the range of correlations for this condition
            all_corrs=horzcat(data_corr{:,2});

            % Compute the correlation threshold
            corr_thresh=prctile(all_corrs,params.thresh_percentile);

            if params.plot_corrs
                figure();
                hist(all_corrs,100);
                hold all;
                plot([corr_thresh corr_thresh],ylim(),'r--');
                xlabel('Correlation');
                ylabel('Number of trials');
                title(condition);
            end

            % Go through each date in the data
            for dat_idx=1:length(data.dates)

                % Convert to date format used in correlation file
                date=data.dates{dat_idx};
                corr_date=datestr(datetime(date,'InputFormat','dd.MM.yy'),'dd.mm.YYYY');

                % Find all trials from this date in this condition
                date_trials=find(strcmp(data.metadata.condition,condition) & (data.trial_date==dat_idx));

                if length(date_trials)>0
                    % Find all correlations for this date
                    corr_dat_idx=find(strcmp([data_corr{:,1}],corr_date));
                    if length(corr_dat_idx)
                        correlations=data_corr{corr_dat_idx,2};

                        % Add trials with correlation less than threshold to the list
                        % of bad trials
                        bad_date_trials=find(correlations<corr_thresh);
                        if length(bad_date_trials)>0
                            date_trials_to_remove=setdiff(date_trials(bad_date_trials),bad_trials);
                            corr_bad_trials(end+1:end+length(date_trials_to_remove))=date_trials_to_remove;
                        end
                    end
                end
            end
        end
    else
        bad_trials=union(bad_trials, strcmp(data.metadata.condition,condition));
    end
end
disp(sprintf('Removing %d trials based on correlation', length(corr_bad_trials)));

bad_trials=union(bad_trials, corr_bad_trials);

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
    spike_rts=rts(data.spikedata.trial);
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
