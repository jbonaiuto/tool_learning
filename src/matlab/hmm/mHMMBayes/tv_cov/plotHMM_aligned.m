function plotHMM_aligned(model, data, varargin)

% Parse optional arguments
defaults=struct();
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

% Compute firing rate
data=compute_firing_rate(data, 'baseline_type', 'none', 'win_len', 6);

% Compute bin width
binwidth=(data.bins(2)-data.bins(1));

% Align events
align_events={'go','hand_mvmt_onset','obj_contact','place'};
%align_events={'go','hand_mvmt_onset','tool_mvmt_onset','obj_contact','place'};

% Size of epochs around each align event
win_size=[-150 150];

% Aligned forward probabilities and firing rates for this condition
forward_probs=[];%zeros(length(condition_trials), model.n_states,...
%length(align_events), length([win_size(1):binwidth:win_size(2)]));
firing_rates=[];%zeros(length(condition_trials), length(data.electrodes),...
%length(align_events), length([win_size(1):binwidth:win_size(2)]));

% For each alignment event
for r=1:length(align_events)
    align_evt=align_events{r};
    
    % Times of this event in all trials
    align_event_times = data.metadata.(align_evt);
    
    for t_idx=1:data.ntrials
        % Rows of forward probabilities for this trial
        trial_rows=find((model.forward_probs.subj==t_idx));
        
        if length(trial_rows)
            % Get the bins that we used in the HMM (time>0 and up to reward)
            bin_idx=find((data.bins>=0) & (data.bins<=data.metadata.reward(t_idx)));
            
            % Find time of alignment event in this trial
            event_time = align_event_times(t_idx);
            
            % Window around event to get data
            win_start_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(1));
            win_end_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(2));
            event_wdw = [win_start_idx:win_end_idx];
            
            % Save p states within this window
            for i=1:model.n_states
                state_idx=find(model.metadata.state_labels==i);
                sprobs=model.forward_probs.(sprintf('fw_prob_S%d',state_idx));
                forward_probs(t_idx,i,r,1:length(event_wdw)) = sprobs(trial_rows(event_wdw));
            end
            
            % Get firing rates for this trial
            trial_firing_rates=squeeze(data.firing_rate(1,:,t_idx,bin_idx));
            
            % Save firing rates in this window
            win_rates=trial_firing_rates(:,event_wdw);
            firing_rates(t_idx,:,r,1:size(win_rates,2))=win_rates;
        end
    end
end

% Compute firing rate limits
firing_rate_lims=[Inf -Inf];
mean_aligned_firing_rates=squeeze(mean(firing_rates,1));
stderr_aligned_firing_rates=squeeze(std(firing_rates,[],1))./sqrt(size(firing_rates,1));
[min_rate,min_rate_idx]=min(mean_aligned_firing_rates(:)-stderr_aligned_firing_rates(:));
if min_rate<firing_rate_lims(1)
    firing_rate_lims(1)=min_rate;
end
[max_rate,max_rate_idx]=max(mean_aligned_firing_rates(:)+stderr_aligned_firing_rates(:));
if max_rate>firing_rate_lims(2)
    firing_rate_lims(2)=max_rate;
end

%colors=cbrewer('qual','Paired',12);
colors=cbrewer2('qual','Dark2',6);

f=figure();
set(f, 'Position', [0 88 889 987]);

for r=1:length(align_events)
    ax=subplot(2,length(align_events),r);
    fr_colors=get(gca,'ColorOrder');
    hold all;
    title(strrep(align_events{r},'_',' '));
    if r==1
        ylabel('Firing rate (Hz)','FontSize',12,'FontWeight','bold');
    end
    for m=1:length(data.electrodes)
        mean_fr=squeeze(mean(firing_rates(:,m,r,:)));
        stderr_fr=squeeze(std(firing_rates(:,m,r,:)))./sqrt(size(firing_rates,1));
        H=shadedErrorBar([win_size(1):binwidth:win_size(2)],mean_fr,stderr_fr,...
            'LineProps',{'Color',fr_colors(mod(m-1,7)+1,:)});
    end
    xlim(win_size);
    ylim(firing_rate_lims);
    plot([0 0],ylim(),':k');
end

for r=1:length(align_events)
    ax=subplot(2,length(align_events),length(align_events)+r);
    hold all
    if r==1
        ylabel('Forward probability','FontSize',12,'FontWeight','bold');
    end
    handles=[];
    state_labels={};
    for m=1:model.n_states
        mean_pstate=squeeze(nanmean(forward_probs(:,m,r,:)));
        stderr_pstate=squeeze(nanstd(forward_probs(:,m,r,:)))./sqrt(size(forward_probs,1));
        H=shadedErrorBar([win_size(1):binwidth:win_size(2)],mean_pstate,stderr_pstate,...
            'LineProps',{'Color',colors(m,:)});
        handles(end+1)=H.mainLine;
        state_labels{end+1}=sprintf('State %d', m);
    end
    
    plot([0 0],[0 1],':k');
    plot(xlim(),[1/model.n_states 1/model.n_states],'-.k');
    xlim(win_size);
    ylim([0 1]);
    xlabel('Time (ms)');
    if r==length(align_events)
        orig_pos=get(ax,'Position');
        legend(handles, state_labels,'Location','bestoutside');
        set(ax,'Position',orig_pos);
    end
end

