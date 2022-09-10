function PSTH_OnOff_MostLikelyStateSequence_OneWindow(model,array,subject,conditions,dates,electrodes,data,output_path)

% comment dbstop if not debugging something
dbstop if error

addpath('../../');
exp_info=init_exp_info();
rmpath('../../');

% LOAD THE DATA WITH 1MS BIN SIZE
dt=1;

kernel_width=9; % Kernel width used to smooth data before normalizing
kernel=gausswin(kernel_width);

data10ms=data;

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
for c_idx=1%:length(conditions)

    condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));

    %for each state
    for state_nbr=1:model.n_states
        state=model.metadata.state_labels(state_nbr);
        
        trial_MaxAct=zeros(1,length(condition_trials));
        
        %for each trial
        for n=1:length(condition_trials)
               
            %use the trial of interest in this condition
            TOI=condition_trials(n);
            RowsOI=find(model.state_seq.trial==TOI & model.state_seq.state==state);
            
            tstep=model.state_seq.tstep(RowsOI);
            StateAct_idx=1;
            NoBlip_tstep=zeros(1,100);
            
            for t=1:length(tstep)-2
                if tstep(t)==tstep(t+1)-1 && tstep(t)==tstep(t+2)-2
                    NoBlip_tstep(StateAct_idx)=NoBlip_tstep(StateAct_idx)+1;
                elseif tstep(t)~=tstep(t+1)-1 && tstep(t)==tstep(t+2)-2
                    NoBlip_tstep(StateAct_idx)=NoBlip_tstep(StateAct_idx)+1;
                else
                    StateAct_idx=StateAct_idx+1;
                end
            end
            
            trial_MaxAct(n)=max(NoBlip_tstep);
        end
       CondState_MeanDur(c_idx,state_nbr)=mean(trial_MaxAct);     
    end
end

%convert dur in bin into ms
CondState_MeanDur=CondState_MeanDur*10;

mean_onspikes=zeros(length(electrodes),900,state_nbr,c_idx);
for c_idx=1:length(conditions)

    condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));

    %for each state
    for state_nbr=1:model.n_states
        state=model.metadata.state_labels(state_nbr);
        
        %for each trial
        for n=1:length(condition_trials)
            
            plot_idx=(c_idx-1)*model.n_states+(state_nbr-1);
            
            %use the trial of interest in this condition
            TOI=condition_trials(n);
            
            %subplot(length(conditions),model.n_states, sub2ind([length(conditions),model.n_states],c_idx,state_nbr));

            % Spikes surrounding (before and after) each transition to this state
            % across all trials from all days
            %StateElectrodeSpikes=[];
            BaselineSpikes=[];
            StateOnElectrodeSpikes=[];
            StateOffElectrodeSpikes=[];

            TrialSTATE=find(model.state_seq.trial==TOI & model.state_seq.state==state);
            
            if length(TrialSTATE)<2
                continue
            end
            
            %get rid of the blips in the the state/trail rows
%             lenght_TrialSTATE_WithBlip=length(TrialSTATE);
            
            longestActiv=[cumsum(diff(TrialSTATE)~=1)];
            
            TrialSTATE=TrialSTATE(longestActiv==mode(longestActiv));
            
            % Get the bins that we used in the HMM (time>0 and up to reward)
            bin_idx=find((data10ms.bins>=0) & (data10ms.bins<=data10ms.metadata.reward(TOI)));
            

%             onset_times=nonzeros(onset_times);
            onset_times=model.state_seq.tstep(TrialSTATE(1));
            offset_times=model.state_seq.tstep(TrialSTATE(end));

            % Find the time (from the downsampled multiunit data) where the threshold is crossed
            threshONCrossTime=data10ms.bins(bin_idx(onset_times));
            threshOFFCrossTime=data10ms.bins(bin_idx(offset_times));
            
            % WOI start and end time
            %start_time_OFF=threshOFFCrossTime-ceil(max(CondState_MeanDur(:,state_nbr)));
            start_time_ON=threshONCrossTime-50;
            end_time_ON=threshONCrossTime+ceil(max(CondState_MeanDur(:,state_nbr)));
%             start_time_OFF=threshOFFCrossTime-ceil(max(CondState_MeanDur(:,state_nbr)));
%             end_time_OFF=threshOFFCrossTime+50;
            start_time_OFF=threshONCrossTime;
            end_time_OFF=threshONCrossTime+ceil(max(CondState_MeanDur(:,state_nbr)))+50;

            

            win_ON_bins=[knnsearch(data.bins',start_time_ON):knnsearch(data.bins',end_time_ON)];
            win_OFF_bins=[knnsearch(data.bins',start_time_OFF):knnsearch(data.bins',end_time_OFF)];
            
            baseline_bins=[knnsearch(data.bins',start_time_ON):knnsearch(data.bins',threshONCrossTime)];

            BaselineSpikes(end+1,:)=mean(data.binned_spikes(1,electrodes,TOI,baseline_bins),4);
            %BaselineSpikes(end+1,:)=mean(data.firing_rate(1,electrodes,TOI,baseline_bins),4);
            
            StateOnElectrodeSpikes(end+1,:,:)=squeeze(data.binned_spikes(1,electrodes,TOI,win_ON_bins));
            %StateOnElectrodeSpikes(end+1,:,:)=squeeze(data.firing_rate(1,electrodes,TOI,win_ON_bins));
            
            StateOffElectrodeSpikes(end+1,:,:)=squeeze(data.binned_spikes(1,electrodes,data.trial_date(TOI),win_OFF_bins));
            %StateOffElectrodeSpikes(end+1,:,:)=squeeze(data.firing_rate(1,electrodes,data.trial_date(TOI),win_OFF_bins));

        end    
       
    if isempty(StateOnElectrodeSpikes)==1 || isempty(StateOffElectrodeSpikes)==1
            continue
    end

        for i=1:size(StateOnElectrodeSpikes,1)
            StateOnElectrodeSpikes(i,:,:)=squeeze(StateOnElectrodeSpikes(i,:,:))-repmat(mean(BaselineSpikes,1)',1,length(win_ON_bins));
            for j=1:length(electrodes)
                StateOnElectrodeSpikes(i,j,:)=filtfilt(kernel,3,squeeze(StateOnElectrodeSpikes(i,j,:)));
            end
        end
       
        mean_onspikes(:,:,state_nbr,c_idx)=squeeze(mean(StateOnElectrodeSpikes,1));

        
    end
end        

f1=figure();
set(f1, 'WindowState', 'maximized');

for c_idx=1:length(conditions)
    yl=[min(mean_onspikes(c_idx,:))-.1 max(mean_onspikes(c_idx,:))+.1];
    for state_nbr=1:model.n_states
        subplot(length(conditions), model.n_states, plot_idx+1 )
        hold all        
        if state_nbr==1
            ylabel({strrep(conditions{c_idx},'_',' ');''},'FontSize',12,'FontWeight','bold');
        end
        if c_idx==1
            title(sprintf('state %d', state_nbr));
        end
        plot([-50:dt:ceil(max(CondState_MeanDur(:,state_nbr)))],mean_onspikes);
        plot([0 0],yl,'r--');
        ylim(yl);
        if c_idx==length(conditions) && state_nbr==1
            xlabel('Time (ms)');
        end
    end
end
sgtitle([subject ' ' array 'by condition']);

f2=figure();
set(f2, 'WindowState', 'maximized');
for c_idx=1:length(conditons)
    for state_nbr=1:model.n_states
        yl=[min(mean_onspikes(:,state_nbr))-.1 max(mean_onspikes(:,state_nbr))+.1];
        subplot(length(conditions), model.n_states, plot_idx+1 )
        hold all        
        if state_nbr==1
            ylabel({strrep(conditions{c_idx},'_',' ');''},'FontSize',12,'FontWeight','bold');
        end
        if c_idx==1
            title(sprintf('state %d', state_nbr));
        end
        plot([-50:dt:ceil(max(CondState_MeanDur(:,state_nbr)))],mean_onspikes);
        plot([0 0],yl,'r--');
        ylim(yl);
        if c_idx==length(conditions) && state_nbr==1
            xlabel('Time (ms)');
        end
    end
end
sgtitle([subject ' ' array 'by states']);

% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'MotorGrasp' 'TvCov_10d_PSTH_OnsetOffset' '.png']));
% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'MotorGrasp' 'TvCov_10d_PSTH_OnsetOffset' '.eps']),'epsc');
