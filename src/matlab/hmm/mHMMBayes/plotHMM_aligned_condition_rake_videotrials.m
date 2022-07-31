%function aligned_p_states=plotHMM_aligned_condition_rake_videotrials(data, date, conditions, array, forward_probs_file)
function aligned_p_states=plotHMM_aligned_condition_rake_videotrials(data, date, conditions, directions, array)

addpath('../..');
exp_info=init_exp_info();

%data=compute_firing_rate(data, 'baseline_type', 'none', 'win_len', 6);
 
binwidth=(data.bins(2)-data.bins(1));

%Align events
align_events={'go','hand_mvmt_onset','obj_contact','place'};

win_size=[-150 150];

%forward_probs=readtable(forward_probs_file);
% n_states=0;
% for i=1:length(forward_probs.Properties.VariableNames)
%     var_name=forward_probs.Properties.VariableNames{i};
%     if length(var_name)>8 && strcmp(var_name(1:8),'fw_prob_')
%     %if startsWith(var_name,'fw_prob_')
%         n_states=n_states+1;
%     end
% end

%aligned_p_states={};
aligned_firing_rates={};

%% Figure out which trials to use and get trial data

if strcmp(conditions,'AlignedTrial')==1
   addpath('../../video_coding');
   data_idx=ExtractVideoTrial();

   condition={'motor_rake_center','motor_rake_right','motor_rake_left'};
    trials=zeros(1,length(data.metadata.condition));
    for i=1:length(condition)
        trials = trials | (strcmp(data.metadata.condition,condition{i}));
    end

    trials=find(trials);
    trial_condition=data.metadata.condition(trials);

    TOI=[];
    for m=1:length(data_idx)
        TOI(end+1) = trials(data_idx(m));
    end
    trials=TOI;
    length(trials);

        cond_firing_rates=[];%zeros(length(trials), length(data.electrodes),...
            %length(align_events), length([win_size(1):binwidth:win_size(2)]));
        %cond_p_states=[];

        % Rows from forward probs with this condition
        cond_rows=find(forward_probs.condition==i);    
        cond_trials=unique(forward_probs.subj(cond_rows));

        % For each alignment event
        for r=1:length(align_events)
            align_evt=align_events{r};

            % Times of this event in all trials
            align_event_times = data.metadata.(align_evt);
            align_event_times = align_event_times(trials);

            %% Get trial spikes
            t_idx=1;
            for g = 1:length(trials)
                %trial_rows=find((forward_probs.subj==d) & (forward_probs.rm==n));
                if ~isnan(data.metadata.place(trials(g)))
                    trial_rows=find(forward_probs.subj==cond_trials(t_idx));

                    bin_idx=find((data.bins>=0) & (data.bins<=(data.metadata.place(trials(g))+150)));

                    % Find time of alignment event in this trial
                    event_time = align_event_times(g);

                    % Window around event to get data
                    win_start_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(1));
                    win_end_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(2));
                    event_wdw = [win_start_idx:win_end_idx];

                    % Save p states within this window
%                     for j=1:n_states
%                         sprobs=forward_probs.(sprintf('fw_prob_S%d',j));
%                         cond_p_states(t_idx,j,r,1:length(event_wdw)) = sprobs(trial_rows(event_wdw));                        
%                     end

                    % Get firing rates for this trial
                    trial_firing_rates=squeeze(data.smoothed_firing_rate(1,:,trials(g),bin_idx));

                    % Save firing rates in this window
                    win_rates=trial_firing_rates(:,event_wdw);
                    cond_firing_rates(t_idx,:,r,1:size(win_rates,2))=win_rates;    
                    t_idx=t_idx+1;
                end
            end
        end
        %aligned_p_states{i}=cond_p_states;
        aligned_firing_rates{i}=cond_firing_rates;

else
    for i=1:length(conditions)
        trials = strcmp(data.metadata.condition,conditions{i});
        trials=find(trials);
        length(trials);

        cond_firing_rates=[];%zeros(length(trials), length(data.electrodes),...
            %length(align_events), length([win_size(1):binwidth:win_size(2)]));
        cond_p_states=[];

        % Rows from forward probs with this condition
        cond_rows=find(forward_probs.condition==i);    
        cond_trials=unique(forward_probs.subj(cond_rows));

        % For each alignment event
        for r=1:length(align_events)
            align_evt=align_events{r};

            % Times of this event in all trials
            align_event_times = data.metadata.(align_evt);
            align_event_times = align_event_times(trials);

            %% Get trial spikes
            t_idx=1;
            for g = 1:length(trials)
                %trial_rows=find((forward_probs.subj==d) & (forward_probs.rm==n));
                if ~isnan(data.metadata.place(trials(g)))
                    trial_rows=find(forward_probs.subj==cond_trials(t_idx));

                    bin_idx=find((data.bins>=0) & (data.bins<=(data.metadata.place(trials(g))+150)));

                    % Find time of alignment event in this trial
                    event_time = align_event_times(g);

                    % Window around event to get data
                    win_start_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(1));
                    win_end_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(2));
                    event_wdw = [win_start_idx:win_end_idx];

                    % Save p states within this window
                    for j=1:n_states
                        sprobs=forward_probs.(sprintf('fw_prob_S%d',j));
                        cond_p_states(t_idx,j,r,1:length(event_wdw)) = sprobs(trial_rows(event_wdw));                        
                    end

                    % Get firing rates for this trial
                    trial_firing_rates=squeeze(data.smoothed_firing_rate(1,:,trials(g),bin_idx));

                    % Save firing rates in this window
                    win_rates=trial_firing_rates(:,event_wdw);
                    cond_firing_rates(t_idx,:,r,1:size(win_rates,2))=win_rates;    
                    t_idx=t_idx+1;
                end
            end
        end
        aligned_p_states{i}=cond_p_states;
        aligned_firing_rates{i}=cond_firing_rates;

    end
end
    
firing_rate_lims=[Inf -Inf];
for cond_idx=1:length(conditions)
    cond_mean_aligned_firing_rates=squeeze(mean(aligned_firing_rates{cond_idx}));
    cond_stderr_aligned_firing_rates=squeeze(std(aligned_firing_rates{cond_idx}))./sqrt(size(aligned_firing_rates{cond_idx},1));
    [min_rate,min_rate_idx]=min(cond_mean_aligned_firing_rates(:));
    if min_rate<firing_rate_lims(1)
        firing_rate_lims(1)=min_rate-cond_stderr_aligned_firing_rates(min_rate_idx);
    end    
    [max_rate,max_rate_idx]=max(cond_mean_aligned_firing_rates(:));
    if max_rate>firing_rate_lims(2)
        firing_rate_lims(2)=max_rate+cond_stderr_aligned_firing_rates(max_rate_idx);
    end
end

colors=cbrewer('qual','Paired',12);

f=figure();
set(f, 'Position', get(0, 'Screensize'));

for cond_idx=1:length(conditions)
    cond_aligned_firing_rates=aligned_firing_rates{cond_idx};
    
    
    for r=1:length(align_events)
        ax=subplot(length(conditions),length(align_events),(cond_idx-1)*length(align_events)+r);
        fr_colors=get(gca,'ColorOrder');
        hold all;
        title(strrep(align_events{r},'_',' '));
        if r==1
            ylabel({sprintf('%s , %s', conditions{cond_idx}, array);length(find(strcmp(data.metadata.condition,conditions{cond_idx}))) ;'Firing rate'},'FontSize',12,'FontWeight','bold')
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
        ylim(firing_rate_lims);
        plot([0 0],ylim(),':k');    
        xlabel('Time (ms)');
        if r==length(align_events)
            orig_pos=get(ax,'Position');
            l=legend(handles, electrode_labels,'Location','bestoutside');
            set(ax,'Position',orig_pos);
        end
    end

    
end

date=strrep(date,'.','-');

saveas(f,fullfile(exp_info.base_output_dir,'HMM', 'betta', 'rake', [date '_' array '_vidfilFR_rake.png']));
saveas(f,fullfile(exp_info.base_output_dir,'HMM', 'betta', 'rake', [date '_' array '_vidfilFR_rake.eps']), 'epsc');
close(f);

date=strrep(date,'-','.');

f=figure();
set(f, 'Position', get(0, 'Screensize'));

for cond_idx=1:length(conditions)
    cond_aligned_p_states=aligned_p_states{cond_idx};
    
    for r=1:length(align_events)
        ax=subplot(length(conditions),length(align_events),(cond_idx-1)*length(align_events)+r);
        hold all
        title(strrep(align_events{r},'_',' '));
        ylim([0 1.2]);
        if r==1
            ylabel({sprintf('%s , %s', conditions{cond_idx}, array);length(find(strcmp(data.metadata.condition,conditions{cond_idx})));'State Probability'},'FontSize',12,'FontWeight','bold');
        end
        handles=[];
        state_labels={};
        %state_nums=cellfun(@str2num,model.state_labels);
        %for m=1:max(state_nums)
        for state_idx=1:n_states
            %state_idx=find(strcmp(model.state_labels,num2str(m)));
            %if length(state_idx)
                mean_pstate=squeeze(nanmean(cond_aligned_p_states(:,state_idx,r,:)));
                stderr_pstate=squeeze(nanstd(cond_aligned_p_states(:,state_idx,r,:)))./sqrt(size(cond_aligned_p_states,1));
                %H=shadedErrorBar([win_size(1):orig_binwidth:win_size(2)],mean_pstate,stderr_pstate,'LineProps',{'Color',colors(str2num(model.state_labels{state_idx}),:)});
                H=shadedErrorBar([win_size(1):binwidth:win_size(2)],mean_pstate,stderr_pstate,'LineProps',{'Color',colors(state_idx,:)});
                handles(end+1)=H.mainLine;
                state_labels{end+1}=sprintf('State %d', state_idx);%model.state_labels{state_idx};
            %end
        end

        plot([0 0],ylim(),':k');
        plot(xlim(),[0.6 0.6],'-.k');
        if cond_idx==length(conditions)
            xlabel('Time (ms)');
        end
        if r==length(align_events)
            orig_pos=get(ax,'Position');
            legend(handles, state_labels,'Location','bestoutside');
            set(ax,'Position',orig_pos);
        end
    end
end

date=strrep(date,'.','-');

saveas(f,fullfile(exp_info.base_output_dir,'HMM', 'betta', 'rake', [date '_' array '_vidfilHMM_rake.png']));
saveas(f,fullfile(exp_info.base_output_dir,'HMM', 'betta', 'rake', [date '_' array '_vidfilHMM_rake.eps']), 'epsc');
close(f);
end