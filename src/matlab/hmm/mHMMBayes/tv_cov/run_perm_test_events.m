function run_perm_test_events(subject, array, data, model, conditions, dates, output_path)

threshold=0.25;
dur_thresh=20;

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

% Smoothing kernel
w=gausswin(5);
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
                mon=trial_state_onsets{i};
                moff=trial_state_offsets{i};
                sprobs=model.forward_probs.(sprintf('fw_prob_S%d',i));
                trial_fwd_probs = sprobs(trial_rows);                  
                %trial_fwd_probs_sm=conv(trial_fwd_probs(sub_bin_idx),w,'same');
                trial_fwd_probs_sm=trial_fwd_probs(sub_bin_idx);
                above_thresh=trial_fwd_probs_sm>threshold;
                thresh_diff=diff([0; above_thresh]);
                onsets=find(thresh_diff==1);
                offsets=find(thresh_diff==-1);
                if length(onsets)>length(offsets)
                    durations=offsets-onsets(1:end-1);
                    durations(end+1)=length(thresh_diff)-onsets(end);
                    good_idx=find(durations>dur_thresh);
                    mon{all_t_idx}=data.bins(bin_idx(sub_bin_idx(onsets(good_idx))))-data.metadata.go(day_trials(n));
                    trial_state_onsets{i}=mon;
                    moff{all_t_idx}=data.bins(bin_idx(sub_bin_idx(offsets(good_idx(1:end-1)))))-data.metadata.go(day_trials(n));
                    trial_state_offsets{i}=moff;
                else
                    durations=offsets-onsets;
                    good_idx=find(durations>dur_thresh);
                    mon{all_t_idx}=data.bins(bin_idx(sub_bin_idx(onsets(good_idx))))-data.metadata.go(day_trials(n));
                    trial_state_onsets{i}=mon;
                    moff{all_t_idx}=data.bins(bin_idx(sub_bin_idx(offsets(good_idx))))-data.metadata.go(day_trials(n));
                    trial_state_offsets{i}=moff;
                end
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
    state=model.metadata.state_labels{i};
    mon=trial_state_onsets{i};
    moff=trial_state_offsets{i};
    first_onsets=[];
    first_offsets=[];
    last_onsets=[];
    last_offsets=[];
    for j=1:length(mon)
        ton=mon{j};
        
        % Get first and last onsets
        first_on=NaN;
        last_on=NaN;
        if length(ton)>0
            first_on=ton(1);
        end
        if length(ton)>1
            last_on=ton(end);
        end
        first_onsets(end+1)=first_on;
        last_onsets(end+1)=last_on;
        
        % Get first and last offsets
        toff=moff{j};
        first_off=NaN;
        last_off=NaN;
        if length(toff)>0
            first_off=toff(1);
        end
        if length(toff)>1
            last_off=toff(1);
        end
        first_offsets(end+1)=first_off;
        last_offsets(end+1)=last_off;
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
        
        b_onsets=first_onsets;
        %on_diff=nanmean(b_onsets-e_times);
        %on_diff=corr(b_onsets',e_times','type','Spearman', 'rows','complete');
        on_diff=partialcorr(b_onsets',e_times',other_event_times', 'rows','complete','Type','Spearman');
        shuffled_diffs=[];
        for j=1:10000
            p_idx=randperm(length(e_times));
            shuffled_e_times=e_times(p_idx);%-prev_e_times;
            %shuffled_diffs(j)=nanmean(b_onsets-shuffled_e_times);
            %shuffled_diffs(j)=corr(b_onsets',shuffled_e_times','type','Spearman', 'rows','complete');
            shuffled_diffs(j)=partialcorr(b_onsets',shuffled_e_times',other_event_times(:,p_idx)', 'rows','complete');
        end        
        b=sum(abs(shuffled_diffs)>=abs(on_diff));
        p = (b+1)/(length(shuffled_diffs)+1);
        disp(sprintf('State: %s, Event: %s, First Onset, p=%.3f', state, event, p));
        [f,xi]=ksdensity(shuffled_diffs);
        subplot(4,length(events)-1,e-1);
        hold all;
        ci=CIFcn(shuffled_diffs,95);
        p=fill([ci(1) ci(2) ci(2) ci(1)],[0 0 0 0],'y');
        plot(xi,f);
        yl=ylim();
        plot([on_diff on_diff],yl);
        set(p,'ydata',[yl(1) yl(1) yl(2) yl(2)]);
        title(sprintf('%s - %s', state, event));
        ylabel('First onset');
    
        b_offsets=first_offsets;
        %off_diff=nanmean(b_offsets-e_times);
        %off_diff=corr(b_offsets',e_times','type','Spearman', 'rows','complete');
        off_diff=partialcorr(b_offsets',e_times',other_event_times', 'rows','complete');
        shuffled_diffs=[];
        for j=1:10000
            p_idx=randperm(length(e_times));
            shuffled_e_times=e_times(p_idx);%-prev_e_times;
            %shuffled_diffs(j)=nanmean(b_offsets-shuffled_e_times);
            %shuffled_diffs(j)=corr(b_offsets',shuffled_e_times','type','Spearman', 'rows','complete');
            shuffled_diffs(j)=partialcorr(b_offsets',shuffled_e_times',other_event_times(:,p_idx)', 'rows','complete');
        end
        b=sum(abs(shuffled_diffs)>=abs(off_diff));
        p = (b+1)/(length(shuffled_diffs)+1);
        disp(sprintf('State: %s, Event: %s, First Offset, p=%.3f', state, event, p));
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
        
        if length(find(~isnan(last_onsets)))>length(last_onsets)*.5
            b_onsets=last_onsets;%-prev_e_times;
            %on_diff=nanmean(b_onsets-e_times);
            %on_diff=corr(b_onsets',e_times','type','Spearman', 'rows','complete');
            on_diff=partialcorr(b_onsets',e_times',other_event_times', 'rows','complete');
            shuffled_diffs=[];
            for j=1:10000
                p_idx=randperm(length(e_times));
                shuffled_e_times=e_times(p_idx);%-prev_e_times;
                %shuffled_diffs(j)=nanmean(b_onsets-shuffled_e_times);
                %shuffled_diffs(j)=corr(b_onsets',shuffled_e_times','type','Spearman', 'rows','complete');
                shuffled_diffs(j)=partialcorr(b_onsets',shuffled_e_times',other_event_times(:,p_idx)', 'rows','complete');
            end
            b=sum(abs(shuffled_diffs)>=abs(on_diff));
            p = (b+1)/(length(shuffled_diffs)+1);
            disp(sprintf('State: %s, Event: %s, Last Onset, p=%.3f', state, event, p));
            [f,xi]=ksdensity(shuffled_diffs);
            subplot(4,length(events)-1,(length(events)-1)*2+e-1);
            hold all;
            ci=CIFcn(shuffled_diffs,95);
            p=fill([ci(1) ci(2) ci(2) ci(1)],[0 0 0 0],'y');
            plot(xi,f);
            yl=ylim();
            plot([on_diff on_diff],yl);
            set(p,'ydata',[yl(1) yl(1) yl(2) yl(2)]);
            ylabel('Last onset');
        end
    
        if length(find(~isnan(last_offsets)))>length(last_offsets)*.5
            b_offsets=last_offsets;%-prev_e_times;
            %off_diff=nanmean(b_offsets-e_times);
            %off_diff=corr(b_offsets',e_times','type','Spearman', 'rows','complete');
            off_diff=partialcorr(b_offsets',e_times',other_event_times', 'rows','complete');
            shuffled_diffs=[];
            for j=1:10000
                p_idx=randperm(length(e_times));
                shuffled_e_times=e_times(p_idx);%-prev_e_times;
                %shuffled_diffs(j)=nanmean(b_offsets-shuffled_e_times);
                %shuffled_diffs(j)=corr(b_offsets',shuffled_e_times','type','Spearman', 'rows','complete');
                shuffled_diffs(j)=partialcorr(b_offsets',shuffled_e_times',other_event_times(:,p_idx)', 'rows','complete');
            end
            b=sum(abs(shuffled_diffs)>=abs(off_diff));
            p = (b+1)/(length(shuffled_diffs)+1);
            disp(sprintf('State: %s, Event: %s, Last Offset, p=%.3f', state, event, p));
            [f,xi]=ksdensity(shuffled_diffs);
            subplot(4,length(events)-1,(length(events)-1)*3+e-1);
            hold all;
            ci=CIFcn(shuffled_diffs,95);
            p=fill([ci(1) ci(2) ci(2) ci(1)],[0 0 0 0],'y');
            plot(xi,f);
            yl=ylim();
            plot([off_diff off_diff],yl);
            set(p,'ydata',[yl(1) yl(1) yl(2) yl(2)]);
            ylabel('Last offset');
        end
    end
    
end
    