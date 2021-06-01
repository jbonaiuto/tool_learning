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
   
        % THERES A FUNCTION FOR THIS
        %mean_active_mat_cond{cond_idx,sc}=sum(active_mat_cond(sc,:),2)/length(condition_trials);
        mean_active_mat_cond(cond_idx,:)=mean(active_mat_cond,2);
    end
end

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





















