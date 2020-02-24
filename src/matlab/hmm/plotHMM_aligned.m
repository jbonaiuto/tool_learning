function plotHMM_aligned(exp_info, subject, model_name)

dbstop if error

file_name=fullfile(exp_info.base_output_dir, 'HMM', subject, model_name, 'hmm_results.mat');
load(file_name);
model=hmm_results.models(hmm_results.best_model_idx(1),hmm_results.best_model_idx(2));

addpath('../spike_data_processing');
date_data={};
for i=1:length(hmm_results.dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, hmm_results.dates{i},'multiunit','binned',sprintf('fr_b_F1_%s_whole_trial.mat',hmm_results.dates{i})));
    date_data{i}=data;
    clear('data');
end

data=concatenate_data(date_data, 'spike_times', false);
condition_trials=find(strcmp(data.metadata.condition,'motor_grasp_right'));
clear('date_data');

%Align events

align_events={'go','hand_mvmt_onset','obj_contact','place'};

win_size=[-140 140];

aligned_p_states=zeros(length(hmm_results.SEQ),model.n_states,length(align_events),win_size(2)-win_size(1)+1);
aligned_firing_rates=zeros(length(hmm_results.SEQ),length(data.electrodes),length(align_events),win_size(2)-win_size(1)+1);

% For each alignment event
for r=1:length(align_events)
    align_evt=align_events{r};
    
    % Times of this event in all trials
    align_event_times = data.metadata.(align_evt);
    
    % Go through each trial
    for n=1:length(hmm_results.SEQ)
        
        % Run HMM decode
        PSTATES = hmmdecode(hmm_results.SEQ{n},model.ESTTR,model.ESTEMIT,'Symbols',[0:32]);
        
        % Find time of alignment event in this trial
        event_time = align_event_times(condition_trials(n));
        
        % Find bin that this event occurs in
        event_bin = knnsearch(data.bins(data.bins>0)',round(event_time));
        
        % Window around event to get data
        event_wdw = [event_bin+win_size(1):min([size(PSTATES,2) event_bin+win_size(2)])];
        
        % Save p states within this window
        aligned_p_states(n,:,r,1:length(event_wdw)) = PSTATES(:,event_wdw);
        
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(condition_trials(n)))));
        
        % Get firing rates for this trial
        trial_firing_rates=squeeze(data.smoothed_firing_rate(1,:,condition_trials(n),bin_idx));
        
        % Save firing rates in this window
        aligned_firing_rates(n,:,r,1:length(event_wdw))=trial_firing_rates(:,event_wdw);
    
    end
end

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
        H=shadedErrorBar([win_size(1):win_size(2)],mean_fr,stderr_fr,'LineProps',{'Color',fr_colors(mod(m-1,7)+1,:)});
        handles(end+1)=H.mainLine;
        electrode_labels{end+1}=sprintf('electrode %d',m);
    end
    ylim([-50 2000]);
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
    for m=1:hmm_results.n_states
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

saveas(f,fullfile(exp_info.base_output_dir, 'figures\HMM', subject, [model_name '_average.png']));
saveas(f,fullfile(exp_info.base_output_dir, 'figures\HMM', subject, [model_name '_average.eps']), 'epsc');
close(f);
end
