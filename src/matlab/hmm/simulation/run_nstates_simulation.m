function run_nstates_simulation()

params=[];
params.nTrials=100;
params.maxFR = 30;
params.stateSeqLength = 10;
params.dt = .01;
params.maxIterations = 500;
params.numRuns = 10;
params.nNeurons=50;
params.noise_level=0;

n_possible_states=2:10;

poiss_LL=zeros(length(n_possible_states),length(n_possible_states));
multinomial_LL=zeros(length(n_possible_states),length(n_possible_states));
poiss_AIC=zeros(length(n_possible_states),length(n_possible_states));
multinomial_AIC=zeros(length(n_possible_states),length(n_possible_states));
poiss_BIC=zeros(length(n_possible_states),length(n_possible_states));
multinomial_BIC=zeros(length(n_possible_states),length(n_possible_states));

for i=1:length(n_possible_states)
    params.nActualStates=n_possible_states(i);
    disp(sprintf('%d actual states', params.nActualStates));
    
    [trial_data, state_rates, state_seq_vecs]=create_simulated_data(params);
    n_obs=0;
    for j=1:length(trial_data)
        n_obs=n_obs+size(trial_data{j},2);
    end

    for j=1:length(n_possible_states)
        params.nPredictedStates=n_possible_states(j);
        disp(sprintf('%d predicted states', params.nPredictedStates));
        [poissonModel, multinomialModel]=run_simulation(params, trial_data);
        
        poiss_LL(i,j)=poissonModel.LL;
        multinomial_LL(i,j)=multinomialModel.LL;
        
        n_emissions=size(poissonModel.ESTEMIT,2);
        num_poiss_params=params.nPredictedStates*(params.nPredictedStates-1)+params.nPredictedStates*(n_emissions-1)+(params.nPredictedStates-1);
        poiss_AIC(i,j)=-(2*poissonModel.LL)+(2*num_poiss_params);
        poiss_BIC(i,j)=-(2*poissonModel.LL)+num_poiss_params*log(n_obs);            
        
        n_emissions=size(multinomialModel.ESTEMIT,2);
        num_multinomial_params=params.nPredictedStates*(params.nPredictedStates-1)+params.nPredictedStates*(n_emissions-1)+(params.nPredictedStates-1);
        multinomial_AIC(i,j)=-(2*multinomialModel.LL)+(2*num_multinomial_params);
        multinomial_BIC(i,j)=-(2*multinomialModel.LL)+num_multinomial_params*log(n_obs);                    
    end
end
    
    
figure();
subplot(2,4,1);
imagesc(n_possible_states,n_possible_states,poiss_LL);
colorbar();
xlabel('Predicted States');
ylabel({'Poisson','Actual States'});
title('LL');
subplot(2,4,2);
imagesc(n_possible_states,n_possible_states,poiss_AIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
title('AIC');
subplot(2,4,3);
imagesc(n_possible_states,n_possible_states,poiss_BIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
title('BIC');
subplot(2,4,4);
imagesc(n_possible_states,n_possible_states,poiss_AIC+poiss_BIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
title('AIC');

subplot(2,4,5);
imagesc(n_possible_states,n_possible_states,multinomial_LL);
colorbar();
xlabel('Predicted States');
ylabel({'Multinomial','Actual States'});
subplot(2,4,6);
imagesc(n_possible_states,n_possible_states,multinomial_AIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
subplot(2,4,7);
imagesc(n_possible_states,n_possible_states,multinomial_BIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');
subplot(2,4,8);
imagesc(n_possible_states,n_possible_states,multinomial_AIC+multinomial_BIC);
colorbar();
xlabel('Predicted States');
ylabel('Actual States');

    