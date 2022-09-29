function run_perm_test_events_durations_days(subject, data, model)

min_time_steps=10;
n_perms=10000;

CIFcn = @(x,p)prctile(x(~isnan(x)),abs([0,100]-(100-p)/2));

% Times of this event in all trials
rt= [];
reach_dur = [];
place_dur = [];


trial_state_durations={};
for i=1:model.n_states
    trial_state_durations{i}=[];
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
            mdur=trial_state_durations{i};
            % Get mapped index
            state_idx=find(model.metadata.state_labels==i);
            
            % Get state activations from most likely state sequence
            above_thresh=model.state_seq.state(trial_rows(sub_bin_idx))==state_idx;
            onsets = strfind([0 above_thresh'], [0 ones(1,min_time_steps)]);
            offsets = strfind([above_thresh' 0], [ones(1,min_time_steps) 0]);
            % Use the onset and offset time of the activation with the
            % max duration
            durations=offsets-onsets;
            %[m_dur,m_idx]=max(durations);
            %m_idx=length(durations)
            m_idx=1;
            if length(durations)
                mdur(t_idx)=durations(m_idx);
            else
                mdur(t_idx)=NaN;
            end
            trial_state_durations{i}=mdur;  
        end
    end
end

event_times.rt=rt;
event_times.reach_dur=reach_dur;
event_times.place_dur=place_dur;

events={'rt','reach_dur','place_dur'};

dates=data.dates;

if strcmp(subject,'betta')
    included={'1 - rt', '6 - place_dur' };
elseif strcmp(subject,'samovar')
    included={'1 - rt', '4 - reach_dur', '3 - place_dur','4 - place_dur','5 - place_dur' };
end
figure();
lbls={};
hold all;
for i=1:model.n_states
    mdur=trial_state_durations{i};
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
                jmact=trial_state_durations{j};
                if j>1
                    other_event_times(end+1,:)=jmact;
                end                
            end
        end
        
        lbl=sprintf('%d - %s',i,event);
        if length(find(strcmp(included,lbl)))
            b_act=mdur;
            state_act_mo_corrs=[];
            lbls{end+1}=lbl;
        
            for d=1:2:length(dates)
                rows=find((data.trial_date==d) | (data.trial_date==(d+1)));
                act_diff=corr(b_act(rows)',e_times(rows)','rows','complete','type','Spearman');
                shuffled_diffs=[];
                for j=1:n_perms
                    p_idx=randperm(length(rows));
                    shuffled_e_times=e_times(rows(p_idx));
                    shuffled_diffs(j)=corr(b_act(rows)',shuffled_e_times',...
                        'rows','complete','type','Spearman');
                end        
                b=sum(abs(shuffled_diffs)>=abs(act_diff));
                p = (b+1)/(length(shuffled_diffs)+1);
                disp(sprintf('State: %d, Event: %s, day=%d, r=%.3f, p=%.3f', i, event, d, act_diff, p));
                state_act_mo_corrs(end+1)=act_diff;

            end
            plot([1:5],state_act_mo_corrs);
        end
    end
end
xlim([.5 5.5]);
ylim([0 1.1]);
xlabel('Day');
ylabel('\rho');
legend(lbls);
