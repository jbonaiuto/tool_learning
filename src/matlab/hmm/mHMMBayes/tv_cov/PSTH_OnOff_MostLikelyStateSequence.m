function PSTH_OnOff_MostLikelyStateSequence(model,electrodes,data,output_path)

% comment dbstop if not debugging somethin
%dbstop if error

min_time_steps=1;
data=compute_firing_rate(data,'baseline_type','none');

%  find the mean state duration For each condition
meanDur=zeros(1,model.n_states);
%for each state
for state_nbr=1:model.n_states
    state_idx=model.metadata.state_labels(state_nbr);
    
    trial_max_dur=[];
    for t=1:data.ntrials
        trial_rows=find((model.state_seq.trial==t));
        
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data.bins>=0) & (data.bins<=data.metadata.reward(t)));
        sub_bin_idx=find(data.bins(bin_idx)-data.metadata.go(t)>=-500);
        trial_times=data.bins(bin_idx(sub_bin_idx));
        
        mask=model.state_seq.state(trial_rows(sub_bin_idx))==state_idx;
        
        onsets = trial_times(strfind([0 mask'], [0 ones(1,min_time_steps)]));
        offsets = trial_times(strfind([mask' 0], [ones(1,min_time_steps) 0]))+min_time_steps;
        durations=offsets-onsets;
        [m_dur,m_idx]=max(durations);
        %m_idx=1;
        %m_dur=mean(durations);
        
        if length(durations)
            trial_max_dur(end+1)=durations(m_idx);
            %trial_max_dur(end+1)=m_dur;
        end
    end
    meanDur(state_nbr)=mean(trial_max_dur);
end

state_on_FR={};
state_off_FR={};
for state_nbr=1:model.n_states
    state_on_FR{state_nbr}=[];
    state_off_FR{state_nbr}=[];
end

%for each state
fid=fopen(fullfile(output_path,'state_aligned_firing_rates.csv'),'w');
fprintf(fid,'state,day,trial,electrode,condition,rate\n');

for state_nbr=1:model.n_states
    state_idx=find(model.metadata.state_labels==state_nbr);
    
    StateOnElectrodeFR=[];
    StateOffElectrodeFR=[];
    BaselineFR=[];
    
    %for each trial
    for t=1:data.ntrials
        trial_rows=find((model.state_seq.trial==t));
        
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data.bins>=0) & (data.bins<=data.metadata.reward(t)));
        sub_bin_idx=find(data.bins(bin_idx)-data.metadata.go(t)>=-500);
        trial_times=data.bins(bin_idx(sub_bin_idx));
        
        mask=model.state_seq.state(trial_rows(sub_bin_idx))==state_idx;
        
        onsets = trial_times(strfind([0 mask'], [0 ones(1,min_time_steps)]));
        offsets = trial_times(strfind([mask' 0], [ones(1,min_time_steps) 0]))+min_time_steps;
        durations=offsets-onsets;
        [m_dur,m_idx]=max(durations);
        %m_idx=1;
        
        if length(durations)
            %for m_idx=1:length(durations)
                onset=onsets(m_idx);
                offset=offsets(m_idx);

                % WOI start and end time
                start_time_ON=onset-100;
                end_time_ON=onset+meanDur(state_nbr)/2;
                start_time_OFF=offset-meanDur(state_nbr)/2;
                end_time_OFF=offset+100;

                win_ON_bins=[knnsearch(data.bins',start_time_ON):knnsearch(data.bins',end_time_ON)];
                win_OFF_bins=[knnsearch(data.bins',start_time_OFF):knnsearch(data.bins',end_time_OFF)];

                baseline_bins=[knnsearch(data.bins',start_time_ON):knnsearch(data.bins',onset)];

                baseline_rate=squeeze(data.firing_rate(1,electrodes,t,baseline_bins));
                BaselineFR(end+1,:,:)=baseline_rate;

                first_bins=[knnsearch(data.bins',onset):knnsearch(data.bins',end_time_ON)];
                first_rate=squeeze(data.firing_rate(1,electrodes,t,first_bins));
                StateOnElectrodeFR(end+1,:,:)=squeeze(data.firing_rate(1,electrodes,t,win_ON_bins));

                second_bins=[knnsearch(data.bins',start_time_OFF):knnsearch(data.bins',offset)];
                second_rate=squeeze(data.firing_rate(1,electrodes,t,second_bins));
                StateOffElectrodeFR(end+1,:,:)=squeeze(data.firing_rate(1,electrodes,t,win_OFF_bins));
                
                post_bins=[knnsearch(data.bins',offset):knnsearch(data.bins',end_time_OFF)];
                post_rate=squeeze(data.firing_rate(1,electrodes,t,post_bins));
                
                for e=1:length(electrodes)
                    mean_baseline_rate=mean(baseline_rate(e,:));
                    fprintf(fid,'%d,%d,%d,%d,baseline,%.4f\n',state_nbr,data.trial_date(t),t,e,mean_baseline_rate);
                    mean_first_rate=mean(first_rate(e,:));
                    fprintf(fid,'%d,%d,%d,%d,first,%.4f\n',state_nbr,data.trial_date(t),t,e,mean_first_rate);
                    mean_second_rate=mean(second_rate(e,:));
                    fprintf(fid,'%d,%d,%d,%d,second,%.4f\n',state_nbr,data.trial_date(t),t,e,mean_second_rate);
                    mean_post_rate=mean(post_rate(e,:));
                    fprintf(fid,'%d,%d,%d,%d,post,%.4f\n',state_nbr,data.trial_date(t),t,e,mean_post_rate);
                end
            %end
        end
    end
    
    mean_baseline=mean(mean(BaselineFR,3),1);
    reshaped_baseline=repmat(mean_baseline,size(BaselineFR,1),1,length(win_ON_bins));
    StateOnElectrodeFR=(StateOnElectrodeFR-reshaped_baseline)./reshaped_baseline;
    reshaped_baseline=repmat(mean_baseline,size(BaselineFR,1),1,length(win_OFF_bins));
    StateOffElectrodeFR=(StateOffElectrodeFR-reshaped_baseline)./reshaped_baseline;
    state_on_FR{state_nbr}=StateOnElectrodeFR;
    state_off_FR{state_nbr}=StateOffElectrodeFR;
end
fclose(fid);

f=figure();
set(f,'renderer','Painters')
fr_colors=get(gca,'ColorOrder');
sp_idx=1;
%for each state
for state_nbr=1:model.n_states
    onspikes=state_on_FR{state_nbr};
    offspikes=state_off_FR{state_nbr};
    mean_onspikes=squeeze(mean(onspikes,1));
    se_onspikes=squeeze(std(onspikes,[],1)/sqrt(size(onspikes,1)));
    mean_offspikes=squeeze(mean(offspikes,1));
    se_offspikes=squeeze(std(offspikes,[],1)/sqrt(size(offspikes,1)));
    
    yl=[min([mean_onspikes(:)-se_onspikes(:); mean_offspikes(:)-se_offspikes(:)])-.1 max([mean_onspikes(:)+se_onspikes(:); mean_offspikes(:)+se_offspikes(:)])+.1];
    subplot(2, 6, sp_idx);
    hold all
    title(sprintf('state %d: onset', state_nbr));
    bins=linspace(-100,meanDur(state_nbr)/2,size(mean_onspikes,2));
    for m=1:size(mean_onspikes,1)
        shadedErrorBar(bins,mean_onspikes(m,:),se_onspikes(m,:),...
            'LineProps',{'Color',fr_colors(mod(m-1,7)+1,:)});
    end
    plot([0 0],yl,'--k');
    ylim(yl);
    ylabel('Firing rate');
    xlim(bins([1 end]));
    xlabel('Time (ms)');
    sp_idx=sp_idx+1;
    
    subplot(2, 6, sp_idx);
    hold all
    title(sprintf('state %d: offset', state_nbr));
    bins=linspace(-meanDur(state_nbr)/2,100,size(mean_offspikes,2));
    for m=1:size(mean_offspikes,1)
        shadedErrorBar(bins,mean_offspikes(m,:),se_offspikes(m,:),...
            'LineProps',{'Color',fr_colors(mod(m-1,7)+1,:)});
    end
    plot([0 0],yl,'--k');
    ylim(yl);
    yticklabels([]);
    xlim(bins([1 end]));
    xlabel('Time (ms)');
    sp_idx=sp_idx+1;
end

