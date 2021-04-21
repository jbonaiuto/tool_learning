function aligned_p_states=plotMHMM_aligned_condition(data, dates, condition, model)

dbstop if error

data=compute_firing_rate(data, 'baseline_type', 'none', 'win_len', 6);
 
binwidth=(data.bins(2)-data.bins(1));

%Align events
align_events={'go','hand_mvmt_onset','obj_contact','place'};

win_size=[-150 150];

condition_trials = find(strcmp(data.metadata.condition,condition));
    
trial_date=data.trial_date(condition_trials);

aligned_p_states=zeros(length(condition_trials), model.n_states,...
        length(align_events), length([win_size(1):binwidth:win_size(2)]));
aligned_firing_rates=zeros(length(condition_trials), length(data.electrodes),...
    length(align_events), length([win_size(1):binwidth:win_size(2)]));
    
% For each alignment event
for r=1:length(align_events)
    align_evt=align_events{r};

    % Times of this event in all trials
    align_event_times = data.metadata.(align_evt);

    % Go through each trial
    t_idx=1;
    for d=1:length(dates)
        day_trials=condition_trials(trial_date==d);

        for n=1:length(day_trials)
            trial_rows=find((model.forward_probs.subj==d) & (model.forward_probs.rm==n));
            
            % Get the bins that we used in the HMM (time>0 and up to 150ms after place)
            if ~isnan(data.metadata.place(day_trials(n))) && data.metadata.place(day_trials(n))+150<=data.bins(end)
                bin_idx=find((data.bins>=0) & (data.bins<=(data.metadata.place(day_trials(n))+150)));

                % Find time of alignment event in this trial
                event_time = align_event_times(condition_trials(t_idx));

                % Window around event to get data
                win_start_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(1));
                win_end_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(2));
                event_wdw = [win_start_idx:win_end_idx];

                % Save p states within this window
                for i=1:model.n_states
                    sprobs=model.forward_probs.(sprintf('fw_prob_S%d',i));
                    aligned_p_states(t_idx,i,r,1:length(event_wdw)) = sprobs(trial_rows(event_wdw));                        
                end

                % Get firing rates for this trial
                trial_firing_rates=squeeze(data.smoothed_firing_rate(1,:,day_trials(n),bin_idx));

                % Save firing rates in this window
                win_rates=trial_firing_rates(:,event_wdw);
                aligned_firing_rates(t_idx,:,r,1:size(win_rates,2))=win_rates;    
                t_idx=t_idx+1;
            end
        end
    end
end

firing_rate_lims=[Inf -Inf];
cond_mean_aligned_firing_rates=squeeze(mean(aligned_firing_rates));
cond_stderr_aligned_firing_rates=squeeze(std(aligned_firing_rates))./sqrt(size(aligned_firing_rates,1));
[min_rate,min_rate_idx]=min(cond_mean_aligned_firing_rates(:));
[max_rate,max_rate_idx]=max(cond_mean_aligned_firing_rates(:));
firing_rate_lims=[min_rate-cond_stderr_aligned_firing_rates(min_rate_idx) max_rate+cond_stderr_aligned_firing_rates(max_rate_idx)];
colors=cbrewer('qual','Paired',12);

f=figure();
set(f, 'Position', get(0, 'Screensize'));

for r=1:length(align_events)
    ax=subplot(2,length(align_events),r);
    fr_colors=get(gca,'ColorOrder');
    hold all;
    title(strrep(align_events{r},'_',' '));
    if r==1
        ylabel({strrep(condition,'_',' ');'Firing rate'},'FontSize',12,'FontWeight','bold');
    end
    handles=[];
    electrode_labels={};
    for m=1:length(data.electrodes)
        mean_fr=squeeze(mean(aligned_firing_rates(:,m,r,:)));
        stderr_fr=squeeze(std(aligned_firing_rates(:,m,r,:)))./sqrt(size(aligned_firing_rates,1));
        H=shadedErrorBar([win_size(1):binwidth:win_size(2)],mean_fr,stderr_fr,'LineProps',{'Color',fr_colors(mod(m-1,7)+1,:)});
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
        ylabel({'Motor grasp: right, F1';' ';'State Probability'},'FontSize',12,'FontWeight','bold');
    end
    handles=[];
    state_labels={};
    state_nums=cellfun(@str2num,model.metadata.state_labels);
    for m=1:max(state_nums)
        state_idx=find(strcmp(model.metadata.state_labels,num2str(m)));
        if length(state_idx)
            mean_pstate=squeeze(nanmean(aligned_p_states(:,state_idx,r,:)));
            stderr_pstate=squeeze(nanstd(aligned_p_states(:,state_idx,r,:)))./sqrt(size(aligned_p_states,1));
            H=shadedErrorBar([win_size(1):binwidth:win_size(2)],mean_pstate,stderr_pstate,'LineProps',{'Color',colors(m,:)});
            handles(end+1)=H.mainLine;
            state_labels{end+1}=sprintf('State %s', model.metadata.state_labels{state_idx});
        end
    end

    plot([0 0],ylim(),':k');
    plot(xlim(),[0.6 0.6],'-.k');
    xlabel('Time (ms)');
    if r==length(align_events)
        orig_pos=get(ax,'Position');
        legend(handles, state_labels,'Location','bestoutside');
        set(ax,'Position',orig_pos);
    end
end

%saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, [model_name '_average.png']));
%saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, [model_name '_average.eps']), 'epsc');
%close(f);
end