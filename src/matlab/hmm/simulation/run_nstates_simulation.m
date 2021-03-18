% RUN_NSTATES_SIMULATION Runs simulation comparing univariate multinomial HMM
% and multivariate Poisson HMM as the number of simulated/model states is
% varied

clear all

%% Set up parameters of simuation
params=[];
% Number of trials to simulate
params.nTrials= 100;
% Maximum firing rate
params.maxFR = 30;
% Length of state sequence to simulate
params.stateSeqLength = 3;
% Time step
params.dt = .001;
% Maximum number of iterations in Baum-Welch
params.maxIterations = 500;
% Number of times to run Baum-Welch (to find model with max LL)
params.numRuns = 10;
% Number of neurons to simulate
params.nNeurons=50;
% Amount of noise to add to the simulated spikes
params.noise_level=0;

% Number of states to simulate or model
n_possible_states=2:10;

results_fname='nstates_simulation_results.mat';
% Restart last simulation
if exist(results_fname,'file')==2
    load(results_fname);
% Start new simulation
else
    % list to save the results
    simulation_results=[];
    % save model results in a list
    simulation_results.trial_data={};
    simulation_results.state_rates={};
    simulation_results.state_seq_vecs={};
    simulation_results.poissonModel={};
    simulation_results.multinomialModel={};
    % Save the last iteration index so can restart from there
    simulation_results.lasti=0;
    simulation_results.poiss_LL=zeros(length(n_possible_states),length(n_possible_states));
    simulation_results.multinomial_LL=zeros(length(n_possible_states),length(n_possible_states));
    simulation_results.poiss_AIC=zeros(length(n_possible_states),length(n_possible_states));
    simulation_results.multinomial_AIC=zeros(length(n_possible_states),length(n_possible_states));
    simulation_results.poiss_BIC=zeros(length(n_possible_states),length(n_possible_states));
    simulation_results.multinomial_BIC=zeros(length(n_possible_states),length(n_possible_states));
end
simulation_results.params=params;
simulation_results.n_possible_states=n_possible_states;
    
% Start from last iteration
for i=simulation_results.lasti+1:length(n_possible_states)
    simulation_results.lasti=i;
    
    params.nActualStates=n_possible_states(i);
    disp(sprintf('%d actual states', params.nActualStates));
    
    [trial_data, state_rates, state_seq_vecs]=create_simulated_data(params);
    n_obs=0;
    for j=1:length(trial_data)
        n_obs=n_obs+size(trial_data{j},2);
    end
    
    simulation_results.trial_data{i}=trial_data;
    simulation_results.state_rates{i}=state_rates;
    simulation_results.state_seq_vecs{i}=state_seq_vecs;
    
    poiss_LL=simulation_results.poiss_LL;
    multinomial_LL=simulation_results.multinomial_LL;
    poiss_AIC=simulation_results.poiss_AIC;
    poiss_BIC=simulation_results.poiss_BIC;
    multinomial_AIC=simulation_results.multinomial_AIC;
    multinomial_BIC=simulation_results.multinomial_BIC;
    
    for j=1:length(n_possible_states)
        new_params=params;
        new_params.nPredictedStates=n_possible_states(j);
        disp(sprintf('%d predicted states', new_params.nPredictedStates));
        [poissonModel, multinomialModel]=run_simulation(new_params, trial_data);
        
        poiss_LL(i,j)=poissonModel.LL;
        multinomial_LL(i,j)=multinomialModel.LL;
        
        n_emissions=size(poissonModel.ESTEMIT,2);
        num_poiss_params=new_params.nPredictedStates*(new_params.nPredictedStates-1)+new_params.nPredictedStates*(n_emissions-1)+(new_params.nPredictedStates-1);
        poiss_AIC(i,j)=-(2*poissonModel.LL)+(2*num_poiss_params);
        poiss_BIC(i,j)=-(2*poissonModel.LL)+num_poiss_params*log(n_obs);            
        
        n_emissions=size(multinomialModel.ESTEMIT,2);
        num_multinomial_params=new_params.nPredictedStates*(new_params.nPredictedStates-1)+new_params.nPredictedStates*(n_emissions-1)+(new_params.nPredictedStates-1);
        multinomial_AIC(i,j)=-(2*multinomialModel.LL)+(2*num_multinomial_params);
        multinomial_BIC(i,j)=-(2*multinomialModel.LL)+num_multinomial_params*log(n_obs);                                    
    end
    simulation_results.poiss_LL=poiss_LL;
    simulation_results.multinomial_LL=multinomial_LL;
    simulation_results.poiss_AIC=poiss_AIC;
    simulation_results.poiss_BIC=poiss_BIC;
    simulation_results.multinomial_AIC=multinomial_AIC;
    simulation_results.multinomial_BIC=multinomial_BIC;
    save(results_fname, 'simulation_results');
end
    

figure();
subplot(2,4,1);
imagesc(n_possible_states,n_possible_states,simulation_results.poiss_LL);
colorbar();
xlabel('Predicted States');
ylabel({'Poisson','Actual States'});
title('LL');
subplot(2,4,2);
imagesc(n_possible_states,n_possible_states,simulation_results.poiss_AIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
title('AIC');
subplot(2,4,3);
imagesc(n_possible_states,n_possible_states,simulation_results.poiss_BIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
title('BIC');
subplot(2,4,4);
imagesc(n_possible_states,n_possible_states,simulation_results.poiss_AIC+simulation_results.poiss_BIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
title('AIC');

subplot(2,4,5);
imagesc(n_possible_states,n_possible_states,simulation_results.multinomial_LL);
colorbar();
xlabel('Predicted States');
ylabel({'Multinomial','Actual States'});
subplot(2,4,6);
imagesc(n_possible_states,n_possible_states,simulation_results.multinomial_AIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
subplot(2,4,7);
imagesc(n_possible_states,n_possible_states,simulation_results.multinomial_BIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
subplot(2,4,8);
imagesc(n_possible_states,n_possible_states,simulation_results.multinomial_AIC+simulation_results.multinomial_BIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');

    