function plot_fwd_probs_event_sorted(data, model, conditions, dates)

% Times of this event in all trials
go_times= [];
mo_times = [];
oc_times = [];
pl_times = [];


trial_state_probs=[];
all_t_idx=1;
% Smoothing kernel
%K = (1/3)*ones(1,3);
w=gausswin(10);
w=w/sum(w);

% Date index of each trial for this condition
trial_date=data.trial_date;
    
% For every date
for d=1:length(dates)
    % Find trials from this date for this condition
    day_trials=find(trial_date==d);
            
    % For each trial from this day in this condition
    for n=1:length(day_trials)
                
        % Rows of forward probabilities for this trial
        trial_rows=find((model.forward_probs.subj==day_trials(n)));
        if strcmp(model.type,'multilevel')
            trial_rows=find((model.forward_probs.subj==d) & (model.forward_probs.rm==n));
        end
                            
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data.bins>=0) & (data.bins<=data.metadata.reward(day_trials(n))));
        sub_bin_idx=find(data.bins(bin_idx)-data.metadata.go(day_trials(n))>=-500);
    
        % Find time of alignment event in this trial
        go_times(all_t_idx) = data.metadata.go(day_trials(n))-data.metadata.go(day_trials(n));
        mo_times(all_t_idx) = data.metadata.hand_mvmt_onset(day_trials(n))-data.metadata.go(day_trials(n));
	oc_times(all_t_idx) = data.metadata.obj_contact(day_trials(n))-data.metadata.go(day_trials(n));
	pl_times(all_t_idx) = data.metadata.place(day_trials(n))-data.metadata.go(day_trials(n));
    
        % Save p states within this window
        for i=1:model.n_states
            sprobs=model.forward_probs.(sprintf('fw_prob_S%d',i));
            trial_fwd_probs = sprobs(trial_rows);                  
            trial_state_probs(i,all_t_idx,1:length(sub_bin_idx))=conv(trial_fwd_probs(sub_bin_idx),w,'same');                
        end
        all_t_idx=all_t_idx+1;
    end
end

sz=3;    
aligned_times=[1:size(trial_state_probs,3)].*10-500;
[~,idx] = sort(go_times);
figure();
for i=1:model.n_states
    subplot(model.n_states,4,(i-1)*4+1);
    contourf(aligned_times,[1:length(idx)],squeeze(trial_state_probs(i,idx,:)),'linecolor','none'); 
    set(gca,'clim',[0 1]);
    hold all;
    plot(go_times(idx),[1:length(idx)],'.w','MarkerSize',sz);
    plot(mo_times(idx),[1:length(idx)],'.r','MarkerSize',sz);
    plot(oc_times(idx),[1:length(idx)],'.g','MarkerSize',sz);
    plot(pl_times(idx),[1:length(idx)],'.m','MarkerSize',sz);
    ylabel({sprintf('State %s',model.metadata.state_labels{i}); 'Trial'});
    if i==1
        title('Go-sorted');
    elseif i==model.n_states
        xlabel('Time (ms)');
    end
end

[~,idx] = sort(mo_times);
%figure();
for i=1:model.n_states
    %subplot(2,3,i);
    subplot(model.n_states,4,(i-1)*4+2);
    contourf(aligned_times,[1:length(idx)],squeeze(trial_state_probs(i,idx,:)),'linecolor','none'); 
    set(gca,'clim',[0 1]);
    hold all;
    plot(go_times(idx),[1:length(idx)],'.w','MarkerSize',sz);
    plot(mo_times(idx),[1:length(idx)],'.r','MarkerSize',sz);
    plot(oc_times(idx),[1:length(idx)],'.g','MarkerSize',sz);
    plot(pl_times(idx),[1:length(idx)],'.m','MarkerSize',sz);
    if i==1
        title('Movement onset-sorted');
    elseif i==model.n_states
        xlabel('Time (ms)');
    end
end

[~,idx] = sort(oc_times);
%figure();
for i=1:model.n_states
    %subplot(2,3,i);
    subplot(model.n_states,4,(i-1)*4+3);
    contourf(aligned_times,[1:length(idx)],squeeze(trial_state_probs(i,idx,:)),'linecolor','none'); 
    set(gca,'clim',[0 1]);
    hold all;
    plot(go_times(idx),[1:length(idx)],'.w','MarkerSize',sz);
    plot(mo_times(idx),[1:length(idx)],'.r','MarkerSize',sz);
    plot(oc_times(idx),[1:length(idx)],'.g','MarkerSize',sz);
    plot(pl_times(idx),[1:length(idx)],'.m','MarkerSize',sz);
    if i==1
        title('Obj contact-sorted');
    elseif i==model.n_states
        xlabel('Time (ms)');
    end
end

[~,idx] = sort(pl_times);
%figure();
for i=1:model.n_states
    %subplot(2,3,i);
    subplot(model.n_states,4,(i-1)*4+4);
    contourf(aligned_times,[1:length(idx)],squeeze(trial_state_probs(i,idx,:)),'linecolor','none'); 
    set(gca,'clim',[0 1]);
    hold all;
    plot(go_times(idx),[1:length(idx)],'.w','MarkerSize',sz);
    plot(mo_times(idx),[1:length(idx)],'.r','MarkerSize',sz);
    plot(oc_times(idx),[1:length(idx)],'.g','MarkerSize',sz);
    plot(pl_times(idx),[1:length(idx)],'.m','MarkerSize',sz);
    xlabel('Time (ms)');
    if i==1
        title('Place-sorted');
    elseif i==model.n_states
        xlabel('Time (ms)');
    end
    if i==model.n_states
        pos=get(gca,'Position');
        h=colorbar();
        title(h,'Prob');
        set(gca,'Position',pos);
    end    
end
