function select_week_trials=select_week_trials(data_dir, dates, array, electrodes, condition,event,varargin)
 
% Parse optional arguments
defaults=struct('n_splits', 20, 'output_fname', 'granger_glm_results.mat',...
    'output_path', '../../../../output/functional_connectivity');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end
 
addpath('../../spike_data_processing');
 addpath('../../../matlab');

exp_info= init_exp_info();
 
M={};
granger_glm_results=[];
 
exp_info=init_exp_info;

 
for array_idx=1:length(array)
    
    date_data={};
    for date_idx=1:length(dates)
        date=dates{date_idx};
        dir_data=fullfile(data_dir, date, 'multiunit','binned',sprintf('fr_b_%s_%s_%s.mat', array{array_idx}, date,event));
        load(dir_data);
        data=concatenate_data({data});
        data=filter_data(exp_info, data,'thresh_percentile', 10 ); % 'thresh_percentile', 10
        date_data{date_idx}=data;
    end
    data=concatenate_data(date_data, 'spike_times',false);
    
    
    %Analysis epoch (0s to reward) length(find(strcmp(data2.metadata.condition,'fixation')))


    
    for t=1:data.ntrials
        rew_time=data.metadata.reward(t);
        data.binned_spikes(:,electrodes,t,find((data.bins<0) | (data.bins>=rew_time)))=NaN;
        data.firing_rate(:,electrodes,t,find((data.bins<0) | (data.bins>=rew_time)))=NaN;
        data.smoothed_firing_rate(:,electrodes,t,find((data.bins<0) | (data.bins>=rew_time)))=NaN;
    end
    
    bin_idx=find(data.bins>=0);
    data.bins=data.bins(bin_idx);
    data.binned_spikes=data.binned_spikes(:,electrodes,:,bin_idx);
    data.firing_rate=data.firing_rate(:,electrodes,:,bin_idx);
    data.smoothed_firing_rate=data.smoothed_firing_rate(:,electrodes,:,bin_idx);
    
    granger_glm_results.bins=data.bins;
    
    num_units=length(electrodes);
    
    % Figure out total number of trials (to initialize X with the right size)
    trials=zeros(1,length(data.metadata.condition));
    for i=1:length(condition)
        trials=trials | strcmp(data.metadata.condition,condition{i});
    end
    trials=find(trials);
    num_trials=length(trials);
    
    data.metadata.condition=data.metadata.condition(trials);
    data.metadata.trial_start=data.metadata.trial_start(trials);
    data.metadata.fix_on=data.metadata.fix_on(trials);
    data.metadata.go=data.metadata.go(trials);
    data.metadata.hand_mvmt_onset=data.metadata.hand_mvmt_onset(trials);
    data.metadata.tool_mvmt_onset=data.metadata.tool_mvmt_onset(trials);
    data.metadata.obj_contact=data.metadata.obj_contact(trials);
    data.metadata.place=data.metadata.place(trials);
    data.metadata.reward=data.metadata.reward(trials);
    
    data.binned_spikes=data.binned_spikes(:,:,trials,:);
    data.firing_rate=data.firing_rate(:,:,trials,:);
    data.smoothed_firing_rate=data.smoothed_firing_rate(:,:,trials,:);
    
    X=permute(squeeze(data.binned_spikes),[1 3 2]);
    X(X>1) = 1;
    
    if array_idx==1
        M=X;
    else
        M( (max(electrodes)*(array_idx-1)+1) : (max(electrodes)*array_idx) ,:,:)=X;
    end
    
    
end
select_week_trials=M;
 
end
