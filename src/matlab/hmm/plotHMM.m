function plotHMM(exp_info, subject, model_name, varargin)

% Parse optional arguments
defaults=struct('n_states',[]);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

dbstop if error

file_name=fullfile(exp_info.base_output_dir, 'HMM', subject, model_name, 'hmm_results.mat');
load(file_name);
if length(params.n_states)==0
    model=hmm_results.models(hmm_results.best_model_idx(1),hmm_results.best_model_idx(2));
else
    idx=find(hmm_results.n_state_possibilities==params.n_states);
    model=hmm_results.models(idx,1);
end

addpath('../spike_data_processing');
date_data={};
for i=1:length(hmm_results.dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        hmm_results.dates{i},'multiunit','binned',...
        sprintf('fr_b_F1_%s_whole_trial.mat',hmm_results.dates{i})));
    date_data{i}=data;
    clear('datafr');
end
data=concatenate_data(date_data, 'spike_times', false);
clear('date_data');
   
colors=cbrewer('qual','Paired',12);

ALL_PSTATES={};
if isfield(hmm_results,'trial_spikes')
    for n=1:length(hmm_results.trial_spikes)
        ALL_PSTATES{n} = hmmdecodePoiss(hmm_results.trial_spikes{n},model.ESTTR,model.ESTEMIT,.001);
    end
elseif isfield(hmm_results,'day_spikes')
    for d=1:length(hmm_results.day_spikes)
        trial_spikes=hmm_results.day_spikes{d};
        effectiveE=model.GLOBAL_ESTEMIT+squeeze(model.DAY_ESTEMIT(d,:,:));
        for n=1:length(trial_spikes)
            ALL_PSTATES{end+1} = hmmdecodePoiss(trial_spikes{n},model.ESTTR,effectiveE,.001);
        end
    end
else
    for n=1:length(hmm_results.SEQ)
        ALL_PSTATES{n} = hmmdecode(hmm_results.SEQ{n},model.ESTTR,model.ESTEMIT,'Symbols',[0:32]);
    end
end

for n=1:length(ALL_PSTATES)
    PSTATES=ALL_PSTATES{n};
    
    f=figure();
    hold all 
    
    labels={};
    ylim([0 1.2]);
    set(f, 'Position', get(0, 'Screensize'));
    title(sprintf('Motor grasp : F1 trial %d',hmm_results.trials(n)));
    for m=1:model.n_states
        plot(PSTATES(m,:),'LineWidth',2,'Color',colors(m,:));
        labels{end+1}=sprintf('state %d',m);
    end
    for e=1:length(data.metadata.event_types)
        evt_type=data.metadata.event_types{e};
        evt_times=data.metadata.(evt_type);
        trl_evt_time=evt_times(hmm_results.trials(n));
        if ~isnan(trl_evt_time) && trl_evt_time>0 && trl_evt_time<size(PSTATES,2)
            plot([trl_evt_time trl_evt_time],ylim(),':k');
            text(trl_evt_time,1.1,strrep(evt_type,'_',' '),'BackgroundColor', 'w','rotation',45);
        end
    end
    legend(labels);
    
    bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(hmm_results.trials(n)))));
    raster_data=squeeze(data.binned_spikes(:,:,hmm_results.trials(n),bin_idx));
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
