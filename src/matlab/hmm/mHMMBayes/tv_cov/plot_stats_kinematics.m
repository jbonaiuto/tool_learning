function plot_stats_kinematics(model, data, dates)

state_trial_stats=extract_state_trial_stats(model, data, dates, 'min_time_steps',5);

lifetime=state_trial_stats.state_durations;
LT_max={};
for s=1:model.n_states
    state_idx=model.metadata.state_labels(s);
    lt_mat=zeros(1,data.ntrials);
    for t=1:data.ntrials
        if isempty(lifetime{state_idx,t})
           lifetime{state_idx,t}=0;
        end
        lt=max(lifetime{state_idx,t});        
        lt_mat(t)=lt;
    end
    LT_max{s}=lt_mat;
end
active_mat={};
for s=1:model.n_states
   state_mat=zeros(data.ntrials,1);
   state_idx=model.metadata.state_labels(s);
   for t=1:data.ntrials
       activations=length(state_trial_stats.state_onsets{state_idx,t});
       state_mat(t)=activations;
   end
   active_mat{s}=state_mat;
end

rts=data.metadata.hand_mvmt_onset-data.metadata.go;
mts=data.metadata.obj_contact-data.metadata.hand_mvmt_onset;
pts=data.metadata.place-data.metadata.obj_contact;

figure();
subplot(2,4,1);
plot(LT_max{1},rts,'o');
subplot(2,4,2);
plot(LT_max{2},mts,'o');
subplot(2,4,3);
plot(LT_max{3},mts,'o');
subplot(2,4,4);
plot(LT_max{6},mts,'o');
subplot(2,4,5);
plot(LT_max{2},pts,'o');
subplot(2,4,6);
plot(LT_max{3},pts,'o');
subplot(2,4,7);
plot(LT_max{4},pts,'o');
subplot(2,4,8);
plot(LT_max{5},pts,'o');
