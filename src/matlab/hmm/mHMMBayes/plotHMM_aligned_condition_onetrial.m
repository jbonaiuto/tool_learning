function [aligned_forward_probs,f]=plotHMM_aligned_condition_onetrial(subject, array, electrodes, data, dates, conditions, model, output_path)


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
data10ms=compute_firing_rate(data10ms, 'baseline_type', 'none', 'win_len', 6);
 
% Compute bin width
binwidth=(data10ms.bins(2)-data10ms.bins(1));

% Align events
%align_events={'go','hand_mvmt_onset','obj_contact','place'};
align_events='go';

conditions='motor_grasp_center';

%dates='08.03.19'; %% then d=8

% Size of epochs around each align event
win_size=[-500 1500];


for cond_idx=1:length(conditions)
    % Find data trials for this condition
    condition_trials = find(strcmp(data10ms.metadata.condition,conditions));
    
    % Date index of each trial for this condition
    trial_date=data10ms.trial_date(condition_trials);
    
    % Aligned forward probabilities and firing rates for this condition
    trial_forward_probs=[];
    trial_firing_rates=[];

    for r=1
        align_evt=align_events;
        
        % Times of this event in all trials
        align_event_times = data10ms.metadata.(align_evt);

        % Go through each trial
        t_idx=1;

        % For every date
        for d=8 %the number of the data I'm working on in the data structure        1:length(dates)
        
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
                bin_idx=find((data10ms.bins>=0) & (data10ms.bins<=data10ms.metadata.reward(day_trials(n))));

                % Find time of alignment event in this trial
                event_time = align_event_times(day_trials(n));
                
                % Window around event to get data
                %win_start_idx=1;
                win_start_idx=knnsearch(data10ms.bins(bin_idx)',event_time+win_size(1));
                win_end_idx=knnsearch(data10ms.bins(bin_idx)',event_time+win_size(2));
                event_wdw =[win_start_idx:win_end_idx];

                % Save p states within this window
                for i=1:model.n_states
                    sprobs=model.forward_probs.(sprintf('fw_prob_S%d',i));
                    %trial_forward_probs(i,:) = sprobs(trial_rows);
                    trial_forward_probs(t_idx,i,r,1:length(event_wdw)) = sprobs(trial_rows(event_wdw));
                end

                % Get firing rates for this trial
                trial_firing_rates=squeeze(data10ms.smoothed_firing_rate(1,:,day_trials(n),:));
                
                % Save firing rates in this window
                win_rates=trial_firing_rates(:,event_wdw);
                cond_firing_rates(t_idx,:,r,1:size(win_rates,2))=win_rates;    
                t_idx=t_idx+1;
            end
        end
    end
end

colors=cbrewer2('qual','Dark2',12);

for t_idx=1:length(day_trials)

    figure();
    subplot(2,1,1);
    electrode_labels={};
    for e=1:length(electrodes)
        el=electrodes(e);
        %plot(data.bins(bin_idx)-event_time,trial_firing_rates(:,bin_idx)');
        plot([win_size(1):binwidth:win_size(2)],squeeze(cond_firing_rates(t_idx,el,r,:)));
        hold on
        electrode_labels{end+1}=sprintf('electrode %d',el);
    end
    ylabel('Firing Rate (Hz)','FontSize',12,'FontWeight','bold');
    xlim(win_size);
    plot([0 0],ylim(),':k');
    legend(electrode_labels,'Location','bestoutside');
    
    subplot(2,1,2);
    hold on       
    ylabel('State Probability','FontSize',12,'FontWeight','bold');
    handles=[];
    state_labels={};
    %state_nums=cellfun(@str2num,model.metadata.state_labels);
    state_nums=model.metadata.state_labels;
    for m=1:max(state_nums)
        state_idx=state_nums(m);
        plot([win_size(1):binwidth:win_size(2)],squeeze(trial_forward_probs(t_idx,state_idx,r,:)),'Color',colors(m,:),'LineWidth',2)
        state_labels{end+1}=sprintf('State %s', model.metadata.state_labels(state_idx));
    end
 
    el_idx=[1:length(electrodes)]./(length(electrodes)+1);
    for el=1:length(electrodes)
        raster_data=squeeze(cond_firing_rates(t_idx,el,r,:));
        bin_idx=find(raster_data);
        raster_data(bin_idx)=1;
        %plot(spike_times, el_idx(el).*ones(size(spike_times)),'.k');
        plot([win_size(1):binwidth:win_size(2)], el_idx(el).*raster_data,'.k','LineWidth',4);
    end

    %                 plot([0 0],[0 1],':k');
    %                 plot(xlim(),[1/model.n_states 1/model.n_states],'-.k');
        %xlim([win_start_idx win_end_idx]);
        ylim([0 1]);
        xlabel('Time (ms)');
        xlim(win_size);
        plot([0 0],ylim(),':k');
        legend(state_labels,'Location','bestoutside');
end

end

%%% add raster plot %%%

%  bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(hmm_results.trials(n)))));
%     raster_data=squeeze(data.binned_spikes(:,:,hmm_results.trials(n),bin_idx));
%     neuron_idx=[1:32]./33;
%     for n_idx=1:32
%         spike_times=find(raster_data(n_idx,:)==1);
%         plot(spike_times, neuron_idx(n_idx).*ones(size(spike_times)),'.k');
%     end
%     xlim([data.bins(bin_idx(1)) data.bins(bin_idx(end))]);
%     plot(xlim(),[0.6 0.6],'-.k');






  %%plot trials here  
        
%     
%     aligned_forward_probs{cond_idx}=cond_forward_probs;
%     aligned_firing_rates{cond_idx}=cond_firing_rates;    
% 
% 
% % Compute firing rate limits
% firing_rate_lims=[Inf -Inf];
% for cond_idx=1:length(conditions)
%     cond_mean_aligned_firing_rates=squeeze(mean(aligned_firing_rates{cond_idx}));
%     cond_stderr_aligned_firing_rates=squeeze(std(aligned_firing_rates{cond_idx}))./sqrt(size(aligned_firing_rates{cond_idx},1));
%     [min_rate,min_rate_idx]=min(cond_mean_aligned_firing_rates(:)-cond_stderr_aligned_firing_rates(:));
%     if min_rate<firing_rate_lims(1)
%         firing_rate_lims(1)=min_rate;
%     end    
%     [max_rate,max_rate_idx]=max(cond_mean_aligned_firing_rates(:)+cond_stderr_aligned_firing_rates(:));
%     if max_rate>firing_rate_lims(2)
%         firing_rate_lims(2)=max_rate;
%     end
% end
% 
% %colors=cbrewer('qual','Paired',12);
% colors=cbrewer('qual','Dark2',12);
% 
% f=figure();
% set(f, 'Position', [0 88 889 987]);
% 
% for cond_idx=1:length(conditions)
%     cond_aligned_firing_rates=aligned_firing_rates{cond_idx};
%     cond_aligned_p_states=aligned_forward_probs{cond_idx};
%     
%     for r=1:length(align_events)
%         ax=subplot(2*length(conditions),length(align_events),2*(cond_idx-1)*length(align_events)+r);
%         fr_colors=get(gca,'ColorOrder');
%         hold all;
%         if cond_idx==1
%             title(strrep(align_events{r},'_',' '));
%         end
%         if r==1
%             ylabel({strrep(conditions{cond_idx},'_',' ');'Firing rate'},'FontSize',12,'FontWeight','bold');
%         end
%         handles=[];
%         electrode_labels={};
%         for m=1:length(data.electrodes)
%             mean_fr=squeeze(mean(cond_aligned_firing_rates(:,m,r,:)));
%             stderr_fr=squeeze(std(cond_aligned_firing_rates(:,m,r,:)))./sqrt(size(cond_aligned_firing_rates,1));
%             H=shadedErrorBar([win_size(1):binwidth:win_size(2)],mean_fr,stderr_fr,'LineProps',{'Color',fr_colors(mod(m-1,7)+1,:)});
%             handles(end+1)=H.mainLine;
%             electrode_labels{end+1}=sprintf('electrode %d',m);
%         end
%         xlim(win_size);
%         ylim(firing_rate_lims);
%         plot([0 0],ylim(),':k');    
%     end
% 
%     for r=1:length(align_events)
%         ax=subplot(2*length(conditions),length(align_events),2*(cond_idx-1)*length(align_events)+length(align_events)+r);
%         hold all        
%         if r==1
%             ylabel('State Probability','FontSize',12,'FontWeight','bold');
%         end
%         handles=[];
%         state_labels={};
%         state_nums=cellfun(@str2num,model.metadata.state_labels);
%         for m=1:max(state_nums)
%             state_idx=find(strcmp(model.metadata.state_labels,num2str(m)));
%             if length(state_idx)
%                 mean_pstate=squeeze(nanmean(cond_aligned_p_states(:,state_idx,r,:)));
%                 stderr_pstate=squeeze(nanstd(cond_aligned_p_states(:,state_idx,r,:)))./sqrt(size(cond_aligned_p_states,1));
%                 H=shadedErrorBar([win_size(1):binwidth:win_size(2)],mean_pstate,stderr_pstate,'LineProps',{'Color',colors(m,:)});
%                 handles(end+1)=H.mainLine;
%                 state_labels{end+1}=sprintf('State %s', model.metadata.state_labels{state_idx});
%             end
%         end
% 
%         plot([0 0],[0 1],':k');
%         plot(xlim(),[1/model.n_states 1/model.n_states],'-.k');
%         xlim(win_size);
%         ylim([0 1]);
%         if cond_idx==length(conditions)
%             xlabel('Time (ms)');
%         end
%         if cond_idx==1 && r==length(align_events)
%             orig_pos=get(ax,'Position');
%             legend(handles, state_labels,'Location','bestoutside');
%             set(ax,'Position',orig_pos);
%         end
%     end
% end
