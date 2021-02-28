function hmm_results = model_comparison(exp_info, hmm_results, model_name,...
    varargin)

% Parse optional arguments
defaults=struct('method','AIC+BIC');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

% AIC for each number of possible states
hmm_results.AIC_storing = zeros(size(hmm_results.models,1),1);
hmm_results.BIC_storing = zeros(size(hmm_results.models,1),1);
% Index of the run with the maximm log likelihood for each possible number
% of states
hmm_results.maxLL_idx_storing = zeros(size(hmm_results.models,1),1);
% Max log likelihood over runs for each possible number of states
hmm_results.maxLL_storing = zeros(size(hmm_results.models,1),1);

% Go through each possible number of states
for n=1:size(hmm_results.models,1)
    n_states=hmm_results.n_state_possibilities(n);
    
    % Find run with the max log likelihood
    [max_LL,max_idx]=max(real([hmm_results.models(n,:).sum_log_likelihood]));
    
    % Compute AIC for this run
    if isfield(hmm_results.models(n,1),'EMITGUESS')
        n_emissions=size(hmm_results.models(n,1).EMITGUESS,2);
        num_params=n_states*(n_states-1)+n_states*(n_emissions-1)+(n_states-1);
    else
        n_emissions=size(hmm_results.models(n,1).DAY_EMITGUESS,3);
        n_days=size(hmm_results.models(n,1).DAY_EMITGUESS,1);
        num_params=n_states*(n_states-1)+n_states*(n_emissions-1)+n_days*n_states*(n_emissions-1)+(n_states-1);
    end
    AIC=-(2*max_LL)+(2*num_params);
    
    n_obs=0;
    if isfield(hmm_results,'SEQ')
        for i=1:length(hmm_results.SEQ)
            n_obs=n_obs+length(hmm_results.SEQ{i});
        end
    elseif isfield(hmm_results,'trial_spikes')        
        for i=1:length(hmm_results.trial_spikes)
            n_obs=n_obs+size(hmm_results.trial_spikes{i},2);
        end
    elseif isfield(hmm_results,'day_spikes')
        for i=1:length(hmm_results.day_spikes)
            trial_spikes=hmm_results.day_spikes{i};
            for j=1:length(trial_spikes)
                n_obs=n_obs+size(trial_spikes{j},2);
            end
        end
    end
    BIC=-(2*max_LL)+num_params*log(n_obs);            
    
    % Store results
    hmm_results.maxLL_storing(n)=max_LL;
    hmm_results.maxLL_idx_storing(n)=max_idx;
    hmm_results.AIC_storing(n) = AIC;
    hmm_results.BIC_storing(n) = BIC;
end

% Plot max log likelihood and AIC
f=figure();
subplot(4,1,1);
plot(hmm_results.n_state_possibilities(1:size(hmm_results.models,1)),hmm_results.maxLL_storing);
xlabel('nstates');
ylabel('LL');
subplot(4,1,2);
hold all;
plot(hmm_results.n_state_possibilities(1:size(hmm_results.models,1)),hmm_results.AIC_storing);
[minAIC, minAICIdx]=min(hmm_results.AIC_storing);
plot([hmm_results.n_state_possibilities(minAICIdx) hmm_results.n_state_possibilities(minAICIdx)],ylim(),'k--');
xlabel('nstates');
ylabel('AIC');
subplot(4,1,3);
hold all;
plot(hmm_results.n_state_possibilities(1:size(hmm_results.models,1)),hmm_results.BIC_storing);
[minBIC, minBICIdx]=min(hmm_results.BIC_storing);
plot([hmm_results.n_state_possibilities(minBICIdx) hmm_results.n_state_possibilities(minBICIdx)],ylim(),'k--');
xlabel('nstates');
ylabel('BIC');
subplot(4,1,4);
hold all;
plot(hmm_results.n_state_possibilities(1:size(hmm_results.models,1)),hmm_results.AIC_storing+hmm_results.BIC_storing);
[minAICBIC, minAICBICIdx]=min(hmm_results.AIC_storing+hmm_results.BIC_storing);
plot([hmm_results.n_state_possibilities(minAICBICIdx) hmm_results.n_state_possibilities(minAICBICIdx)],ylim(),'k--');
xlabel('nstates');
ylabel('AIC+BIC');
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', hmm_results.subject,[model_name '_AIC-BIC_maxLL.png']));
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', hmm_results.subject,[model_name '_AIC-BIC_maxLL.eps']), 'epsc');

% Find number of states that minimized metric
if strcmp(params.method,'AIC+BIC')
    [metric_min,min_metric_idx]=min(hmm_results.AIC_storing+hmm_results.BIC_storing);
elseif strcmp(params.method,'AIC')
    [metric_min,min_metric_idx]=min(hmm_results.AIC_storing);
elseif strcmp(params.method,'BIC')
    [metric_min,min_metric_idx]=min(hmm_results.BIC_storing);
end

% Save results
hmm_results.best_model_idx=[min_metric_idx hmm_results.maxLL_idx_storing(min_metric_idx)];
