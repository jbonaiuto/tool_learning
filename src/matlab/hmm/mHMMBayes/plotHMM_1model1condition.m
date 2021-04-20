function aligned_p_states=plotHMM_1model1condition(exp_info, array, data, dates, conditions, forward_probs_file)

dbstop if error

% Compute dt
orig_binwidth=(data.bins(2)-data.bins(1));
new_binwidth=10;

if orig_binwidth ~= new_binwidth
data2=rebin_spikes(data,new_binwidth/orig_binwidth);
data2=compute_firing_rate(data2, 'baseline_type', 'none', 'win_len', 6);
else
 data2 = data;
 data2=compute_firing_rate(data2, 'baseline_type', 'none', 'win_len', 6);
end

% identify trials per date and conditions
condition_trials=zeros(1,length(data.metadata.condition));
for i=1:length(conditions)
    condition_trials = condition_trials | (strcmp(data.metadata.condition,conditions{i}));
end
condition_trials=find(condition_trials);
trial_date=data.trial_date(condition_trials);

clear('date_data');

%Align events
align_events={'go','hand_mvmt_onset','obj_contact','place'};

win_size=[-150 150];

% read the forward probabilty file and compte the number of states
forward_probs=readtable(forward_probs_file);
n_states=0;
for i=1:length(forward_probs.Properties.VariableNames)
    var_name=forward_probs.Properties.VariableNames{i};
    if startsWith(var_name,'fw_prob_')
        n_states=n_states+1;
    end
end

% creat array giving the state forward probability for each trial of the conditions, states, events 
% and bin for the window of interest around the aligned event
aligned_p_states=zeros(length(condition_trials), n_states,...
    length(align_events), length([win_size(1):orig_binwidth:win_size(2)]));
% the same but for the firing rate
aligned_firing_rates=zeros(length(condition_trials), length(data2.electrodes),...
    length(align_events), length([win_size(1):new_binwidth:win_size(2)]));


% For each alignment event
for r=1:length(align_events)
    align_evt=align_events{r};
    
    % Times of this event in all trials
    align_event_times = data.metadata.(align_evt);
    
    
    % Go through each date
    t_idx=1; %trial_index to have the connection between data structure and forward probability csv file
    for d=1:length(dates)
        day_trials=condition_trials(trial_date==d);
        
        % Go through each trial
        for n=1:length(day_trials)
            %get the row corresponding to the n trial the d day
            trial_rows=find((forward_probs.subj==d) & (forward_probs.rm==n));
           
            % Get the bins that we used in the HMM (time>0 and up to 150ms after place)
            bin_idx=find((data.bins>=0) & (data.bins<=(data.metadata.place(condition_trials(n))+150)));
            
            % Find time of alignment event in this trial
            event_time = align_event_times(condition_trials(t_idx));

            % Window around event to get data
            win_start_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(1));
            win_end_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(2));
            event_wdw = [win_start_idx:min(length(trial_rows),win_end_idx)];

            % Save p states within this window
            for i=1:n_states
                sprobs=forward_probs.(sprintf('fw_prob_S%d',i));
                aligned_p_states(t_idx,i,r,1:length(event_wdw)) = sprobs(trial_rows(event_wdw));
            end
            
            t_idx=t_idx+1;
        end
    end

    for n=1:length(condition_trials)
        % Get the bins that we used in the HMM (time>0 and up to 150ms after place)
        bin_idx=find((data2.bins>=0) & (data2.bins<=(data2.metadata.place(condition_trials(n))+150)));
        
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
    ax=subplot(2,length(align_events),r);
    fr_colors=get(gca,'ColorOrder');
    hold all;
    title(strrep(align_events{r},'_',' '));
    if r==1
        ylabel({sprintf('%s , %s', strjoin(conditions,'_'), array);' ';'Firing rate'},'FontSize',20,'FontWeight','bold');
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
    if r==length(align_events)
        orig_pos=get(ax,'Position');
        l=legend(handles, electrode_labels,'Location','bestoutside');
        set(ax,'Position',orig_pos);
    end
end

for r=1:length(align_events)
    ax=subplot(2,length(align_events),length(align_events)+r);
    hold all
    title(strrep(align_events{r},'_',' '));
    ylim([0 1.2]);
    
    if r==1
        ylabel({sprintf('%s , %s', strjoin(conditions,'_'), array);' ';'Firing rate'},'FontSize',20,'FontWeight','bold');
    end
    
    handles=[];
    state_labels={};
    for state_idx=1:n_states
        mean_pstate=squeeze(nanmean(aligned_p_states(:,state_idx,r,:)));
        stderr_pstate=squeeze(nanstd(aligned_p_states(:,state_idx,r,:)))./sqrt(size(aligned_p_states,1));
        H=shadedErrorBar([win_size(1):orig_binwidth:win_size(2)],mean_pstate,stderr_pstate,'LineProps',{'Color',colors(state_idx,:)});
        handles(end+1)=H.mainLine;
        state_labels{end+1}=sprintf('State %d', state_idx);
    end
    
    plot([0 0],ylim(),':k');
    plot(xlim(),[0.6 0.6],'-.k');
    xlabel('Time (ms)');
    if r==length(align_events);
        orig_pos=get(ax,'Position');
        legend(handles, state_labels,'Location','bestoutside');
        set(ax,'Position',orig_pos);
    end
end

saveas(f,fullfile(exp_info.base_output_dir,'HMM', 'betta', 'grasp', 'mHMM', [strjoin(conditions,'_') '_' array '_' '10w_mHMM_grasp.png']));
saveas(f,fullfile(exp_info.base_output_dir,'HMM', 'betta', 'grasp', 'mHMM', [strjoin(conditions,'_') '_' array '_' '10w_mHMM_grasp.png']), 'epsc');
%close(f);
end