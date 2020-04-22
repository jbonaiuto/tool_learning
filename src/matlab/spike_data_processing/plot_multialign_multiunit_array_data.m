function plot_multialign_multiunit_array_data(exp_info, subject, dates, array, conditions)

date_data={};
for i=1:length(dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dates{i},'multiunit','binned',...
        sprintf('fr_b_%s_%s_whole_trial.mat', array, dates{i})));
    date_data{i}=data;
    clear('data');
end

data=concatenate_data(date_data, 'spike_times', false);
data=filter_data(data);
% Compute dt
dt=(data.bins(2)-data.bins(1))/1000;

new_binwidth=10;
data2=rebin_spikes(data,new_binwidth);
data2=compute_firing_rate(data2, 'baseline_type', 'none', 'win_len', 6);

condition_trials=zeros(1,length(data.metadata.condition));
for i=1:length(conditions)
    condition_trials = condition_trials | (strcmp(data.metadata.condition,conditions{i}));
end
condition_trials=find(condition_trials);
length(condition_trials)
trial_date=data.trial_date(condition_trials);

clear('date_data');

%Align events
align_events={'go','hand_mvmt_onset','obj_contact','place'};

win_size=[-150 150];

aligned_firing_rates=zeros(length(condition_trials), length(data.electrodes),...
    length(align_events), length([win_size(1):new_binwidth:win_size(2)]));

% For each alignment event
for r=1:length(align_events)
    align_evt=align_events{r};
    
    % Times of this event in all trials
    align_event_times = data.metadata.(align_evt);
    
    for n=1:length(condition_trials)
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data2.bins>=0) & (data2.bins<(data2.metadata.reward(condition_trials(n)))));
        
        % Get firing rates for this trial
        trial_firing_rates=squeeze(data2.smoothed_firing_rate(1,:,condition_trials(n),bin_idx));
        
        % Find time of alignment event in this trial
        event_time = align_event_times(condition_trials(n));
        
        % Window around event to get data
        win_start_idx=knnsearch(data2.bins(bin_idx)',event_time+win_size(1));
        win_end_idx=knnsearch(data2.bins(bin_idx)',event_time+win_size(2));
        event_wdw = [win_start_idx:win_end_idx];
        
        % Save firing rates in this window
        win_rates=trial_firing_rates(:,event_wdw);
        aligned_firing_rates(n,:,r,1:size(win_rates,2))=win_rates;    
    end
end
mean_aligned_firing_rates=squeeze(mean(aligned_firing_rates));
stderr_aligned_firing_rates=squeeze(std(aligned_firing_rates))./sqrt(size(aligned_firing_rates,1));
[min_rate,min_rate_idx]=min(mean_aligned_firing_rates(:));
[max_rate,max_rate_idx]=max(mean_aligned_firing_rates(:));
firing_rate_lims=[min_rate-stderr_aligned_firing_rates(min_rate_idx) max_rate+stderr_aligned_firing_rates(max_rate_idx)];
colors=cbrewer('qual','Paired',12);

f=figure();
ylim([0 1.2]);
set(f, 'Position', get(0, 'Screensize'));

for r=1:length(align_events)
    ax=subplot(1,length(align_events),r);
    fr_colors=get(gca,'ColorOrder');
    hold all;
    title(strrep(align_events{r},'_',' '));
    if r==1
        ylabel({'Motor grasp: right, F1';' ';'Firing rate'},'FontSize',20,'FontWeight','bold');
    end
    handles=[];
    electrode_labels={};
    for m=1:length(data.electrodes)
        mean_fr=squeeze(mean(aligned_firing_rates(:,m,r,:)));
        stderr_fr=squeeze(std(aligned_firing_rates(:,m,r,:)))./sqrt(size(aligned_firing_rates,1));
        H=shadedErrorBar([win_size(1):new_binwidth:win_size(2)],mean_fr,stderr_fr,'LineProps',{'Color',fr_colors(mod(m-1,7)+1,:)});
        handles(end+1)=H.mainLine;
        electrode_labels{end+1}=sprintf('electrode %d',m);
    end
    ylim(firing_rate_lims);
    plot([0 0],ylim(),':k');    
    xlabel('Time (ms)');
    if r==length(align_events);
        orig_pos=get(ax,'Position');
        l=legend(handles, electrode_labels,'Location','bestoutside');
        set(ax,'Position',orig_pos);
    end
end

end
