function run_num_neurons_simulation()

params=[];
params.nTrials=5;
params.nActualStates = 3;
params.nPredictedStates = 3;
params.maxFR = 15;
params.stateSeqLength = 10;
params.dt = .01%.001;
params.maxIterations = 500;
params.numRuns = 10;
params.noise_level=3;

n_neurons=[50:50:100];

poiss_errs=[];
multinomial_errs=[];

num_neurons_simulation_results.mean_poiss_err={};
num_neurons_simulation_results.stderr_poiss_err={};
num_neurons_simulation_results.mean_multinomial_err={};
num_neurons_simulation_results.stderr_multinomial_err={};

num_neurons_simulation_results.trial_data={};
num_neurons_simulation_results.state_rates={};
num_neurons_simulation_results.state_seq_vecs={};
num_neurons_simulation_results.poissonModel={};
num_neurons_simulation_results.multinomialModel={};

for i=1:length(n_neurons)
    params.nNeurons=n_neurons(i);
    [trial_data, state_rates, state_seq_vecs]=create_simulated_data(params);
    [poissonModel, multinomialModel]=run_simulation(params, trial_data);

    correspondingStatesPoiss = getCorrespondingStates(state_rates, poissonModel.ESTEMIT');
    correspondingStatesMulti = getCorrespondingStates(state_rates, multinomialModel.ESTEMIT(:,2:end)');

    poissonModel=relabel_states(poissonModel, correspondingStatesPoiss);
    multinomialModel=relabel_states(multinomialModel, correspondingStatesMulti);

    poiss_errs(i,:)=compute_errors(params, trial_data, poissonModel, state_seq_vecs);
    multinomial_errs(i,:)=compute_errors(params, trial_data, multinomialModel, state_seq_vecs);
    
    mean_poiss_err=mean(poiss_errs,2);
    stderr_poiss_err=std(poiss_errs,[],2)./sqrt(size(poiss_errs,2));
    mean_multinomial_err=mean(multinomial_errs,2);
    stderr_multinomial_err=std(multinomial_errs,[],2)./sqrt(size(multinomial_errs,2));
    
    num_neurons_simulation_results.mean_poiss_err{i}=mean_poiss_err;
    num_neurons_simulation_results.stderr_poiss_err{i}=stderr_poiss_err;
    num_neurons_simulation_results.mean_multinomial_err{i}=mean_multinomial_err;
    num_neurons_simulation_results.stderr_multinomial_err{i}=stderr_multinomial_err;
    num_neurons_simulation_results.trial_data{i}=trial_data;
    num_neurons_simulation_results.state_rates{i}=state_rates;
    num_neurons_simulation_results.state_seq_vecs{i}=state_seq_vecs;
    num_neurons_simulation_results.poissonModel{i}=poissonModel;
    num_neurons_simulation_results.multinomialModel{i}=multinomialModel;
    
end

%f=figure();% colors=get(gca,'ColorOrder');
% hold all;
% shadedErrorBar(n_neurons,mean_poiss_err,stderr_poiss_err,'LineProps',{'Color',colors(1,:)});
% shadedErrorBar(n_neurons,mean_multinomial_err,stderr_multinomial_err,...
%     'LineProps',{'Color',colors(2,:)});
% xlabel('Number of neurons');
% ylabel('Mean RMSE');
% legend({'Poisson','Multinomial'});
% 
% saveas(f, fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation\figures', 'num_neurons_simulation_50neurons_50trials_0.1dt_1.png'));
% saveas(f, fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation\figures', 'num_neurons_simulation_50neurons_50trials_0.1dt_1_1.eps'));


num_neurons_simulation_results.params=params;
save(fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation','num_neurons_simulation_results_100neurons_5trials_0.1dt_1_1.mat'), 'num_neurons_simulation_results','-v7.3');

    