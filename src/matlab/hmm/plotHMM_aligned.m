function aligned_p_states=plotHMM_aligned(exp_info, subject, dates, array, conditions, model)

addpath('../spike_data_processing');
date_data={};
for i=1:length(dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dates{i},'multiunit','binned',...
        sprintf('fr_b_%s_%s_whole_trial.mat', array, dates{i})));
    date_data{i}=data;
    clear('data');
end
addpath('../spike_data_processing');
data=concatenate_data(date_data, 'spike_times', false);
data=filter_data(exp_info, data);
orig_binwidth=1;
new_binwidth=10;
data2=rebin_spikes(data,new_binwidth);
data2=compute_firing_rate(data2, 'baseline_type', 'none', 'win_len', 6);

% Compute dt
dt=(data.bins(2)-data.bins(1))/1000;

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

aligned_p_states=zeros(length(condition_trials), model.n_states,...
    length(align_events), length([win_size(1):orig_binwidth:win_size(2)]));
aligned_firing_rates=zeros(length(condition_trials), length(data2.electrodes),...
    length(align_events), length([win_size(1):new_binwidth:win_size(2)]));

% For each alignment event
for r=1:length(align_events)
    align_evt=align_events{r};
    
    % Times of this event in all trials
    align_event_times = data.metadata.(align_evt);
    
    % Go through each trial
    if strcmp(model.type,'multivariate_poisson')
        for n=1:length(condition_trials)
            % Get the bins that we used in the HMM (time>0 and up to reward)
            bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(condition_trials(n)))));

            trial_spikes=squeeze(data.binned_spikes(1,:,condition_trials(n),bin_idx));
            
            % Decode
            PSTATES = hmmdecodePoiss(trial_spikes, model.ESTTR, model.ESTEMIT, dt);
            
            % Find time of alignment event in this trial
            event_time = align_event_times(condition_trials(n));

            % Window around event to get data
            win_start_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(1));
            win_end_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(2));
            event_wdw = [win_start_idx:win_end_idx];

            % Save p states within this window
            aligned_p_states(n,:,r,1:length(event_wdw)) = PSTATES(:,event_wdw);
        end
    elseif strcmp(model.type,'multilevel_multivariate_poisson')
        t_idx=1;
        for d=1:length(dates)
            day_trials=condition_trials(trial_date==d);
            
            effectiveE=model.GLOBAL_ESTEMIT+squeeze(model.DAY_ESTEMIT(d,:,:));
            for n=1:length(day_trials)
                % Get the bins that we used in the HMM (time>0 and up to reward)
                bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(day_trials(n)))));

                trial_spikes=squeeze(data.binned_spikes(1,:,day_trials(n),bin_idx));
                
                PSTATES = hmmdecodePoiss(trial_spikes, model.ESTTR,...
                    effectiveE, dt);
                
                % Find time of alignment event in this trial
                event_time = align_event_times(condition_trials(t_idx));

                % Window around event to get data
                win_start_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(1));
                win_end_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(2));
                event_wdw = [win_start_idx:win_end_idx];

                % Save p states within this window
                aligned_p_states(t_idx,:,r,1:length(event_wdw)) = PSTATES(:,event_wdw);
                t_idx=t_idx+1;
            end
        end
    elseif strcmp(model.type,'univariate_multinomial')
        for n=1:length(condition_trials)
            % Get the bins that we used in the HMM (time>0 and up to reward)
            bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(condition_trials(n)))));

            trial_spikes=squeeze(data.binned_spikes(1,:,condition_trials(n),bin_idx));
            
            % Create symbol sequence for this trial
            vec = create_symbol_vector(trial_spikes);
            
            % Run HMM decode
            PSTATES = hmmdecode(vec, model.ESTTR, model.ESTEMIT,...
                'Symbols', [0:32]);
                   
            % Find time of alignment event in this trial
            event_time = align_event_times(condition_trials(n));

            % Window around event to get data
            win_start_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(1));
            win_end_idx=knnsearch(data.bins(bin_idx)',event_time+win_size(2));
            event_wdw = [win_start_idx:win_end_idx];

            % Save p states within this window
            aligned_p_states(n,:,r,1:length(event_wdw)) = PSTATES(:,event_wdw);
        end
    end

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
    ax=subplot(2,length(align_events),r);
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

for r=1:length(align_events)
    ax=subplot(2,length(align_events),length(align_events)+r);
    hold all
    title(strrep(align_events{r},'_',' '));
    ylim([0 1.2]);
    if r==1
        ylabel({'Motor grasp: right, F1';' ';'State Probability'},'FontSize',20,'FontWeight','bold');
    end
    handles=[];
    state_labels={};
    state_nums=cellfun(@str2num,model.state_labels);
    for m=1:max(state_nums)
        state_idx=find(strcmp(model.state_labels,num2str(m)));
        if length(state_idx)
            %plot([win_size(1):win_size(2)],squeeze(mean(aligned_p_states(:,m,r,:))),'LineWidth',2);
            mean_pstate=squeeze(nanmean(aligned_p_states(:,state_idx,r,:)));
            stderr_pstate=squeeze(nanstd(aligned_p_states(:,state_idx,r,:)))./sqrt(size(aligned_p_states,1));
            H=shadedErrorBar([win_size(1):orig_binwidth:win_size(2)],mean_pstate,stderr_pstate,'LineProps',{'Color',colors(str2num(model.state_labels{state_idx}),:)});
            handles(end+1)=H.mainLine;
            state_labels{end+1}=model.state_labels{state_idx};
        end
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

%saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, [model_name '_average.png']));
%saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, [model_name '_average.eps']), 'epsc');
%close(f);
end
