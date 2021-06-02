array='F1';
subject='betta';
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};
dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
    '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19'};
dt=10;
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '10w_multiday_condHMM', array);
% Load best model (lowest AIC)
model=get_best_model(output_path, 'type', 'condition_covar');
load(fullfile(output_path,'data.mat'));
state_trial_stats=extract_state_trial_stats(model, data, dates);


%each number of times a state becam active per trial overall conditions
active_mat=zeros(model.n_states,data.ntrials);

for s=1:model.n_states
   for t=1:data.ntrials
       active_mat(s,t)=length(state_trial_stats.state_onsets{s,t});
   end
end
mean_active_mat=mean(active_mat,2);


%each number of times a state becam active per trial for each condition
mean_active_mat_cond=zeros(length(conditions),model.n_states);

for cond_idx=1:length(conditions)
    % Find data trials for this condition
    condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
    
    active_mat_cond=zeros(model.n_states,length(condition_trials));
    for sc=1:model.n_states
        state_onsets_cond=state_trial_stats.state_onsets(:,condition_trials);
        for tc=1:length(condition_trials)
            active_mat_cond(sc,tc)=length(state_onsets_cond{sc,tc});
        end
   
        mean_active_mat_cond(cond_idx,:)=mean(active_mat_cond,2);
    end
end

%%
figure()
center=mean_active_mat_cond(1,:);
right=mean_active_mat_cond(2,:);
left=mean_active_mat_cond(3,:);

bar_cond=bar(1:model.n_states, [center' right' left'], 1);

hold on
plot(mean_active_mat,'Marker','s','LineStyle','none','MarkerSize',10,'MarkerFaceColor','k');

title('Mean states activation per trial')
xlabel('States')
ylabel('Mean number of activation')
ylim([0 ceil(max(mean_active_mat_cond(:)))])
legend('Center','Right','Left','State mean','Location','northeastoutside')

%%
%average life time of each states

%check if the number of onset is equal to the number of offset in each trials   
 for s=1:model.n_states
     for t=1:data.ntrials
     onsetoffset(s,t)=isequal(length(state_trial_stats.state_onsets{s,t}),length(state_trial_stats.state_offsets{s,t}));
     end
 end
 
if find(onsetoffset==0)>0
    display('check onsetoffset!')
end


lifetime={};
for s=1:model.n_states
     for t=1:data.ntrials
        offset=state_trial_stats.state_offsets{s,t};
        onset=state_trial_stats.state_onsets{s,t};
        offon_nbr=length(offset);
        LT_idx=zeros(1,offon_nbr);
        for o=1:offon_nbr
            LT_idx(o)=offset(o)-onset(o);    
        end
        lifetime{s,t}=LT_idx;
     end  
 end

%mean number of time a state is active for less than 10ms
state_blip=zeros(model.n_states,data.ntrials);
for s=1:model.n_states
     for t=1:data.ntrials
     state_blip(s,t)=length(find(lifetime{s,t}==0));
     end
 end
mean_state_blip=mean(state_blip,2);


%mean state lifetime based on the maximum activation length of a trial
%(with 0ms duration)
for s=1:model.n_states
     for t=1:data.ntrials
        if isempty(lifetime{s,t})==1
           lifetime{s,t}=0;
        end
     end
 end

LT_max=zeros(model.n_states,data.ntrials);
for s=1:model.n_states
     for t=1:data.ntrials
     LT_max(s,t)=max(lifetime{s,t});
     end
 end
mean_LT_max=mean(LT_max,2);

for cond_idx=1:length(conditions)
    condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
    LT_max_cond=zeros(model.n_states,length(condition_trials));
    for sc=1:model.n_states
        lifetime_cond=lifetime(:,condition_trials);
        for tc=1:length(condition_trials)
            LT_max_cond(sc,tc)=max(lifetime_cond{sc,tc});
        end
   
        mean_LT_max_cond(cond_idx,:)=mean(LT_max_cond,2);
    end
end

        %mean state lifetime based on the maximum activation length of a trial
        %(WITHOUT 0ms duration)
        for s=1:model.n_states
            state=LT_max(s,:);
            state_zeros=find(LT_max(s,:)==0);
            state([state1_zeros])=[];
            mean_LT_max_no0(s)=mean(state,2);
        end    
        mean_LT_max_no0=mean_LT_max_no0';

        %%
figure()
center=mean_LT_max_cond(1,:);
right=mean_LT_max_cond(2,:);
left=mean_LT_max_cond(3,:);

bar_cond=bar(1:model.n_states, [center' right' left'], 1);

hold on
plot(mean_LT_max,'Marker','s','LineStyle','none','MarkerSize',10,'MarkerFaceColor','k');

title('Mean maximum lifetime per trial')
xlabel('States')
ylabel('Duration (ms)')
ylim([0 ceil(max(mean_LT_max_cond(:)))])
legend('Center','Right','Left','State mean','Location','northeastoutside')

%%

%mean state lifetime based on the sum of all activations of a trial
LT_sum=zeros(model.n_states,data.ntrials);
for s=1:model.n_states
     for t=1:data.ntrials
     LT_sum(s,t)=sum(lifetime{s,t});
     end
 end
mean_LT_sum=mean(LT_sum,2);

for cond_idx=1:length(conditions)
    condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
    LT_sum_cond=zeros(model.n_states,length(condition_trials));
    for sc=1:model.n_states
        lifetime_cond=lifetime(:,condition_trials);
        for tc=1:length(condition_trials)
            LT_sum_cond(sc,tc)=sum(lifetime_cond{sc,tc});
        end
   
        mean_LT_sum_cond(cond_idx,:)=mean(LT_sum_cond,2);
    end
end

%%
figure()
center=mean_LT_sum_cond(1,:);
right=mean_LT_sum_cond(2,:);
left=mean_LT_sum_cond(3,:);

bar_cond=bar(1:model.n_states, [center' right' left'], 1);

hold on
plot(mean_LT_sum,'Marker','s','LineStyle','none','MarkerSize',10,'MarkerFaceColor','k');

title('Mean sum lifetime per trial')
xlabel('States')
ylabel('Mean duration')
ylim([0 ceil(max(mean_LT_sum_cond(:)))])
legend('Center','Right','Left','State mean','Location','northeastoutside')

%%





