function run_perm_test_events(data, model, dates)

min_time_steps=1;

CIFcn = @(x,p)prctile(x(~isnan(x)),abs([0,100]-(100-p)/2));

% Times of this event in all trials
go_times= [];
mo_times = [];
oc_times = [];
pl_times = [];


trial_state_onsets={};
trial_state_offsets={};
for i=1:model.n_states
    trial_state_onsets{i}={};
    trial_state_offsets{i}={};
end
all_t_idx=1;

% Date index of each trial for this condition
trial_date=data.trial_date;
    
% For every date
for d=1:length(dates)
    % Find trials from this date for this condition
    day_trials=find(trial_date==d);
            
    % For each trial from this day in this condition
    for n=1:length(day_trials)
                
        % Rows of state seq for this trial
        trial_rows=find((model.state_seq.trial==day_trials(n)));
                            
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
                mon=trial_state_onsets{i};
                moff=trial_state_offsets{i};
                % Get mapped index
                state_idx=find(model.metadata.state_labels==i);
                % Get state activations from most likely state sequence
                above_thresh=model.state_seq.state(trial_rows(sub_bin_idx))==state_idx;
                onsets = strfind([0 above_thresh'], [0 ones(1,min_time_steps)]);
                offsets = strfind([above_thresh' 0], [ones(1,min_time_steps) 0]);
                % Use the onset and offset time of the activation with the
                % max duration
                durations=offsets-onsets;
                [m_dur,m_idx]=max(durations);
                mon{all_t_idx}=data.bins(bin_idx(sub_bin_idx(onsets(m_idx))))-data.metadata.go(day_trials(n));
                trial_state_onsets{i}=mon;
                moff{all_t_idx}=data.bins(bin_idx(sub_bin_idx(offsets(m_idx))))-data.metadata.go(day_trials(n));
                trial_state_offsets{i}=moff;
            end
            all_t_idx=all_t_idx+1;
        end
    end
end

event_times.go=go_times;
event_times.mo=mo_times;
event_times.oc=oc_times;
event_times.pl=pl_times;

events={'go','mo','oc','pl'};

for i=1:model.n_states
    mon=trial_state_onsets{i};
    moff=trial_state_offsets{i};
    onsets=[];
    offsets=[];
    for j=1:length(mon)
        ton=mon{j};
        
        % Get first and last onsets
        on=NaN;
        if length(ton)>0
            on=ton(1);
        end
        onsets(end+1)=on;
        
        % Get first and last offsets
        toff=moff{j};
        off=NaN;
        if length(toff)>0
            off=toff(1);
        end
        offsets(end+1)=off;        
    end
    
    figure();
    for e=2:length(events)
        event=events{e};
        e_times=event_times.(event);
        other_event_times=[];
        for e2=2:length(events)
            if e2~=e
                other_event_times(end+1,:)=event_times.(events{e2});
            end
        end
        
        b_onsets=onsets;
        on_diff=partialcorr(b_onsets',e_times',other_event_times',...
            'rows','complete','type','Spearman');
        shuffled_diffs=[];
        for j=1:10000
            p_idx=randperm(length(e_times));
            shuffled_e_times=e_times(p_idx);
            shuffled_diffs(j)=partialcorr(b_onsets',shuffled_e_times',...
                other_event_times(:,p_idx)', 'rows','complete','type','Spearman');
        end        
        b=sum(abs(shuffled_diffs)>=abs(on_diff));
        p = (b+1)/(length(shuffled_diffs)+1);
        disp(sprintf('State: %d, Event: %s, Onset, r=%.3f, p=%.3f', i, event, on_diff, p));
        [f,xi]=ksdensity(shuffled_diffs);
        subplot(4,length(events)-1,e-1);
        hold all;
        ci=CIFcn(shuffled_diffs,95);
        p=fill([ci(1) ci(2) ci(2) ci(1)],[0 0 0 0],'y');
        plot(xi,f);
        yl=ylim();
        plot([on_diff on_diff],yl);
        set(p,'ydata',[yl(1) yl(1) yl(2) yl(2)]);
        title(sprintf('%s - %s', i, event));
        ylabel('First onset');
    
        b_offsets=offsets;
        off_diff=partialcorr(b_offsets',e_times',other_event_times',...
            'rows','complete','type','Spearman');
        shuffled_diffs=[];
        for j=1:10000
            p_idx=randperm(length(e_times));
            shuffled_e_times=e_times(p_idx);
            shuffled_diffs(j)=partialcorr(b_offsets',shuffled_e_times',...
                other_event_times(:,p_idx)', 'rows','complete','type','Spearman');
        end
        b=sum(abs(shuffled_diffs)>=abs(off_diff));
        p = (b+1)/(length(shuffled_diffs)+1);
        disp(sprintf('State: %d, Event: %s, Offset, r=%.3f, p=%.3f', i, event, off_diff, p));
        [f,xi]=ksdensity(shuffled_diffs);
        subplot(4,length(events)-1,(length(events)-1)+e-1);
        hold all;
        ci=CIFcn(shuffled_diffs,95);
        p=fill([ci(1) ci(2) ci(2) ci(1)],[0 0 0 0],'y');
        plot(xi,f);
        yl=ylim();
        plot([off_diff off_diff],yl);
        set(p,'ydata',[yl(1) yl(1) yl(2) yl(2)]);
        ylabel('First offset');        
    end
    
end
    