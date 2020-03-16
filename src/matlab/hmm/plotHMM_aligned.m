function plotHMM_aligned(exp_info, subject, model_name, varargin)

% Parse optional arguments
defaults=struct('n_states',[]);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

dbstop if error

file_name=fullfile(exp_info.base_output_dir, 'HMM', subject, model_name, 'hmm_results.mat');
load(file_name);
hmm_results = select_best_model(exp_info, hmm_results, model_name,'method','AIC+BIC');
if length(params.n_states)==0
    model=hmm_results.models(hmm_results.best_model_idx(1),hmm_results.best_model_idx(2));
else
    idx=find(hmm_results.n_state_possibilities==params.n_states);
    model=hmm_results.models(idx,hmm_results.maxLL_idx_storing(idx));
end

addpath('../spike_data_processing');
date_data={};
for i=1:length(hmm_results.dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, hmm_results.dates{i},'multiunit','binned',sprintf('fr_b_F1_%s_whole_trial.mat',hmm_results.dates{i})));
    date_data{i}=data;
    clear('data');
end

data=concatenate_data(date_data, 'spike_times', false);

new_binwidth=10;
%new_binwidth=1;
data2=rebin_spikes(data,new_binwidth);
data2=compute_firing_rate(data2, 'baseline_type', 'none', 'win_len', 6);
%data2=compute_firing_rate(data2, 'baseline_type', 'none', 'win_len', 60);

condition_trials=find(strcmp(data.metadata.condition,'motor_grasp_right'));
clear('date_data');

nonoutlier_trials=condition_trials;%exclude_outliers(data2, condition_trials);

%Align events
align_events={'go','hand_mvmt_onset','obj_contact','place'};

win_size=[-140 140];

aligned_p_states=zeros(length(condition_trials),model.n_states,length(align_events),win_size(2)-win_size(1)+1);
aligned_firing_rates=zeros(length(nonoutlier_trials),length(data.electrodes),length(align_events),length([win_size(1):new_binwidth:win_size(2)]));

% For each alignment event
for r=1:length(align_events)
    align_evt=align_events{r};
    
    % Times of this event in all trials
    align_event_times = data.metadata.(align_evt);
    
    % Go through each trial
    if isfield(hmm_results,'trial_spikes')
        for n=1:length(hmm_results.trial_spikes)
            PSTATES = hmmdecodePoiss(hmm_results.trial_spikes{n},model.ESTTR,model.ESTEMIT,.001);
            % Get the bins that we used in the HMM (time>0 and up to reward)
            bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(condition_trials(n)))));

            % Find time of alignment event in this trial
            event_time = align_event_times(condition_trials(n));

            % Window around event to get data
            event_wdw = [knnsearch(data.bins(bin_idx)',event_time+win_size(1)):knnsearch(data.bins(bin_idx)',event_time+win_size(2))];

            % Save p states within this window
            aligned_p_states(n,:,r,1:length(event_wdw)) = PSTATES(:,event_wdw);
        end
    elseif isfield(hmm_results,'day_spikes')
        t_idx=1;
        for d=1:length(hmm_results.day_spikes)
            trial_spikes=hmm_results.day_spikes{d};
            effectiveE=model.GLOBAL_ESTEMIT+squeeze(model.DAY_ESTEMIT(d,:,:));
            for n=1:length(trial_spikes)
                PSTATES = hmmdecodePoiss(trial_spikes{n},model.ESTTR,effectiveE,.001);
                % Get the bins that we used in the HMM (time>0 and up to reward)
                bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(condition_trials(t_idx)))));

                % Find time of alignment event in this trial
                event_time = align_event_times(condition_trials(t_idx));

                % Window around event to get data
                event_wdw = [knnsearch(data.bins(bin_idx)',event_time+win_size(1)):knnsearch(data.bins(bin_idx)',event_time+win_size(2))];

                % Save p states within this window
                aligned_p_states(t_idx,:,r,1:length(event_wdw)) = PSTATES(:,event_wdw);
                t_idx=t_idx+1;
            end
        end
    else
        for n=1:length(hmm_results.SEQ)

            % Run HMM decode
            PSTATES = hmmdecode(hmm_results.SEQ{n},model.ESTTR,model.ESTEMIT,'Symbols',[0:32]);
            
            % Get the bins that we used in the HMM (time>0 and up to reward)
            bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(condition_trials(n)))));

            % Find time of alignment event in this trial
            event_time = align_event_times(condition_trials(n));

            % Window around event to get data
            event_wdw = [knnsearch(data.bins(bin_idx)',event_time+win_size(1)):knnsearch(data.bins(bin_idx)',event_time+win_size(2))];

            % Save p states within this window
            aligned_p_states(n,:,r,1:length(event_wdw)) = PSTATES(:,event_wdw);
        end
    end

    for n=1:length(nonoutlier_trials)
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data2.bins>=0) & (data2.bins<(data2.metadata.reward(nonoutlier_trials(n)))));
        
        % Get firing rates for this trial
        trial_firing_rates=squeeze(data2.smoothed_firing_rate(1,:,nonoutlier_trials(n),bin_idx));
        
        % Find time of alignment event in this trial
        event_time = align_event_times(nonoutlier_trials(n));
        
        % Window around event to get data
        event_wdw = [knnsearch(data2.bins(bin_idx)',event_time+win_size(1)):knnsearch(data2.bins(bin_idx)',event_time+win_size(2))];
        
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
    for m=1:model.n_states
        %plot([win_size(1):win_size(2)],squeeze(mean(aligned_p_states(:,m,r,:))),'LineWidth',2);
        mean_pstate=squeeze(mean(aligned_p_states(:,m,r,:)));
        stderr_pstate=squeeze(std(aligned_p_states(:,m,r,:)))./sqrt(size(aligned_p_states,1));
        H=shadedErrorBar([win_size(1):win_size(2)],mean_pstate,stderr_pstate,'LineProps',{'Color',colors(m,:)});
        handles(end+1)=H.mainLine;
        state_labels{end+1}=sprintf('state %d',m);
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

saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, [model_name '_average.png']));
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, [model_name '_average.eps']), 'epsc');
%close(f);
end
