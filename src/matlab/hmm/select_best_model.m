function hmm_results = select_best_model(exp_info, hmm_results, model_name)

% AIC for each number of possible states
hmm_results.AIC_storing = zeros(length(hmm_results.n_state_possibilities),1);
% Index of the run with the maximm log likelihood for each possible number
% of states
hmm_results.maxLL_idx_storing = zeros(length(hmm_results.n_state_possibilities),1);
% Max log likelihood over runs for each possible number of states
hmm_results.maxLL_storing = zeros(length(hmm_results.n_state_possibilities),1);

% Go through each possible number of states
for n=1:length(hmm_results.n_state_possibilities)
    n_states=hmm_results.n_state_possibilities(n);
    
    % Find run with the max log likelihood
    [max_LL,max_idx]=max([hmm_results.models(n,:).sum_log_likelihood]);
    
    % Compute AIC for this run
    num_params=n_states+n_states.^2+33*n_states;
    AIC=(2*num_params)-(2*max_LL);
    
    % Store results
    hmm_results.maxLL_storing(n)=max_LL;
    hmm_results.maxLL_idx_storing(n)=max_idx;
    hmm_results.AIC_storing(n) = AIC;
end

% Plot max log likelihood and AIC
f=figure();
subplot(2,1,1);
plot(hmm_results.n_state_possibilities,hmm_results.maxLL_storing);
xlabel('nstates');
ylabel('LL');
subplot(2,1,2);
plot(hmm_results.n_state_possibilities,hmm_results.AIC_storing);
xlabel('nstates');
ylabel('AIC');
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', hmm_results.subject,[model_name '_AIC_maxLL.png']));
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', hmm_results.subject,[model_name '_AIC_maxLL.eps']), 'epsc');

% Find number of states that minimized AIC
[AIC_min,min_AIC_idx]=min(hmm_results.AIC_storing);

% Save results
hmm_results.best_model_idx=[min_AIC_idx hmm_results.maxLL_idx_storing(min_AIC_idx)];
