% {'01.02.19','04.02.19','05.02.19','06.02.19','07.02.19','08.02.19','11.02.19','12.02.19','13.02.19','14.02.19','18.02.19','19.02.19','20.02.19'}
% %

%
% 
function time_frequency_go_aligned(exp_info, subject)

base_data_path=fullfile('/data/tool_learning/preprocessed_data', subject);

% Dates to load data from
dates={'01.02.19','04.02.19','01.04.19'};

% Conditions to analyze
conditions={'visual_grasp', 'motor_grasp', 'visual_pliers', 'visual_rake_pull'};

% Events to plot
events={'trap_edge','monkey_handle_off','exp_start_off','exp_grasp_center',...
    'tool_start_off','go'};
events_idx=zeros(1,length(events));
for i=1:length(events)
    event=events{i};
    events_idx(i)=find(strcmp(exp_info.event_types,event));
end

plot_lims=[-0.5 2.75];

% Analysis parameters
params=[];
params.visual_grasp.baseline_epoch=[-1 .5];
params.visual_grasp.epoch=[-1 1.75];
params.visual_grasp.directions={'left','right'};
params.visual_grasp.baseline_window = [-.5 0]; % in s
params.visual_grasp.plot_time=[-.5 1.5];

params.motor_grasp.baseline_epoch=[-1 .5];
params.motor_grasp.epoch=[-1 1.75];
params.motor_grasp.directions={'left','center','right'};
params.motor_grasp.baseline_window = [-.5 0]; % in s
params.motor_grasp.plot_time=[-.5 1.5];

params.visual_pliers.baseline_epoch=[-1 .5];
params.visual_pliers.epoch=[-1 3];
params.visual_pliers.directions={'left','right'};
params.visual_pliers.baseline_window = [-.5 0]; % in s
params.visual_pliers.plot_time=[-.5 2.75];

params.visual_rake_pull.baseline_epoch=[-1 .5];
params.visual_rake_pull.epoch=[-1 3];
params.visual_rake_pull.directions={'left','right'};
params.visual_rake_pull.baseline_window = [-.5 0]; % in s
params.visual_rake_pull.plot_time=[-.5 2.75];

% All trials from each condition
all_data=[];
all_data.visual_grasp={};
all_data.visual_pliers={};
all_data.visual_rake_pull={};
all_data.motor_grasp={};
% All baseline data from each condition
all_data.visual_grasp_baseline={};
all_data.visual_pliers_baseline={};
all_data.visual_rake_pull_baseline={};
all_data.motor_grasp_baseline={};

% Load data for each date
for i=1:length(dates)
    % Load LFP mat file
    fname=fullfile(base_data_path, dates{i}, 'lfps', sprintf('%s_%s_lfp.mat', subject, dates{i}));
    load(fname);
    
    for j=1:length(conditions)
        condition=conditions{j};
        condition_params=params.(condition);
        base_conditions={};
        for k=1:length(condition_params.directions)
            direction=condition_params.directions{k};
            base_conditions{end+1}=sprintf('%s_%s', condition, direction);
        end
        all_data.(sprintf('%s_baseline', condition)){i}=epoch(exp_info, data, 'go',...
            condition_params.baseline_epoch, base_conditions, 'exclude_bad_trials',...
            true);
        all_data.(condition){i}=epoch(exp_info, data, 'go', condition_params.epoch,...
            base_conditions, 'exclude_bad_trials', true);
    end
end
        

% Concatenate data
for i=1:length(conditions)
    condition=conditions{i};
    condition_data=all_data.(sprintf('%s_baseline', condition));
    concat_data=concatenate_data(exp_info,...
        condition_data);
    all_data.(sprintf('%s_baseline', condition))=concat_data;
    
    condition_data=all_data.(condition);
    concat_data=concatenate_data(exp_info, condition_data);
    all_data.(condition)=concat_data;
end

for i=1:length(conditions)
    condition=conditions{i};
    all_data.(condition).event_mean_times=[];
    for j=1:length(events)
        event_idx=events_idx(j);
        all_data.(condition).event_mean_times(j)=nanmean(all_data.(condition).trialinfo(:,2+event_idx));
    end
end       


% frequency parameters
min_freq =  2;
max_freq = 100;
num_frex = 120;
% Frequencies to determine power at
frex = linspace(min_freq,max_freq,num_frex);
%frex = logspace(log10(min_freq),log10(max_freq),num_frex);

% Time frequency configuration
cfg_TF              = [];
cfg_TF.output       = 'pow';
cfg_TF.channel      = 'all';
cfg_TF.method       = 'mtmconvol';
cfg_TF.taper        = 'hanning';
cfg_TF.pad          = 'nextpow2';
cfg_TF.keeptrials   = 'yes';
cfg_TF.foi          = frex;
cfg_TF.t_ftimwin    = ones(length(cfg_TF.foi),1).*0.5;   % length of time window = 0.5 sec

for i=1:length(conditions)
    condition=conditions{i};
    condition_data=all_data.(condition);
    condition_times=condition_data.time{1};
    cfg_TF.toi          = condition_times;          
    tf_data = ft_freqanalysis(cfg_TF, condition_data);

	condition_baseline_data=all_data.(sprintf('%s_baseline', condition));
    condition_baseline_times=condition_baseline_data.time{1};
    cfg_TF.toi          = condition_baseline_times;      
    tf_baseline_data = ft_freqanalysis(cfg_TF, condition_baseline_data);
    baselinetime_idx=dsearchn(condition_baseline_times',params.(condition).baseline_window');
    
    % Baseline correct (log normalize) each trial
    n_trials=length(condition_data.trial);
    n_chans=length(condition_data.label);
    n_freqs=length(tf_data.freq);
    n_pts=length(tf_data.time);
    trial_tf=zeros(n_trials,n_chans,n_freqs,n_pts);
    for triali=1:n_trials
        for ch=1:n_chans
            % dB-correct
            trial_tf_data=squeeze(tf_data.powspctrm(triali,ch,:,:));
            baseline_power = squeeze(mean(tf_baseline_data.powspctrm(triali,ch,:,baselinetime_idx(1):baselinetime_idx(2)),4));
            dbconverted = 10*log10( bsxfun(@rdivide,trial_tf_data,baseline_power));
            trial_tf(triali,ch,:,:)=dbconverted;
        end
    end
    plotidx = dsearchn(condition_times',params.(condition).plot_time');
    % Average over trials
    all_data.(sprintf('%s_tf', condition))=squeeze(mean(trial_tf(:,:,:,plotidx(1):plotidx(2)),1));
end

%for labeli = 1:length(all_data.visual_grasp.label)
    labeli=find(strcmp(all_data.visual_grasp.label,'F5hand_22'));
    
    % plot results
    chantf=[];
    max_abs=-Inf;
    for i=1:length(conditions)
        condition=conditions{i};
        condition_tf=all_data.(sprintf('%s_tf', condition));
        cond_chan_tf=squeeze(condition_tf(labeli, : ,:));
        if max(abs(cond_chan_tf(:)))>max_abs
            max_abs=max(abs(cond_chan_tf(:)));
        end
        chantf.(condition)=cond_chan_tf;
    end
    max_abs=.9*max_abs;
        
    f= figure();
    for i=1:length(conditions)
        condition=conditions{i};
        condition_data=all_data.(condition);
        condition_times=condition_data.time{1};
        plotidx = dsearchn(condition_times',params.(condition).plot_time');
        
        subplot(length(conditions),1,i);
        imagesc(condition_times(plotidx(1):plotidx(2)),frex,chantf.(condition));
        set(gca,'xlim',plot_lims);
        set(gca,'ydir','normal')
        set(gca,'clim',[-max_abs max_abs]);
        %set(gca,'ytick',round(round(logspace(log10(frex(1)),log10(frex(end)),10)*100)/100),'yscale','log')
        hold on
        plot([0 0], [frex(1) frex(end)], '--w');    
        for j=1:length(events)
            mean_offset=all_data.(condition).event_mean_times(j);
            plot([mean_offset mean_offset], [frex(1) frex(end)], '--k');    
        end
        xlabel('Time (s)');
        ylabel('Frequency (Hz)');
        title([condition ': ', strrep(condition_data.label{labeli},'_',' ')])
        h=colorbar();
        title(h,'Power (dB)');
    end    
    set(f, 'PaperUnits', 'inches');
    x_width=7.25 ;y_width=9.125;
    set(f, 'PaperPosition', [0 0 x_width y_width]); %
    %saveas(f, fullfile('C:\Users\kirchher\project\tool_learning\output\figures\lfp\betta\go_aligned', [visual_grasp_data.label{labeli} '.png']));
    %saveas(f, fullfile('C:\Users\kirchher\project\tool_learning\output\figures\lfp\betta\go_aligned', [visual_grasp_data.label{labeli} '.eps']), 'epsc');
    %close(f);
    
    f=figure(); %clf    
    CT=cbrewer('div', 'RdBu', 100);
    colormap(flipud(CT));
    
    subplot(4,1,1);
    cond_diff=chantf.motor_grasp-chantf.visual_grasp;
    condition_times=all_data.motor_grasp.time{1};
    plotidx = dsearchn(condition_times',params.motor_grasp.plot_time');
    maxabs=.9.*max(abs(cond_diff(:)));
    imagesc(condition_times(plotidx(1):plotidx(2)),frex,cond_diff);
    set(gca,'xlim',plot_lims);
    set(gca,'ydir','normal')
    set(gca,'clim',[-maxabs maxabs]);
    %set(gca,'ytick',round(round(logspace(log10(frex(1)),log10(frex(end)),10)*100)/100),'yscale','log')
    hold on
    plot([0 0], [frex(1) frex(end)], '--k');        
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title(['motor grasp - visual grasp: ', strrep(all_data.motor_grasp.label{labeli},'_',' ')])
    h=colorbar();
    title(h,'Power (dB)');
        
    set(f, 'PaperUnits', 'inches');
    x_width=7.25 ;y_width=9.125;
    set(f, 'PaperPosition', [0 0 x_width y_width]); %
    %saveas(f, fullfile('C:\Users\kirchher\project\tool_learning\output\figures\lfp\betta\go_aligned', [visual_grasp_data.label{labeli} '_motor-visual_grasp.png']));
    %saveas(f, fullfile('C:\Users\kirchher\project\tool_learning\output\figures\lfp\betta\go_aligned', [visual_grasp_data.label{labeli} '_motor-visual_grasp.eps']),'epsc');
    %close(f);
%end

