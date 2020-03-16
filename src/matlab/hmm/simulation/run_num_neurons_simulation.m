function run_num_neurons_simulation()

params=[];
params.nTrials=100;
params.nActualStates = 3;
params.nPredictedStates = 3;
params.maxFR = 15;
params.stateSeqLength = 10;
params.dt = .01;
params.maxIterations = 500;
params.numRuns = 10;
params.noise_level=3;

n_neurons=[50:50:1000];

poiss_errs=[];
multinomial_errs=[];

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
end

figure();
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(n_neurons,mean(poiss_errs,2),std(poiss_errs,[],2)./sqrt(size(poiss_errs,2)),'LineProps',{'Color',colors(1,:)});
shadedErrorBar(n_neurons,mean(multinomial_errs,2),std(multinomial_errs,[],2)./sqrt(size(multinomial_errs,2)),'LineProps',{'Color',colors(2,:)});
xlabel('Number of neurons');
ylabel('Mean RMSE');
legend({'Poisson','Multinomial'});


    