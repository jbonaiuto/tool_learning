function plot_fwd_probs_event_sorted(subject, array, data, model, dates, output_path)

% Times of this event in all trials
go_times= [];
mo_times = [];
oc_times = [];
pl_times = [];

evtcolors=cbrewer2('qual','Set1',5);

dt=10;
%dt=1;

trial_state_probs=[];
all_t_idx=1;
% Smoothing kernel
w=gausswin(10*(10/dt));
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
                    
        if length(trial_rows)
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
                state_idx=find(model.metadata.state_labels==i);
                sprobs=model.forward_probs.(sprintf('fw_prob_S%d',state_idx));
                trial_fwd_probs = sprobs(trial_rows);                  
                trial_state_probs(i,all_t_idx,1:length(sub_bin_idx))=conv(trial_fwd_probs(sub_bin_idx),w,'same');                
            end
            all_t_idx=all_t_idx+1;
        end
    end
end

sz=3;    
aligned_times=[1:size(trial_state_probs,3)].*dt-500;
[~,idx] = sort(go_times);

f=figure();
set(gcf,'renderer','Painters')
f.WindowState = 'maximized';

for i=1:model.n_states
    subplot(model.n_states,4,(i-1)*4+1);
    imagesc(aligned_times,[1:length(idx)],squeeze(trial_state_probs(i,idx,:))); 
    set(gca,'ydir','normal');
    set(gca,'clim',[0 1]);
    hold all;
%     plot(go_times(idx),[1:length(idx)],'.w','MarkerSize',sz);
%     plot(mo_times(idx),[1:length(idx)],'.r','MarkerSize',sz);
%     plot(oc_times(idx),[1:length(idx)],'.g','MarkerSize',sz);
%     plot(pl_times(idx),[1:length(idx)],'.m','MarkerSize',sz);
    plot(go_times(idx),[1:length(idx)],'.','color',evtcolors(1,:));
    plot(mo_times(idx),[1:length(idx)],'.','color',evtcolors(2,:));
    plot(oc_times(idx),[1:length(idx)],'.','color',evtcolors(3,:));
    plot(pl_times(idx),[1:length(idx)],'.','color',evtcolors(4,:));
    ylabel({sprintf('State %d',i); 'Trial'});
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
    imagesc(aligned_times,[1:length(idx)],squeeze(trial_state_probs(i,idx,:))); 
    set(gca,'ydir','normal');
    set(gca,'clim',[0 1]);
    hold all;
%     plot(go_times(idx),[1:length(idx)],'.w','MarkerSize',sz);
%     plot(mo_times(idx),[1:length(idx)],'.r','MarkerSize',sz);
%     plot(oc_times(idx),[1:length(idx)],'.g','MarkerSize',sz);
%     plot(pl_times(idx),[1:length(idx)],'.m','MarkerSize',sz);
    plot(go_times(idx),[1:length(idx)],'.','color',evtcolors(1,:));
    plot(mo_times(idx),[1:length(idx)],'.','color',evtcolors(2,:));
    plot(oc_times(idx),[1:length(idx)],'.','color',evtcolors(3,:));
    plot(pl_times(idx),[1:length(idx)],'.','color',evtcolors(4,:));
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
    imagesc(aligned_times,[1:length(idx)],squeeze(trial_state_probs(i,idx,:))); 
    set(gca,'ydir','normal');
    set(gca,'clim',[0 1]);
    hold all;
%     plot(go_times(idx),[1:length(idx)],'.w','MarkerSize',sz);
%     plot(mo_times(idx),[1:length(idx)],'.r','MarkerSize',sz);
%     plot(oc_times(idx),[1:length(idx)],'.g','MarkerSize',sz);
%     plot(pl_times(idx),[1:length(idx)],'.m','MarkerSize',sz);
    plot(go_times(idx),[1:length(idx)],'.','color',evtcolors(1,:));
    plot(mo_times(idx),[1:length(idx)],'.','color',evtcolors(2,:));
    plot(oc_times(idx),[1:length(idx)],'.','color',evtcolors(3,:));
    plot(pl_times(idx),[1:length(idx)],'.','color',evtcolors(4,:));
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
    imagesc(aligned_times,[1:length(idx)],squeeze(trial_state_probs(i,idx,:))); 
    set(gca,'ydir','normal');
    %set(gca,'clim',[0 1]);
    set(gca,'color',[1 1 1]);
    hold all;
%     plot(go_times(idx),[1:length(idx)],'.w','MarkerSize',sz);
%     plot(mo_times(idx),[1:length(idx)],'.r','MarkerSize',sz);
%     plot(oc_times(idx),[1:length(idx)],'.g','MarkerSize',sz);
%     plot(pl_times(idx),[1:length(idx)],'.m','MarkerSize',sz);
     plot(go_times(idx),[1:length(idx)],'.','color',evtcolors(1,:));
    plot(mo_times(idx),[1:length(idx)],'.','color',evtcolors(2,:));
    plot(oc_times(idx),[1:length(idx)],'.','color',evtcolors(3,:));
    plot(pl_times(idx),[1:length(idx)],'.','color',evtcolors(4,:));
    xlabel('Time (ms)');
    if i==1
        title('Place-sorted');
    elseif i==model.n_states
        xlabel('Time (ms)');
    end
    if i==model.n_states
        pos=get(gca,'Position');
        colormap(flipud(gray(256)));
        h=colorbar();
        title(h,'Prob');
        set(gca,'Position',pos);
    end    
end

saveas(f,fullfile(output_path,...
     [subject '_' array '_' 'grasp' '_Sorted_10d_TvCov_2' '.png']));
saveas(f,fullfile(output_path,...
     [subject '_' array '_' 'grasp' '_Sorted_10d_TvCov_2' '.eps']),'epsc');