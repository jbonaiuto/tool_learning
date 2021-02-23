function plotHMM(exp_info, subject, dates, array, conditions, model, varargin)

% Parse optional arguments
defaults=struct();
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

addpath('../spike_data_processing');
date_data={};
for i=1:length(dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dates{i},'multiunit','binned',...
        sprintf('fr_b_%s_%s_whole_trial.mat', array, dates{i})));
    date_data{i}=data;
    clear('data');
end

data=concatenate_data(date_data, 'spike_times', false);
data=filter_data(data);
% Compute dt
dt=(data.bins(2)-data.bins(1))/1000;

condition_trials=zeros(1,length(data.metadata.condition));
for i=1:length(conditions)
    condition_trials = condition_trials | (strcmp(data.metadata.condition,conditions{i}));
end
condition_trials=find(condition_trials);
trial_date=data.trial_date(condition_trials);

clear('date_data');

colors=cbrewer('qual','Paired',12);

ALL_PSTATES={};
if strcmp(model.type,'multivariate_poisson')
    for n=1:length(condition_trials)
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(condition_trials(n)))));

        trial_spikes=squeeze(data.binned_spikes(1,:,condition_trials(n),bin_idx));
        ALL_PSTATES{n} = hmmdecodePoiss(trial_spikes,model.ESTTR,model.ESTEMIT,dt);
    end
elseif strcmp(model.type,'multilevel_multivariate_poisson')
    t_idx=1;
    for d=1:length(dates)
        day_trials=condition_trials(trial_date==d);

        effectiveE=model.GLOBAL_ESTEMIT+squeeze(model.DAY_ESTEMIT(d,:,:));
    
        for n=1:length(day_trials)
            % Get the bins that we used in the HMM (time>0 and up to reward)
            bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(day_trials(n)))));

            trial_spikes=squeeze(data.binned_spikes(1,:,day_trials(n),bin_idx));
            ALL_PSTATES{end+1} = hmmdecodePoiss(trial_spikes,model.ESTTR,effectiveE,dt);
        end
    end
else
    for n=1:length(condition_trials)
        % Get the bins that we used in the HMM (time>0 and up to reward)
        bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(condition_trials(n)))));

        trial_spikes=squeeze(data.binned_spikes(1,:,condition_trials(n),bin_idx));

        % Create symbol sequence for this trial
        vec = create_symbol_vector(trial_spikes);
        ALL_PSTATES{n} = hmmdecode(vec,model.ESTTR,model.ESTEMIT,'Symbols',[0:32]);
    end
end

for n=1:length(ALL_PSTATES)
    PSTATES=ALL_PSTATES{n};
    bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(condition_trials(n)))));
    trial_firing_rates=squeeze(data.smoothed_firing_rate(1,:,condition_trials(n),bin_idx));
    
    f=figure();
    ax=subplot(2,1,1);
    fr_colors=get(gca,'ColorOrder');
    hold all
    electrode_labels={};
    for m=1:length(data.electrodes)
        plot(data.bins(bin_idx),trial_firing_rates(m,:)./max(trial_firing_rates(:)),'Color',fr_colors(mod(m-1,7)+1,:));
        electrode_labels{end+1}=sprintf('electrode %d',m);
    end
    xlim([data.bins(bin_idx(1)) data.bins(bin_idx(end))]);
    orig_pos=get(ax,'Position');
    l=legend(electrode_labels,'Location','bestoutside');
    set(ax,'Position',orig_pos);
    
    ax=subplot(2,1,2);
    hold all     
    labels={};
    ylim([0 1.2]);
    set(f, 'Position', get(0, 'Screensize'));
    title(sprintf('Motor grasp : F1 trial %d',condition_trials(n)));
    for m=1:model.n_states
        plot(data.bins(bin_idx),PSTATES(m,:),'LineWidth',2,'Color',colors(m,:));
        labels{end+1}=sprintf('state %d',m);
    end
    for e=1:length(data.metadata.event_types)
        evt_type=data.metadata.event_types{e};
        evt_times=data.metadata.(evt_type);
        trl_evt_time=evt_times(condition_trials(n));
        if ~isnan(trl_evt_time) && trl_evt_time>0 && trl_evt_time<size(PSTATES,2)
            plot([trl_evt_time trl_evt_time],ylim(),':k');
            text(trl_evt_time,1.1,strrep(evt_type,'_',' '),'BackgroundColor', 'w','rotation',45);
        end
    end
    orig_pos=get(ax,'Position');
    legend(labels,'Location','bestoutside');
    set(ax,'Position',orig_pos);
    
    raster_data=squeeze(data.binned_spikes(:,:,condition_trials(n),bin_idx));
    neuron_idx=[1:32]./33;
    for n_idx=1:32
        spike_times=find(raster_data(n_idx,:)==1);
        plot(spike_times, neuron_idx(n_idx).*ones(size(spike_times)),'.k');
    end
    xlim([data.bins(bin_idx(1)) data.bins(bin_idx(end))]);
    plot(xlim(),[0.6 0.6],'-.k');
    
    %saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, [model_name '_',sprintf('%d',hmm_results.trials(n)) '.png']));
    %saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, [model_name '_',sprintf('%d',hmm_results.trials(n)) '.eps']), 'epsc');
    %close(f);
end
