function run_state_trial_stats(model, data, dates, conditions, output_path)

cond_labels={'center','right','left'};
state_trial_stats=extract_state_trial_stats(model, data, dates, 'min_time_steps',5);

state_color={'Greens','Oranges','Purples','RdPu','YlGn','YlOrRd'};

state_lbls={};
for s=1:model.n_states
    state_lbls{s}=num2str(s);
end

% % ALL STATES ARE ACTIVATED PRETTY MUCH ONCE PER TRIAL SO THIS METRIC IS NOT VERY INTERESTING
% %each number of times a state becam active per trial overall conditions
active_mat={};
fname=fullfile(output_path,sprintf('model_tv_%s_activations.csv',model.name));
fid=fopen(fname,'w');
fprintf(fid,'day,trial,condition,state,activations\n');
for s=1:model.n_states
   state_mat=zeros(data.ntrials,1);
   state_idx=find(model.metadata.state_labels==s);
   for t=1:data.ntrials
       date=data.trial_date(t);
       condition=data.metadata.condition{t};
       activations=length(state_trial_stats.state_onsets{state_idx,t});
       fprintf(fid,'%d,%d,%s,%d,%d\n',date,t,condition,s,activations);
       state_mat(t)=activations;
   end
   active_mat{s}=state_mat;
end
fclose(fid);

figure();
ax=subplot(3,2+ceil(model.n_states/3),[1:2, 3+ceil(model.n_states/3):4+ceil(model.n_states/3), 7+ceil(model.n_states/3):8+ceil(model.n_states/3)]);
plot_state_statistics(active_mat,state_lbls, 'zero_bounded',true,'density_type','rash','ax',ax);
xlabel('# activations');
title('number of activation');
 
for s_idx=1:model.n_states
    ax=subplot(3,2+ceil(model.n_states/3),floor((s_idx-1)/ceil(model.n_states/3))*(2+ceil(model.n_states/3))+(3+(mod(s_idx-1,ceil(model.n_states/3)))));
    state_idx=find(model.metadata.state_labels==s_idx);
    
    active_mat_cond={};
    for c_idx=1:length(conditions)
        % Find data trials for this condition
        condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
    
        active_mat=zeros(1,length(condition_trials));
        for tc=1:length(condition_trials)
            active_mat(tc)=length(state_trial_stats.state_onsets{state_idx,condition_trials(tc)});
        end
        active_mat_cond{c_idx}=active_mat;
    end
    [cb] = cbrewer('seq',state_color{state_idx},10,'pchip');
    plot_state_statistics_cond(active_mat_cond,cond_labels, cb,state_idx,'zero_bounded',true,'density_type','rash','ax',ax);
    xlabel('# activations');
    title(sprintf('Activations: %d', s_idx));
end

%% mean state lifetime based on the maximum activation length of a trial
%(with 0ms duration)
lifetime=state_trial_stats.state_durations;
for s=1:model.n_states
    for t=1:data.ntrials
        if isempty(lifetime{s,t})
           lifetime{s,t}=0;
        end
    end
end
LT={};
fname=fullfile(output_path,sprintf('model_tv_%s_lifetime.csv',model.name));
fid=fopen(fname,'w');
fprintf(fid,'day,trial,condition,state,lifetime\n');
for s=1:model.n_states
    state_idx=find(model.metadata.state_labels==s);
    lt_mat=zeros(1,data.ntrials);
    for t=1:data.ntrials
        date=data.trial_date(t);
        condition=data.metadata.condition{t};
        trial_lifetimes=lifetime{state_idx,t};
        %lt=max(trial_lifetimes);
        lt=trial_lifetimes(1);
        fprintf(fid,'%d,%d,%s,%d,%.4f\n',date,t,condition,s,lt);
        lt_mat(t)=lt;
    end
    LT{s}=lt_mat;
end
fclose(fid);

figure();
ax=subplot(3,2+ceil(model.n_states/3),[1:2, 3+ceil(model.n_states/3):4+ceil(model.n_states/3), 7+ceil(model.n_states/3):8+ceil(model.n_states/3)]);
plot_state_statistics(LT,state_lbls,'zero_bounded',true,'density_type','rash','ax',ax);
xlabel('Max lifetime (ms)');
title('Lifetime');

for s_idx=1:model.n_states
    state_idx=find(model.metadata.state_labels==s_idx);
    ax=subplot(3,2+ceil(model.n_states/3),floor((s_idx-1)/ceil(model.n_states/3))*(2+ceil(model.n_states/3))+(3+(mod(s_idx-1,ceil(model.n_states/3)))));
    LT_max_cond={};
    for cond_idx=1:length(conditions)
        condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
        LT=zeros(1,length(condition_trials));
        for tc=1:length(condition_trials)
            trial_lifetimes=lifetime{state_idx,condition_trials(tc)};
            %LT(tc)=max(trial_lifetimes);
            LT(tc)=trial_lifetimes(1);
        end
        LT_max_cond{cond_idx}=LT;
    end
    [cb] = cbrewer('seq',state_color{s_idx},10,'pchip');
    plot_state_statistics_cond(LT_max_cond,cond_labels, cb,s_idx,'zero_bounded',true,'density_type','rash','ax',ax);
    if s_idx==model.n_states || s_idx==model.n_states-1
        xlabel('max lifetime (ms)');
    end
    title(sprintf('Lifetime: %d',s_idx));
end

%%
% % fractional occupancy
% fractional_time={};
% fname=fullfile(output_path,sprintf('model_tv_%s_fractional_occupancy.csv',model.name));
% fid=fopen(fname,'w');
% fprintf(fid,'day,trial,condition,state,fractional_occupancy\n');
% for s=1:model.n_states
%     state_idx=find(model.metadata.state_labels==s);
%     frac_mat=zeros(1,data.ntrials);
%     for t=1:data.ntrials
%         date=data.trial_date(t);
%         condition=data.metadata.condition{t};
%         fo=(sum(state_trial_stats.state_durations{state_idx,t})/data.metadata.reward(t))*100.0;
%         fprintf(fid,'%d,%d,%s,%d,%.4f\n',date,t,condition,s,fo);
%         frac_mat(t)=fo;
%     end
%     fractional_time{s}=frac_mat;
% end
% fclose(fid);
% 
% figure();
% ax=subplot(3,2+ceil(model.n_states/3),[1:2, 3+ceil(model.n_states/3):4+ceil(model.n_states/3), 7+ceil(model.n_states/3):8+ceil(model.n_states/3)]);
% plot_state_statistics(fractional_time,state_lbls,'zero_bounded',true,'density_type','rash','ax',ax);
% xlabel('fractional occupancy');
% title('fractional occupancy');
% 
% for s_idx=1:model.n_states
%     state_idx=find(model.metadata.state_labels==s_idx);         
%     ax=subplot(3,2+ceil(model.n_states/3),floor((s_idx-1)/ceil(model.n_states/3))*(2+ceil(model.n_states/3))+(3+(mod(s_idx-1,ceil(model.n_states/3)))));
%     FT_cond={};
%     for cond_idx=1:length(conditions)
%         condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
%         ft_mat=zeros(1,length(condition_trials));
%         for tc=1:length(condition_trials)
%             ft_mat(tc)=(sum(state_trial_stats.state_durations{state_idx,condition_trials(tc)})/data.metadata.reward(condition_trials(tc))).*100.0;
%         end            
%         FT_cond{cond_idx}=ft_mat;
%     end
%     [cb] = cbrewer('seq',state_color{s_idx},10,'pchip');
%     plot_state_statistics_cond(FT_cond,cond_labels, cb,s_idx,'zero_bounded',true,'density_type','rash','ax',ax);
%     if s_idx==model.n_states || s_idx==model.n_states-1
%         xlabel('fractional occupancy');
%     end
%     title(sprintf('Fractional occupancy: %d',s_idx));
% end
% 
% %%
% %state interval time (time between two visits in the same state)
% time_interval={};
% fname=fullfile(output_path,sprintf('model_tv_%s_interstate_interval.csv',model.name));
% fid=fopen(fname,'w');
% fprintf(fid,'day,trial,condition,state,interstate_interval\n');
% for s=1:model.n_states
%     state_idx=find(model.metadata.state_labels==s);
%     interval_mat=[];
%     for t=1:data.ntrials
%         offset=state_trial_stats.state_offsets{state_idx,t};
%         onset=state_trial_stats.state_onsets{state_idx,t};
%         if length(offset)>1
%             date=data.trial_date(t);
%             condition=data.metadata.condition{t};
%             isi=mean(onset(2:end)-offset(1:end-1));
%             fprintf(fid,'%d,%d,%s,%d,%.4f\n',date,t,condition,s,isi);
%             interval_mat(end+1)=isi;
%         end
%     end
%     time_interval{s}=interval_mat;
% end
% fclose(fid);
% 
% figure();
% ax=subplot(3,2+ceil(model.n_states/3),[1:2, 3+ceil(model.n_states/3):4+ceil(model.n_states/3), 7+ceil(model.n_states/3):8+ceil(model.n_states/3)]);
% plot_state_statistics(time_interval,state_lbls,'zero_bounded',true,'density_type','rash','ax',ax);
% xlabel('interval (ms)');
% title('state interval time (time between two visits in the same state)');
% 
% for s_idx=1:model.n_states
%     state_idx=find(model.metadata.state_labels==s_idx);
%     ax=subplot(3,2+ceil(model.n_states/3),floor((s_idx-1)/ceil(model.n_states/3))*(2+ceil(model.n_states/3))+(3+(mod(s_idx-1,ceil(model.n_states/3)))));
%     interval_cond={};
%     for cond_idx=1:length(conditions)
%         condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
%         interval_mat=[];
%         for tc=1:length(condition_trials)
%             offset=state_trial_stats.state_offsets{state_idx,condition_trials(tc)};
%             onset=state_trial_stats.state_onsets{state_idx,condition_trials(tc)};
%             if length(offset)>1
%                 interval_mat(end+1)=mean(onset(2:end)-offset(1:end-1));
%             end
%         end
%         interval_cond{cond_idx}=interval_mat;
%     end
%     [cb] = cbrewer('seq',state_color{s_idx},10,'pchip');
%     plot_state_statistics_cond(interval_cond,cond_labels,cb,s_idx,'zero_bounded',true,'density_type','rash','ax',ax);
%     if s_idx==model.n_states || s_idx==model.n_states-1
%         xlabel('interval (ms)');
%     end
%     title(sprintf('Inter-state interval: %d',s_idx));
% end

end