function plotHMM_onetrial_raster(subject, array, electrodes, data, dates, conditions, model, output_path)


% Parse optional arguments
% defaults=struct();
% params=struct(varargin{:});
% for f=fieldnames(defaults)'
%     if ~isfield(params, f{1})
%         params.(f{1})=defaults.(f{1});
%     end
% end

% load data with 1ms time bin for the raster plots
data10ms=data;
dt=1;

data_fname=fullfile(output_path,'data1ms.mat');
if exist(data_fname,'file')~=2
    % Create a cell array with the data structure of each day to concatenate them
    % into one big structure
    all_data={};
    
    for d_idx=1:length(dates)
        date=dates{d_idx};
        
        % Load and concatenate spike data
        load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
            date,'multiunit','binned',...
            sprintf('fr_b_%s_%s_whole_trial.mat',array,date)));
        
        %create a vector of 1 with the length equal to number of the trail of the day for this condition
        data.trial_date=ones(1,data.ntrials);
        
        % Filter data - RTs too fast or slow
        data=filter_data(data);
        
        % Save to cell array
        all_data{d_idx}=data;
    end
    
    %concatenate all the data structure per day in one big data structure for the period
    concat_data=concatenate_data(all_data, 'spike_times',false);
    clear all_data;
    
    % Figure out which trials to use
    condition_trials=zeros(1,length(concat_data.metadata.condition));
    for i=1:length(conditions)
        condition_trials = condition_trials | (strcmp(concat_data.metadata.condition,conditions{i}));
    end
    condition_trials=find(condition_trials);
    % Remove extra trials - makes the following bit a lot simpler
    all_trials=[1:length(concat_data.metadata.condition)];
    trials_to_remove=setdiff(all_trials,condition_trials);
    data=remove_trials(concat_data,trials_to_remove);
    save(data_fname,'data','-v7.3');
else
    load(data_fname);
end

% Compute firing rate
%data10ms=compute_firing_rate(data10ms, 'baseline_type', 'none', 'win_len', 6);
 
% Compute bin width
binwidth=(data10ms.bins(2)-data10ms.bins(1));
binwidth_1ms=(data.bins(2)-data.bins(1));

% Align events
%align_events={'go','hand_mvmt_onset','obj_contact','place'};
align_event='go';
condition='motor_grasp_center';

% Find data trials for this condition
condition_trials = find(strcmp(data10ms.metadata.condition,condition));

%define the trial of interest
TOI=condition_trials(3);

% adapt window size to each trial
reward_time=ceil(data10ms.metadata.reward(TOI)-data10ms.metadata.go(TOI));
win_size=[-500 reward_time];
%win_size=[-500 2500];
    
% Date index of each trial for this condition
%trial_date=data10ms.trial_date(condition_trials);
    
% Aligned forward probabilities and firing rates for this condition
trial_forward_probs=[];

% Times of this event in all trials
align_event_times = data10ms.metadata.(align_event);
% find the event times and align them to the go signal
HandMvtOnset_time=data10ms.metadata.hand_mvmt_onset(TOI)-data10ms.metadata.go(TOI);
contact_time=data10ms.metadata.obj_contact(TOI)-data10ms.metadata.go(TOI);
place_time=data10ms.metadata.place(TOI)-data10ms.metadata.go(TOI);

%d=1;
% Find trials from this date for this condition
%day_trials=condition_trials(trial_date==d);

% Rows of forward probabilities for this trial
%n=4;
trial_rows=find((model.forward_probs.subj==TOI));
if strcmp(model.type,'multilevel')
    trial_rows=find((model.forward_probs.subj==d) & (model.forward_probs.rm==n));
end

% Get the bins that we used in the HMM (time>0 and up to reward)
bin_idx=find((data10ms.bins>=0) & (data10ms.bins<=data10ms.metadata.reward(TOI)));
bin_1ms_idx=find((data.bins>=0) & (data.bins<=data.metadata.reward(TOI)));

% Find time of alignment event in this trial
event_time = align_event_times(TOI);

% Window around event to get data
%win_start_idx=1;
win_start_idx=knnsearch(data10ms.bins(bin_idx)',event_time+win_size(1));
win_end_idx=knnsearch(data10ms.bins(bin_idx)',event_time+win_size(2));
event_wdw =[win_start_idx:win_end_idx];
                
% Window around event to get data for rater, with data in 1ms bin 
win_start_1ms_idx=knnsearch(data.bins(bin_1ms_idx)',event_time+win_size(1));
win_end_1ms_idx=knnsearch(data.bins(bin_1ms_idx)',event_time+win_size(2));
event_wdw_1ms =[win_start_1ms_idx:win_end_1ms_idx];

% Save p states within this window
for i=1:model.n_states
    sprobs=model.forward_probs.(sprintf('fw_prob_S%d',i));
    %trial_forward_probs(i,:) = sprobs(trial_rows);
    trial_forward_probs(i,:) = sprobs(trial_rows(event_wdw));
end

% Get the spikes for this trial
trial_spikes=squeeze(data.binned_spikes(1,electrodes,TOI,bin_1ms_idx));
trial_spikes=trial_spikes(:,event_wdw_1ms);
                

colors=cbrewer2('qual','Dark2',12);

f=figure();
 
subplot(2,1,1)    
hold on 
ylabel('State Probability','FontSize',12,'FontWeight','bold');
handles=[];
state_labels={};
state_nums=model.metadata.state_labels;
for m=1:max(state_nums)
    state_idx=state_nums(m);
    plot([win_size(1):binwidth:win_size(2)],squeeze(trial_forward_probs(state_idx,:)),'Color',colors(m,:),'LineWidth',1.5)
    state_labels{end+1}=sprintf('State %s', model.metadata.state_labels(state_idx));
end
ylim([0 1]);
xlabel('Time (ms)');
xlim(win_size);
xline(0,':k','go signal','LabelHorizontalAlignment','left','LabelOrientation','horizontal');
xline(HandMvtOnset_time,':k','hand mvt onset','LabelHorizontalAlignment','left','LabelOrientation','horizontal');
xline(contact_time,':k','contact','LabelHorizontalAlignment','left','LabelOrientation','horizontal');
xline(place_time,':k','place','LabelHorizontalAlignment','left','LabelOrientation','horizontal');
% plot([HandMvtOnset_time HandMvtOnset_time],ylim(),':k');
% plot([contact_time contact_time],ylim(),':k');
% plot([place_time place_time],ylim(),':k');


% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'MotorGrasp' '_ForwardProb_trial1_TvCov' '.png']));
% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'MotorGrasp' '_ForwardProb_1trial1_TvCov' '.eps']),'epsc');
 

subplot(2,1,2)
hold on 
el_idx=[1:length(electrodes)]./(length(electrodes)+1);
win_times=[win_size(1):binwidth_1ms:win_size(2)];
for el=1:length(electrodes)
    spike_times=win_times(find(trial_spikes(el,:)));
    plot(spike_times, el_idx(el).*ones(size(spike_times)),'.k');
end
ylim([0 1]);
yticks([]);
ylabel('electrodes');
xlabel('Time (ms)');
xlim(win_size);
xline(0,':k','go signal','LabelHorizontalAlignment','left','LabelOrientation','horizontal');
xline(HandMvtOnset_time,':k','hand mvt onset','LabelHorizontalAlignment','left','LabelOrientation','horizontal');
xline(contact_time,':k','contact','LabelHorizontalAlignment','left','LabelOrientation','horizontal');
xline(place_time,':k','place','LabelHorizontalAlignment','left','LabelOrientation','horizontal');
% plot([HandMvtOnset_time HandMvtOnset_time],ylim(),':k');
% plot([contact_time contact_time],ylim(),':k');
% plot([place_time place_time],ylim(),':k');

% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'MotorGrasp' '_raster_trial_TvCov' '.png']));
% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'MotorGrasp' '_raster_trial1_TvCov' '.eps']),'epsc');

end
