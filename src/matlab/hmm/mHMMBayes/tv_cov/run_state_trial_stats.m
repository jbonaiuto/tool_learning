function run_state_trial_stats(subject, array, model, data, dates, conditions, varargin,output_path)

cond_labels={'center','right','left'};
state_trial_stats=extract_state_trial_stats(model, data, dates, 'min_time_steps',5);

state_color={'Greens','Oranges','Greys','Purples','RdPu','YlGn'};

lifetime=state_trial_stats.state_durations;
state_lbls={};
for s=1:model.n_states
     for t=1:data.ntrials
        if isempty(lifetime{s,t})
           lifetime{s,t}=0;
        end
     end
     state_lbls{s}=num2str(s);
end

% % ALL STATES ARE ACTIVATED PRETTY MUCH ONCE PER TRIAL SO THIS METRIC IS NOT VERY INTERESTING
% %each number of times a state becam active per trial overall conditions
% active_mat={};
% state_lbls={};
% for s=1:model.n_states
%    state_mat=zeros(data.ntrials,1);
%    for t=1:data.ntrials
%        state_mat(t)=length(state_trial_stats.state_onsets{s,t});
%    end
%    active_mat{s}=state_mat;
%    state_lbls{s}=num2str(s);
% end
% 
% plot_state_statistics(active_mat,state_lbls,'zero_bounded',true,'density_type','rash');
% xlabel('# activations');
% title('number of activation');
% 
% figure();
% for s_idx=1:model.n_states
%     ax=subplot(3,ceil(model.n_states/3),s_idx);
%     
%     active_mat_cond={};
%     for c_idx=1:length(conditions)
%         % Find data trials for this condition
%         condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
%     
%         active_mat=zeros(1,length(condition_trials));
%         for tc=1:length(condition_trials)
%             active_mat(tc)=length(state_trial_stats.state_onsets{s_idx,condition_trials(tc)});
%         end
%         active_mat_cond{c_idx}=active_mat;
%     end
%     [cb] = cbrewer2('seq',state_color{s_idx},10,'pchip');
%     plot_state_statistics_cond(active_mat_cond,cond_labels, cb,'zero_bounded',true,'density_type','rash','ax',ax);
%     if s_idx==model.n_states || s_idx==model.n_states-1
%         xlabel('# activations');
%     end
%     title(s_idx);
%     sgtitle('number of activation');
% end

% %% mean state lifetime based on the maximum activation length of a trial
% %(with 0ms duration)
% LT_max={};
% for s=1:model.n_states    
%     lt_mat=zeros(1,data.ntrials);
%     for t=1:data.ntrials
%         lt_mat(t)=max(lifetime{s,t});
%     end
%     LT_max{s}=lt_mat;
% end
% plot_state_statistics(LT_max,state_lbls,'zero_bounded',true,'density_type','rash');
% xlabel('max lifetime (ms)');
% title('mean state lifetime (based on max activation length)');
% 
% figure();
% for s_idx=1:model.n_states
%     ax=subplot(3,ceil(model.n_states/3),s_idx);    
%     LT_max_cond={};
%     for cond_idx=1:length(conditions)
%         condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
%         LT_max=zeros(1,length(condition_trials));
%         for tc=1:length(condition_trials)
%             LT_max(tc)=max(lifetime{s_idx,condition_trials(tc)});
%         end
%         LT_max_cond{cond_idx}=LT_max;
%     end
%     [cb] = cbrewer2('seq',state_color{s_idx},10,'pchip');
%     plot_state_statistics_cond(LT_max_cond,cond_labels, cb,'zero_bounded',true,'density_type','rash','ax',ax);
%     if s_idx==model.n_states || s_idx==model.n_states-1
%         xlabel('max lifetime (ms)');
%     end
%     title(s_idx);
%     sgtitle('mean state lifetime (based on max activation length)');
% end
% 
% %mean state lifetime based on the maximum activation length of a trial
% %(WITHOUT 0)
% lifetime=state_trial_stats.state_durations;
% LT_max={};
% for s=1:model.n_states    
%     lt_mat=[];
%     for t=1:data.ntrials
%         if ~isempty(lifetime{s,t})
%             lt_mat(end+1)=max(lifetime{s,t});
%         end
%     end
%     LT_max{s}=lt_mat;
% end
% plot_state_statistics(LT_max,state_lbls,'zero_bounded',true,'density_type','rash');
% xlabel('max lifetime (ms)');
% title('mean state lifetime (max activation without o ms activation)')
% 
% figure();
% for s_idx=1:model.n_states
%     ax=subplot(3,ceil(model.n_states/3),s_idx);    
%     LT_max_cond={};
%     for cond_idx=1:length(conditions)
%         condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
%         LT_max=[];
% 
%         for tc=1:length(condition_trials)
%             if ~isempty(lifetime{s_idx,condition_trials(tc)})
%                 LT_max(end+1)=max(lifetime{s_idx,condition_trials(tc)});
%             end            
%         end
%         LT_max_cond{cond_idx}=LT_max;
%     end
%     [cb] = cbrewer2('seq',state_color{s_idx},10,'pchip');
%     plot_state_statistics_cond(LT_max_cond,cond_labels, cb,'zero_bounded',true,'density_type','rash','ax',ax);
%     if s_idx==model.n_states || s_idx==model.n_states-1
%         xlabel('max lifetime (ms)');
%     end
%     title(s_idx);
%     sgtitle('mean state lifetime (max activation without o ms activation)');
% end
% 
% 
% %%
% 
% %mean state lifetime based on the sum of all durations of a trial
% LT_sum={};
% for s=1:model.n_states
%     lts=zeros(1,data.ntrials);
%     for t=1:data.ntrials
%         lts(t)=sum(state_trial_stats.state_durations{s,t});
%     end
%     LT_sum{s}=lts;
% end
% plot_state_statistics(LT_sum,state_lbls,'zero_bounded',true,'density_type','rash');
% xlabel('total lifetime (ms)');
% title('mean state lifetime (based on the sum of state activation in the trial)');
% 
% 
% figure();
% for s_idx=1:model.n_states
%     ax=subplot(3,ceil(model.n_states/3),s_idx);    
%     LT_sum_cond={};
%     for cond_idx=1:length(conditions)
%         condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
%         LT_sum=zeros(1,length(condition_trials));
%         for tc=1:length(condition_trials)
%             LT_sum(tc)=sum(state_trial_stats.state_durations{s_idx,condition_trials(tc)});
%         end            
%         LT_sum_cond{cond_idx}=LT_sum;
%     end
%     [cb] = cbrewer2('seq',state_color{s_idx},10,'pchip');
%     plot_state_statistics_cond(LT_sum_cond,cond_labels, cb,'zero_bounded',true,'density_type','rash','ax',ax);
%     if s_idx==model.n_states || s_idx==model.n_states-1
%         xlabel('total lifetime (ms)');
%     end
%     title(s_idx);
%     sgtitle('mean state lifetime (based on the sum of state activation in the trial)');
% end
% 
% %%
% % fractional occupancy
% fractional_time={};
% for s=1:model.n_states
%     frac_mat=zeros(1,data.ntrials);
%     for t=1:data.ntrials
%         frac_mat(t)=(sum(state_trial_stats.state_durations{s,t})/data.metadata.reward(t))*100.0;
%     end
%     fractional_time{s}=frac_mat;
% end
% plot_state_statistics(fractional_time,state_lbls,'zero_bounded',true,'density_type','rash');
% xlabel('fractional occupancy');
% title('fractional occupancy');
% 
% figure();
% for s_idx=1:model.n_states
%     ax=subplot(3,ceil(model.n_states/3),s_idx);    
%     FT_cond={};
%     for cond_idx=1:length(conditions)
%         condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
%         ft_mat=zeros(1,length(condition_trials));
%         for tc=1:length(condition_trials)
%             ft_mat(tc)=(sum(state_trial_stats.state_durations{s_idx,condition_trials(tc)})/data.metadata.reward(condition_trials(tc))).*100.0;
%         end            
%         FT_cond{cond_idx}=ft_mat;
%     end
%     [cb] = cbrewer2('seq',state_color{s_idx},10,'pchip');
%     plot_state_statistics_cond(FT_cond,cond_labels, cb,'zero_bounded',true,'density_type','rash','ax',ax);
%     if s_idx==model.n_states || s_idx==model.n_states-1
%         xlabel('fractional occupancy');
%     end
%     title(s_idx);
%     sgtitle('fractional occupancy');
% end

%%
%mean fractional occupancy
fractional_time={};
for s=1:model.n_states
    frac_mat=zeros(1,data.ntrials);
    for t=1:data.ntrials
        frac_mat(t)=(mean(state_trial_stats.state_durations{s,t})/data.metadata.reward(t))*100.0;
    end
    NaN_idx=find(isnan(frac_mat));
    frac_mat(NaN_idx)=0;
%   frac_mat(NaN_idx)=[];
    fractional_time{s}=frac_mat;
end
plot_state_statistics(fractional_time,state_lbls,'zero_bounded',true,'density_type','rash');
xlabel('fractional occupancy (%)');
title('mean fractional occupancy');

figure();
for s_idx=1:model.n_states
    ax=subplot(3,ceil(model.n_states/3),s_idx);    
    FT_cond={};
    for cond_idx=1:length(conditions)
        condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
        ft_mat=zeros(1,length(condition_trials));
        for tc=1:length(condition_trials)
            ft_mat(tc)=(mean(state_trial_stats.state_durations{s_idx,condition_trials(tc)})/data.metadata.reward(condition_trials(tc))).*100.0;
        end   
        NaN_idx=find(isnan(ft_mat));
        ft_mat(NaN_idx)=0;
        FT_cond{cond_idx}=ft_mat;
    end
    [cb] = cbrewer2('seq',state_color{s_idx},10,'pchip');
    plot_state_statistics_cond(FT_cond,cond_labels, cb,'zero_bounded',true,'density_type','rash','ax',ax);
    if s_idx==model.n_states || s_idx==model.n_states-1
        xlabel('fractional occupancy(%)');
    end
    title(s_idx);
    sgtitle('mean fractional occupancy');
end

%%
%state interval time (time between two visits in the same state)
time_interval={};
for s=1:model.n_states
    interval_mat=[];
    for t=1:data.ntrials
        offset=state_trial_stats.state_offsets{s,t};
        onset=state_trial_stats.state_onsets{s,t};
        if length(offset)>1
            interval_mat(end+1)=mean(onset(2:end)-offset(1:end-1));
        end
    end
    time_interval{s}=interval_mat;
end
plot_state_statistics(time_interval,state_lbls,'zero_bounded',true,'density_type','rash');
xlabel('interval (ms)');
title('state interval time (time between two visits in the same state)');

figure();
for s_idx=1:model.n_states
    ax=subplot(3,ceil(model.n_states/3),s_idx);    
    interval_cond={};
    for cond_idx=1:length(conditions)
        condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
        interval_mat=[];
        for tc=1:length(condition_trials)
            offset=state_trial_stats.state_offsets{s_idx,condition_trials(tc)};
            onset=state_trial_stats.state_onsets{s_idx,condition_trials(tc)};
            if length(offset)>1
                interval_mat(end+1)=mean(onset(2:end)-offset(1:end-1));
            end
        end
        interval_cond{cond_idx}=interval_mat;
    end
    [cb] = cbrewer2('seq',state_color{s_idx},10,'pchip');
    plot_state_statistics_cond(interval_cond,cond_labels, cb,'zero_bounded',true,'density_type','rash','ax',ax);
    if s_idx==model.n_states || s_idx==model.n_states-1
        xlabel('interval (ms)');
    end
    title(s_idx);
    sgtitle('state interval time (time between two visits in the same state)');
end

end