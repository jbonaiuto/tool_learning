function PSTH_OnOff_MostLikelyStateSequence(model,array,subject,conditions,dates,electrodes,data,output_path)

% comment dbstop if not debugging somethin
%dbstop if error

addpath('../../../');
exp_info=init_exp_info();
rmpath('../../../');

% LOAD THE DATA WITH 1MS BIN SIZE
dt=10;

kernel_width=9; % Kernel width used to smooth data before normalizing
kernel=gausswin(kernel_width);

min_time_steps=1;

data10ms=data;
data10ms=compute_firing_rate(data10ms,'baseline_type','none');

data_fname=fullfile(output_path,'data1ms.mat');
if exist(data_fname,'file')~=2
    % Create a cell array with the data structure of each day to concatenate them
    % into one big structure
    all_data={};
    
    for d_idx=1:length(dates)
        date=dates{d_idx};
        
        % Load and concatenate spike data
        load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
            date,'multiunit','binned',...
            sprintf('fr_b_%s_%s_whole_trial.mat',array,date)));
        
        %create a vector of 1 with the length equal to number of the trail of the day for this condition
        data.trial_date=ones(1,data.ntrials);
        
        % Filter data - RTs too fast or slow
        data=filter_data(data);
        
        % Save to cell array
        all_data{d_idx}=data;
    end
    
    %concatenate all the data structure per day in one big data structure for the period
    concat_data=concatenate_data(all_data, 'spike_times',false);
    clear all_data;
    
    % Figure out which trials to use
    condition_trials=zeros(1,length(concat_data.metadata.condition));
    for i=1:length(conditions)
        condition_trials = condition_trials | (strcmp(concat_data.metadata.condition,conditions{i}));
    end
    condition_trials=find(condition_trials);
    % Remove extra trials - makes the following bit a lot simpler
    all_trials=[1:length(concat_data.metadata.condition)];
    trials_to_remove=setdiff(all_trials,condition_trials);
    data=remove_trials(concat_data,trials_to_remove);
    save(data_fname,'data','-v7.3');
else
    load(data_fname);
end


%  find the mean state duration For each condition
CondState_MeanDur=zeros(length(conditions),model.n_states);
for c_idx=1:length(conditions)

    condition_trials = find(strcmp(data10ms.metadata.condition,conditions{c_idx}));

    %for each state
    for state_nbr=1:model.n_states
        state_idx=model.metadata.state_labels(state_nbr);
        
        trial_MaxAct=[];
        
        %for each trial
        for n=1:length(condition_trials)
               
            %use the trial of interest in this condition
            TOI=condition_trials(n);
            
            trial_rows=find((model.state_seq.trial==TOI));            
            
            % Get the bins that we used in the HMM (time>0 and up to reward)
            bin_idx=find((data10ms.bins>=0) & (data10ms.bins<=data10ms.metadata.reward(TOI)));
            sub_bin_idx=find(data10ms.bins(bin_idx)-data10ms.metadata.go(TOI)>=-500);
            trial_times=data10ms.bins(bin_idx(sub_bin_idx));
            
            mask=model.state_seq.state(trial_rows(sub_bin_idx))==state_idx;
                
            onsets = trial_times(strfind([0 mask'], [0 ones(1,min_time_steps)]));
            offsets = trial_times(strfind([mask' 0], [ones(1,min_time_steps) 0]))+min_time_steps;
            durations=offsets-onsets;
            [m_dur,m_idx]=max(durations);
                
            if length(durations)
                trial_MaxAct(end+1)=m_dur;
            end
%             RowsOI=find(model.state_seq.trial==TOI & model.state_seq.state==state);
%             
%             tstep=model.state_seq.tstep(RowsOI);
%             StateAct_idx=1;
%             NoBlip_tstep=zeros(1,100);
%             
%             for t=1:length(tstep)-2
%                 if tstep(t)==tstep(t+1)-1 && tstep(t)==tstep(t+2)-2
%                     NoBlip_tstep(StateAct_idx)=NoBlip_tstep(StateAct_idx)+1;
%                 elseif tstep(t)~=tstep(t+1)-1 && tstep(t)==tstep(t+2)-2
%                     NoBlip_tstep(StateAct_idx)=NoBlip_tstep(StateAct_idx)+1;
%                 else
%                     StateAct_idx=StateAct_idx+1;
%                 end
%             end
%             
%             trial_MaxAct(n)=max(NoBlip_tstep);
%             trial_MaxAct(n)=m_dur;
        end
       CondState_MeanDur(c_idx,state_nbr)=mean(trial_MaxAct);     
    end
end
        
state_on_FR={};
state_off_FR={};
for state_nbr=1:model.n_states
    state_on_FR{state_nbr}=[];
    state_off_FR{state_nbr}=[];
end

for c_idx=1:length(conditions)

    condition_trials = find(strcmp(data10ms.metadata.condition,conditions{c_idx}));

    %for each state
    for state_nbr=1:model.n_states
        state_idx=model.metadata.state_labels(state_nbr);
        
        StateOnElectrodeFR=[];
        StateOffElectrodeFR=[];
        BaselineFR=[];
                
        on_FR=state_on_FR{state_nbr};
        off_FR=state_off_FR{state_nbr};
        %for each trial
        for n=1:length(condition_trials)            
            
            %use the trial of interest in this condition
            TOI=condition_trials(n);
            
            trial_rows=find((model.state_seq.trial==TOI));            
            
            % Get the bins that we used in the HMM (time>0 and up to reward)
            bin_idx=find((data10ms.bins>=0) & (data10ms.bins<=data10ms.metadata.reward(TOI)));
            sub_bin_idx=find(data10ms.bins(bin_idx)-data10ms.metadata.go(TOI)>=-500);
            trial_times=data10ms.bins(bin_idx(sub_bin_idx));
            
            mask=model.state_seq.state(trial_rows(sub_bin_idx))==state_idx;
                
            onsets = trial_times(strfind([0 mask'], [0 ones(1,min_time_steps)]));
            offsets = trial_times(strfind([mask' 0], [ones(1,min_time_steps) 0]))+min_time_steps;
            durations=offsets-onsets;
            [m_dur,m_idx]=max(durations);
                
            if length(durations)
                onset=onsets(m_idx);
                offset=offsets(m_idx);
                
                % WOI start and end time
                start_time_ON=onset-100;
                end_time_ON=onset+ceil(max(CondState_MeanDur(:,state_nbr)))/2;
                start_time_OFF=offset-ceil(max(CondState_MeanDur(:,state_nbr)))/2;
                end_time_OFF=offset+100;

%                 win_ON_bins=[knnsearch(data.bins',start_time_ON):knnsearch(data.bins',end_time_ON)];
%                 win_OFF_bins=[knnsearch(data.bins',start_time_OFF):knnsearch(data.bins',end_time_OFF)];
%             
%                 baseline_bins=[knnsearch(data.bins',start_time_ON):knnsearch(data.bins',onset)];
% 
%                 BaselineFR=squeeze(mean(data.firing_rate(1,electrodes,TOI,baseline_bins),4));
%             
%                 StateOnElectrodeFR(end+1,:,:)=(squeeze(data.firing_rate(1,electrodes,TOI,win_ON_bins))-repmat(BaselineFR',1,length(win_ON_bins)))./repmat(BaselineFR',1,length(win_ON_bins));
%             
%                 StateOffElectrodeFR(end+1,:,:)=(squeeze(data.firing_rate(1,electrodes,TOI,win_OFF_bins))-repmat(BaselineFR',1,length(win_OFF_bins)))./repmat(BaselineFR',1,length(win_OFF_bins));
                win_ON_bins=[knnsearch(data10ms.bins',start_time_ON):knnsearch(data10ms.bins',end_time_ON)];
                win_OFF_bins=[knnsearch(data10ms.bins',start_time_OFF):knnsearch(data10ms.bins',end_time_OFF)];
            
                baseline_bins=[knnsearch(data10ms.bins',start_time_ON):knnsearch(data10ms.bins',onset)];

                BaselineFR(end+1,:,:)=squeeze(data10ms.smoothed_firing_rate(1,electrodes,TOI,baseline_bins));
            
                StateOnElectrodeFR(end+1,:,:)=squeeze(data10ms.smoothed_firing_rate(1,electrodes,TOI,win_ON_bins));
            
                StateOffElectrodeFR(end+1,:,:)=squeeze(data10ms.smoothed_firing_rate(1,electrodes,TOI,win_OFF_bins));
            end
        end
           
        mean_baseline=mean(mean(BaselineFR,3),1);
        mean_onspikes=(squeeze(mean(StateOnElectrodeFR,1))-repmat(mean_baseline',1,length(win_ON_bins)))./repmat(mean_baseline',1,length(win_ON_bins));
        mean_offspikes=(squeeze(mean(StateOffElectrodeFR,1))-repmat(mean_baseline',1,length(win_OFF_bins)))./repmat(mean_baseline',1,length(win_OFF_bins));
        on_FR(c_idx,:,:)=mean_onspikes;
        off_FR(c_idx,:,:)=mean_offspikes;
        state_on_FR{state_nbr}=on_FR;
        state_off_FR{state_nbr}=off_FR;
    end
end
%         -repmat(BaselineFR',1,length(win_ON_bins)))./repmat(BaselineFR',1,length(win_ON_bins))

f=figure();
set(f, 'WindowState', 'maximized');
set(f,'renderer','Painters')
for c_idx=1:length(conditions)

    condition_trials = find(strcmp(data10ms.metadata.condition,conditions{c_idx}));

    %for each state
    for state_nbr=1:model.n_states

        plot_idx=(c_idx-1)*model.n_states*2+(state_nbr-1)*2;
            
        
        on_FR=state_on_FR{state_nbr};
        off_FR=state_off_FR{state_nbr};
        
        mean_onspikes=squeeze(on_FR(c_idx,:,:));
        mean_offspikes=squeeze(off_FR(c_idx,:,:));
        
        yl=[min([on_FR(:); off_FR(:)])-.1 max([on_FR(:); off_FR(:)])+.1];
        %yl=[-.1 7];
        
        subplot(length(conditions), model.n_states*2, plot_idx+1)
        hold all        
        if state_nbr==1
            ylabel({strrep(conditions{c_idx},'_',' ');''},'FontSize',12,'FontWeight','bold');
        end
        if c_idx==1
            title(sprintf('state %d: onset', state_nbr));
        end
        plot(linspace(-100,ceil(max(CondState_MeanDur(:,state_nbr)))/2,size(mean_onspikes,2)),mean_onspikes,'LineWidth',1.25);
        yline(0,':k','LineWidth',1.5)
        xline(0,'--r','LineWidth',1)
        ylim(yl);
        if c_idx==length(conditions) && state_nbr==1
            xlabel('Time (ms)');
        end

        subplot(length(conditions), model.n_states*2, plot_idx+2)
        hold all
        if c_idx==1
            title(sprintf('state %d: offset', state_nbr));
        end
        plot(linspace(-ceil(max(CondState_MeanDur(:,state_nbr)))/2,100,size(mean_offspikes,2)),mean_offspikes,'LineWidth',1.25);
        yline(0,':k','LineWidth',1.5)
        xline(0,'--r','LineWidth',1)
        ylim(yl);
        yticklabels([]);
        if c_idx==length(conditions) && state_nbr==1
            xlabel('Time (ms)');
        end
        
    end
end
   
sgtitle([subject ' ' array]);

% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'MotorGrasp' 'TvCov_10d_PSTH_OnsetOffset' '.png']));
% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'MotorGrasp' 'TvCov_10d_PSTH_OnsetOffset' '.eps']),'epsc');
