% RUN_NOISE_SIMULATION Runs simulation comparing univariate multinomial HMM
% and multivariate Poisson HMM as neurons are added to the network

clear all

%% Set up parameters of simuation
params=[];
% Number of trials to simulate
params.nTrials= 100;
% Number of states to simulate
params.nActualStates = 3;
% Number of states to fit in model
params.nPredictedStates = 3;
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
% Noise level
params.noise_level=3;

% Number of neurons to simulate
n_neurons=[50:50:1000];

% Error at each noise level
poiss_errs=[];
multinomial_errs=[];

% list to save the results
num_neurons_simulation_results=[];
num_neurons_simulation_results.trial_data={};
num_neurons_simulation_results.state_rates={};
num_neurons_simulation_results.state_seq_vecs={};
num_neurons_simulation_results.poissonModel={};
num_neurons_simulation_results.multinomialModel={};

for i=1:length(n_neurons)
    % Set number of neurons
    params.nNeurons=n_neurons(i);
    
    % Create simulated data
    [trial_data, state_rates, state_seq_vecs]=create_simulated_data(params);
    
    % Run simulation
    [poissonModel, multinomialModel]=run_simulation(params, trial_data);

    % Get states that correspond to simulated states
    correspondingStatesPoiss = getCorrespondingStates(state_rates, poissonModel.ESTEMIT');
    correspondingStatesMulti = getCorrespondingStates(state_rates, multinomialModel.ESTEMIT(:,2:end)');

    % Relabel model states (to match simulated states)
    poissonModel=relabel_states(poissonModel, correspondingStatesPoiss);
    multinomialModel=relabel_states(multinomialModel, correspondingStatesMulti);

    % Compute errors
    poiss_errs(i,:)=compute_errors(params, trial_data, poissonModel, state_seq_vecs);
    multinomial_errs(i,:)=compute_errors(params, trial_data, multinomialModel, state_seq_vecs);
    
    num_neurons_simulation_results.trial_data{i}=trial_data;
    num_neurons_simulation_results.state_rates{i}=state_rates;
    num_neurons_simulation_results.state_seq_vecs{i}=state_seq_vecs;
    num_neurons_simulation_results.poissonModel{i}=poissonModel;
    num_neurons_simulation_results.multinomialModel{i}=multinomialModel;
    
end

num_neurons_simulation_results.params=params;
num_neurons_simulation_results.n_neurons=n_neurons;
% save model results in a list
num_neurons_simulation_results.mean_poiss_err=mean(poiss_errs,2);
num_neurons_simulation_results.stderr_poiss_err=std(poiss_errs,[],2)./sqrt(size(poiss_errs,2));
num_neurons_simulation_results.mean_multinomial_err=mean(multinomial_errs,2);
num_neurons_simulation_results.stderr_multinomial_err=std(multinomial_errs,[],2)./sqrt(size(multinomial_errs,2));

save('num_neurons_simulation_results.mat', 'num_neurons_simulation_results','-v7.3');

% Plot
f=figure(1);
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(num_neurons_simulation_results.n_neurons,...
    num_neurons_simulation_results.mean_poiss_err,...
    num_neurons_simulation_results.stderr_poiss_err,'LineProps',{'Color',colors(1,:)});
shadedErrorBar(num_neurons_simulation_results.n_neurons,...
    num_neurons_simulation_results.mean_multinomial_err,...
    num_neurons_simulation_results.stderr_multinomial_err,...
    'LineProps',{'Color',colors(2,:)});
xlabel('# Neurons');
ylabel('Mean RMSE');
legend({'Poisson','Multinomial'});
    