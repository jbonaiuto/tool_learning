function run_perm_test_events_activations(data, model)

min_time_steps=10;
n_perms=10000;

CIFcn = @(x,p)prctile(x(~isnan(x)),abs([0,100]-(100-p)/2));

% Times of this event in all trials
rt= [];
reach_dur = [];
place_dur = [];


trial_state_activations={};
for i=1:model.n_states
    trial_state_activations{i}=[];
end

% For every date
for t_idx=1:data.ntrials
    % Rows of state seq for this trial
    trial_rows=find((model.state_seq.trial==t_idx));
                            
    if length(trial_rows)
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data.bins>=0) & (data.bins<=data.metadata.reward(t_idx)));
        sub_bin_idx=find(data.bins(bin_idx)-data.metadata.go(t_idx)>=-500);

        % Find time of alignment event in this trial
        rt(t_idx) = data.metadata.hand_mvmt_onset(t_idx)-data.metadata.go(t_idx);
        reach_dur(t_idx) = data.metadata.obj_contact(t_idx)-data.metadata.hand_mvmt_onset(t_idx);
        place_dur(t_idx) = data.metadata.place(t_idx)-data.metadata.obj_contact(t_idx);
        
        % Save p states within this window
        for i=1:model.n_states
            mact=trial_state_activations{i};
            % Get mapped index
            state_idx=find(model.metadata.state_labels==i);
            
            % Get state activations from most likely state sequence
            above_thresh=model.state_seq.state(trial_rows(sub_bin_idx))==state_idx;
            onsets = strfind([0 above_thresh'], [0 ones(1,min_time_steps)]);
            offsets = strfind([above_thresh' 0], [ones(1,min_time_steps) 0]);
            % Use the onset and offset time of the activation with the
            % max duration
            durations=offsets-onsets;
            mact(t_idx)=length(durations);
            trial_state_activations{i}=mact;  
        end
    end
end

event_times.rt=rt;
event_times.reach_dur=reach_dur;
event_times.place_dur=place_dur;

events={'rt','reach_dur','place_dur'};

% figure();

for i=1:model.n_states
    mact=trial_state_activations{i};
    
    for e=1:length(events)
        event=events{e};
        e_times=event_times.(event);
        other_event_times=[];
        for e2=1:length(events)
            if e2~=e
                other_event_times(end+1,:)=event_times.(events{e2});
            end
        end
        for j=1:model.n_states
            if j~=i
                jmact=trial_state_activations{j};
                if j>1
                    other_event_times(end+1,:)=jmact;
                end                
            end
        end
        
        b_act=mact;
        act_diff=partialcorr(b_act',e_times',other_event_times',...
            'rows','complete','type','Spearman');
        shuffled_diffs=[];
        for j=1:n_perms
            p_idx=randperm(length(e_times));
            shuffled_e_times=e_times(p_idx);
            shuffled_diffs(j)=partialcorr(b_act',shuffled_e_times',...
                other_event_times(:,:)', 'rows','complete','type','Spearman');
        end        
        b=sum(abs(shuffled_diffs)>=abs(act_diff));
        p = (b+1)/(length(shuffled_diffs)+1);
        disp(sprintf('State: %d, Event: %s, Activations, r=%.3f, p=%.3f', i, event, act_diff, p));

%         [f,xi]=ksdensity(shuffled_diffs);
%         subplot(model.n_states*2,length(events)-1,(i-1)*2*(length(events)-1)+e-1);
    %         hold all;
    %         ci=CIFcn(shuffled_diffs,95);
    %         p=fill([ci(1) ci(2) ci(2) ci(1)],[0 0 0 0],'y');
    %         plot(xi,f);
    %         yl=ylim();
    %         plot([on_diff on_diff],yl);
    %         set(p,'ydata',[yl(1) yl(1) yl(2) yl(2)]);
%         plot(b_act,e_times,'o');
%         xlim([0 3500]);
%         title(sprintf('%d - %s', i, event));
%         ylabel('duration');
        
        
    end
    
end