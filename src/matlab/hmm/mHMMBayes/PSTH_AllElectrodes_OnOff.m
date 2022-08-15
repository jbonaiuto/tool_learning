% PSTH_State
addpath('../../');
exp_info=init_exp_info();
rmpath('../../');
% LOAD THE DATA WITH 1MS BIN SIZE
dt=1;
% subject='betta';
% array='F1';
% %array='F5hand';
% %condition='motor_grasp_right';
% conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};
model
array
subject
conditions
dates
output_path
data
electrodes
%state_nbr=5;
win_len=100;

kernel_width=9; % Kernel width used to smooth data before normalizing
kernel=gausswin(kernel_width);

% Betta's date
% dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
%     '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19',...
%     '13.03.19','14.03.19','15.03.19','18.03.19','19.03.19',...
%     '20.03.19','21.03.19','25.03.19'};


% output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
%     'motor_grasp', '5w_multiday_condHMM', array);
% output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
%     'motor_grasp', '2w_multiday_condHMM', array);

%model=get_best_model(output_path, 'type', 'condition_covar');

%load(fullfile(output_path,'data.mat'));
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

%daySTATE_idx=zeros(length(dates),model.n_states*2);
daySTATE_idx={};


f=figure();
set(f, 'WindowState', 'maximized');

% For each condition
for c_idx=1:length(conditions)

    condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
    trial_date=data.trial_date(condition_trials);

    %for each state
    for state_nbr=1:model.n_states

        plot_idx=(c_idx-1)*model.n_states*2+(state_nbr-1)*2;

        state=model.forward_probs.(sprintf('fw_prob_S%d',state_nbr));

        %subplot(length(conditions),model.n_states, sub2ind([length(conditions),model.n_states],c_idx,state_nbr));

        % Spikes surrounding (before and after) each transition to this state
        % across all trials from all days
        %StateElectrodeSpikes=[];
        BaselineSpikes=[];
        StateOnElectrodeSpikes=[];
        StateOffElectrodeSpikes=[];

        % For every date
        for d=1:length(dates)
            % Find trials from this date for this condition
            day_trials=condition_trials(trial_date==d);

            % For each trial from this day in this condition
            for n=1:length(day_trials)

                % Rows of forward probabilities for this trial
                trial_rows=find((model.forward_probs.subj==day_trials(n)));
                if strcmp(model.type,'multilevel')
                    trial_rows=find((model.forward_probs.subj==d) & (model.forward_probs.rm==n));
                end
                DayTrialSTATE=state(trial_rows);

                % Get the bins that we used in the HMM (time>0 and up to reward)
                bin_idx=find((data10ms.bins>=0) & (data10ms.bins<=data10ms.metadata.reward(day_trials(n))));

                above_thresh=DayTrialSTATE>0.5;
                state_trans=diff(above_thresh);

                onset_times=find(state_trans==1)+1;
                offset_times=find(state_trans==-1);

                % For each threshold crossing
                for i=1:length(onset_times)
                    % Find the time (from the downsampled multiunit data) where the threshold is crossed
                    threshONCrossIdx=onset_times(i);

                    threshONCrossTime=data10ms.bins(bin_idx(threshONCrossIdx));

                    % WOI start and end time
                    start_time_ON=threshONCrossTime-50;
                    end_time_ON=threshONCrossTime+50;

                    woi_bins=[knnsearch(data.bins',start_time_ON):knnsearch(data.bins',end_time_ON)];
                    baseline_bins=[knnsearch(data.bins',start_time_ON):knnsearch(data.bins',threshONCrossTime)];

                    BaselineSpikes(end+1,:)=mean(data.binned_spikes(1,electrodes,day_trials(n),baseline_bins),4);
                    StateOnElectrodeSpikes(end+1,:,:)=squeeze(data.binned_spikes(1,electrodes,day_trials(n),woi_bins));
                end

                for i=1:length(offset_times)
                    % Find the time (from the downsampled multiunit data) where the threshold is crossed
                    threshOFFCrossIdx=offset_times(i);

                    threshOFFCrossTime=data10ms.bins(bin_idx(threshOFFCrossIdx));

                    % WOI start and end time
                    start_time_OFF=threshOFFCrossTime-50;
                    end_time_OFF=threshOFFCrossTime+50;

                    woi_bins=[knnsearch(data.bins',start_time_OFF):knnsearch(data.bins',end_time_OFF)];

                    StateOffElectrodeSpikes(end+1,:,:)=squeeze(data.binned_spikes(1,electrodes,day_trials(n),woi_bins));
                end
            end
        end

        for i=1:size(StateOnElectrodeSpikes,1)
            StateOnElectrodeSpikes(i,:,:)=squeeze(StateOnElectrodeSpikes(i,:,:))-repmat(mean(BaselineSpikes,1)',1,length(woi_bins));
            for j=1:length(electrodes)
                StateOnElectrodeSpikes(i,j,:)=filtfilt(kernel,3,squeeze(StateOnElectrodeSpikes(i,j,:)));
            end
        end
        for i=1:size(StateOffElectrodeSpikes,1)
            StateOffElectrodeSpikes(i,:,:)=squeeze(StateOffElectrodeSpikes(i,:,:))-repmat(mean(BaselineSpikes,1)',1,length(woi_bins));
            for j=1:length(electrodes)
                StateOffElectrodeSpikes(i,j,:)=filtfilt(kernel,3,squeeze(StateOffElectrodeSpikes(i,j,:)));
            end
        end
        
        mean_onspikes=squeeze(mean(StateOnElectrodeSpikes,1));
        mean_offspikes=squeeze(mean(StateOffElectrodeSpikes,1));
        
        yl=[min([mean_onspikes(:); mean_offspikes(:)])-.1 max([mean_onspikes(:); mean_offspikes(:)])+.1];
        
        subplot(length(conditions), model.n_states*2, plot_idx+1)
        hold all        
        if state_nbr==1
            ylabel({strrep(conditions{c_idx},'_',' ');''},'FontSize',12,'FontWeight','bold');
        end
        if c_idx==1
            title(sprintf('state %d: onset', state_nbr));
        end
        plot([-50:dt:50],mean_onspikes);
        plot([0 0],yl,'r--');
        ylim(yl);
        if c_idx==length(conditions) && state_nbr==1
            xlabel('Time (ms)');
        end
        
        subplot(length(conditions), model.n_states*2, plot_idx+2)
        hold all
        if c_idx==1
            title(sprintf('state %d: offset', state_nbr));
        end
        plot([-50:dt:50],mean_offspikes);
        plot([0 0],yl,'r--');
        ylim(yl);
        yticklabels([]);
        if c_idx==length(conditions) && state_nbr==1
            xlabel('Time (ms)');
        end
    end
end
   
sgtitle([subject ' ' array]);

% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'grasp' 'TvCov_10d_PSTH_OnsetOffset' '.png']));
% saveas(f,fullfile(output_path,...
%      [subject '_' array '_' 'grasp' 'TvCov_10d_PSTH_OnsetOffset' '.eps']),'epsc');

    
    


