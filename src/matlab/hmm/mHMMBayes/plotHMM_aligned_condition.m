function [aligned_forward_probs,f]=plotHMM_aligned_condition(data, dates,...
    conditions, model, varargin)

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

% Aligned forward probabilities and firing rates for each condition
aligned_forward_probs={};
aligned_firing_rates={};

% For each condition
for cond_idx=1:length(conditions)
    % Find data trials for this condition
    condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
    
    % Date index of each trial for this condition
    trial_date=data.trial_date(condition_trials);

    % Aligned forward probabilities and firing rates for this condition
    cond_forward_probs=[];%zeros(length(condition_trials), model.n_states,...
            %length(align_events), length([win_size(1):binwidth:win_size(2)]));
    cond_firing_rates=[];%zeros(length(condition_trials), length(data.electrodes),...
        %length(align_events), length([win_size(1):binwidth:win_size(2)]));
    
    % For each alignment event
    for r=1:length(align_events)
        align_evt=align_events{r};
    
        % Times of this event in all trials
        align_event_times = data.metadata.(align_evt);
        
        % Go through each trial
        t_idx=1;
        
        % For every date
        for d=1:length(dates)
            % Find trials from this date for this condition
            day_trials=condition_trials(trial_date==d);
            
            % For each trial from this day in this condition
            for n=1:length(day_trials)
                
                % Rows of forward probabilities for this trial
                trial_rows=find((model.forward_probs.subj==day_trials(n)));
                if strcmp(model.type,'multilevel')
                    trial_rows=find((model.forward_probs.subj==d) & (model.forward_probs.rm==n));
                end
                            
                % Get the bins that we used in the HMM (time>0 and up to reward)
                bin_idx=find((data.bins>=0) & (data.bins<=data.metadata.reward(day_trials(n))));
                
                % Find time of alignment event in this trial
                event_time = align_event_times(day_trials(n));

                % Window around event to get data
                win_start_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(1));
                win_end_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(2));
                event_wdw = [win_start_idx:win_end_idx];

                % Save p states within this window
                for i=1:model.n_states
                    sprobs=model.forward_probs.(sprintf('fw_prob_S%d',i));
                    cond_forward_probs(t_idx,i,r,1:length(event_wdw)) = sprobs(trial_rows(event_wdw));                        
                end

                % Get firing rates for this trial
                trial_firing_rates=squeeze(data.smoothed_firing_rate(1,:,day_trials(n),bin_idx));

                % Save firing rates in this window
                win_rates=trial_firing_rates(:,event_wdw);
                cond_firing_rates(t_idx,:,r,1:size(win_rates,2))=win_rates;    
                t_idx=t_idx+1;
            end
        end
    end
    aligned_forward_probs{cond_idx}=cond_forward_probs;
    aligned_firing_rates{cond_idx}=cond_firing_rates;    
end

% Compute firing rate limits
firing_rate_lims=[Inf -Inf];
for cond_idx=1:length(conditions)
    cond_mean_aligned_firing_rates=squeeze(mean(aligned_firing_rates{cond_idx}));
    cond_stderr_aligned_firing_rates=squeeze(std(aligned_firing_rates{cond_idx}))./sqrt(size(aligned_firing_rates{cond_idx},1));
    [min_rate,min_rate_idx]=min(cond_mean_aligned_firing_rates(:)-cond_stderr_aligned_firing_rates(:));
    if min_rate<firing_rate_lims(1)
        firing_rate_lims(1)=min_rate;
    end    
    [max_rate,max_rate_idx]=max(cond_mean_aligned_firing_rates(:)+cond_stderr_aligned_firing_rates(:));
    if max_rate>firing_rate_lims(2)
        firing_rate_lims(2)=max_rate;
    end
end

%colors=cbrewer('qual','Paired',12);
colors=cbrewer('qual','Dark2',12);

f=figure();
set(f, 'Position', [0 88 889 987]);

for cond_idx=1:length(conditions)
    cond_aligned_firing_rates=aligned_firing_rates{cond_idx};
    cond_aligned_p_states=aligned_forward_probs{cond_idx};
    
    for r=1:length(align_events)
        ax=subplot(2*length(conditions),length(align_events),2*(cond_idx-1)*length(align_events)+r);
        fr_colors=get(gca,'ColorOrder');
        hold all;
        if cond_idx==1
            title(strrep(align_events{r},'_',' '));
        end
        if r==1
            ylabel({strrep(conditions{cond_idx},'_',' ');'Firing rate'},'FontSize',12,'FontWeight','bold');
        end
        handles=[];
        electrode_labels={};
        for m=1:length(data.electrodes)
            mean_fr=squeeze(mean(cond_aligned_firing_rates(:,m,r,:)));
            stderr_fr=squeeze(std(cond_aligned_firing_rates(:,m,r,:)))./sqrt(size(cond_aligned_firing_rates,1));
            H=shadedErrorBar([win_size(1):binwidth:win_size(2)],mean_fr,stderr_fr,'LineProps',{'Color',fr_colors(mod(m-1,7)+1,:)});
            handles(end+1)=H.mainLine;
            electrode_labels{end+1}=sprintf('electrode %d',m);
        end
        xlim(win_size);
        ylim(firing_rate_lims);
        plot([0 0],ylim(),':k');    
    end

    for r=1:length(align_events)
        ax=subplot(2*length(conditions),length(align_events),2*(cond_idx-1)*length(align_events)+length(align_events)+r);
        hold all        
        if r==1
            ylabel('State Probability','FontSize',12,'FontWeight','bold');
        end
        handles=[];
        state_labels={};
        state_nums=cellfun(@str2num,model.metadata.state_labels);
        for m=1:max(state_nums)
            state_idx=find(strcmp(model.metadata.state_labels,num2str(m)));
            if length(state_idx)
                mean_pstate=squeeze(nanmean(cond_aligned_p_states(:,state_idx,r,:)));
                stderr_pstate=squeeze(nanstd(cond_aligned_p_states(:,state_idx,r,:)))./sqrt(size(cond_aligned_p_states,1));
                H=shadedErrorBar([win_size(1):binwidth:win_size(2)],mean_pstate,stderr_pstate,'LineProps',{'Color',colors(m,:)});
                handles(end+1)=H.mainLine;
                state_labels{end+1}=sprintf('State %s', model.metadata.state_labels{state_idx});
            end
        end

        plot([0 0],[0 1],':k');
        plot(xlim(),[1/model.n_states 1/model.n_states],'-.k');
        xlim(win_size);
        ylim([0 1]);
        if cond_idx==length(conditions)
            xlabel('Time (ms)');
        end
        if cond_idx==1 && r==length(align_events)
            orig_pos=get(ax,'Position');
            legend(handles, state_labels,'Location','bestoutside');
            set(ax,'Position',orig_pos);
        end
    end
end

% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'grasp' '_StateSequence_5w_MuldiDayMultiCond' '.png']));
% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'grasp' '_StateSequence_5w_MuldiDayMultiCond' '.eps']),'epsc');
end