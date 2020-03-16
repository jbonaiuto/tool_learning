% RUN_NOISE_SIMULATION Runs simulation comparing univariate multinomial HMM
% and multivariate Poisson HMM as noise is added to the state firing rates

clear all

%% Set up parameters of simuation
params=[];
% Number of trials to simulate
params.nTrials=100;
% Number of states to simulate
params.nActualStates = 3;
% Number of states to fit in model
params.nPredictedStates = 3;
% Maximum firing rate
params.maxFR = 30;
% Length of state sequence to simulate
params.stateSeqLength = 10;
% Time step
params.dt = .01;
% Maximum number of iterations in Baum-Welch
params.maxIterations = 500;
% Number of times to run Baum-Welch (to find model with max LL)
params.numRuns = 10;
% Number of neurons to simulate
params.nNeurons=50;

% Noise levels to simulate
noise_levels=[1:15];

% Error at each noise level
poiss_errs=[];
multinomial_errs=[];

for i=1:length(noise_levels)
    % Set noise level
    params.noise_level=noise_levels(i);
    
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
end

% Get mean and std error of errors
mean_poiss_err=mean(poiss_errs,2);
stderr_poiss_err=std(poiss_errs,[],2)./sqrt(size(poiss_errs,2));
mean_multinomial_err=mean(multinomial_errs,2);
stderr_multinomial_err=std(multinomial_errs,[],2)./sqrt(size(multinomial_errs,2));

% Plot
figure();
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(noise_levels,mean_poiss_err,stderr_poiss_err,...
    'LineProps',{'Color',colors(1,:)});
shadedErrorBar(noise_levels,mean_multinomial_err,stderr_multinomial_err,...
    'LineProps',{'Color',colors(2,:)});
xlabel('Noise level');
ylabel('Mean RMSE');
legend({'Poisson','Multinomial'});


    