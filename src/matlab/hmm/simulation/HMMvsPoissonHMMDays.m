% HMM vs. poissHMM
clear all;
params=[];
params.nDays=3;
params.nTrials=10;
params.nNeurons = 32;
params.nActualStates = 3;
params.nPredictedStates = 3;
params.maxFR = 30;
params.stateSeqLength = 10;
params.dt = .01;
params.maxIterations = 500;
params.numRuns = 10;
params.noise_level=0;

[trial_data, state_rates, day_state_rates, state_seq_vecs]=create_simulated_longitudinal_data(params);
day_data={};
for i=1:params.nDays
    day_data{i}=trial_data((i-1)*params.nTrials+1:i*params.nTrials);
end

[poissonModel, multinomialModel]=run_simulation(params, trial_data);
longitudinalPoissonModel=run_longitudinal_simulation(params, day_data);

correspondingStatesPoiss = getCorrespondingStates(state_rates, poissonModel.ESTEMIT');
correspondingStatesMulti = getCorrespondingStates(state_rates, multinomialModel.ESTEMIT(:,2:end)');
correspondingStatesLongPoiss = getCorrespondingLongitudinalStates(day_state_rates, longitudinalPoissonModel.GLOBAL_ESTEMIT, longitudinalPoissonModel.DAY_ESTEMIT);

poissonModel=relabel_states(poissonModel, correspondingStatesPoiss);
multinomialModel=relabel_states(multinomialModel, correspondingStatesMulti);
longitudinalPoissonModel=relabel_longitudinal_states(longitudinalPoissonModel, correspondingStatesLongPoiss);

poiss_err=compute_errors(params, trial_data, poissonModel, state_seq_vecs);
multinomial_err=compute_errors(params, trial_data, multinomialModel, state_seq_vecs);
long_poiss_err=compute_errors(params, trial_data, longitudinalPoissonModel, state_seq_vecs);

disp(sprintf('Multilevel Poisson HMM mean error=%.4f', mean(long_poiss_err)));
disp(sprintf('Poisson HMM mean error=%.4f', mean(poiss_err)));
disp(sprintf('Multinomial HMM mean error=%.4f', mean(multinomial_err)));

for i=1:params.nTrials*params.nDays;
    spike_data=trial_data{i};
    trial_duration=size(spike_data,2)*params.dt;    
    tvec=linspace(params.dt,trial_duration,size(spike_data,2));
    
    trial_state_seq=state_seq_vecs{i};
    
    figure;
    subplot(5,1,1);
    [y,x]=find(spike_data>0);
    plot(x.*params.dt,y,'.');
    hold all;
    trial_state_seq_diffs=diff(trial_state_seq);
    transitions=find(abs(trial_state_seq_diffs)>0);
    for j=1:length(transitions)
        plot([transitions(j) transitions(j)].*params.dt,ylim(),'r');
    end
    xlim([0 trial_duration]);
    ylim([0 params.nNeurons]);
    
    subplot(5,1,2);
    hold all
    labels={};
    for j=1:params.nPredictedStates
        plot(tvec,longitudinalPoissonModel.PSTATES{i}(j,:)');
        labels{j}=num2str(j);
    end
    xlim([0 trial_duration]);
    ylim([0 1.2]);
    legend(labels)
    ylabel('Probability');
    title('Multilevel Poisson HMM');

    subplot(5,1,3);
    hold all
    labels={};
    for j=1:params.nPredictedStates
        plot(tvec,poissonModel.PSTATES{i}(j,:)');
        labels{j}=num2str(j);
    end
    xlim([0 trial_duration]);
    ylim([0 1.2]);
    legend(labels)
    ylabel('Probability');
    title('Poisson HMM');
    
    subplot(5,1,4);
    hold all
    labels={};
    for j=1:params.nPredictedStates
        plot(tvec,multinomialModel.PSTATES{i}(j,:)');
        labels{j}=num2str(j);
    end
    xlim([0 trial_duration]);
    ylim([0 1.2]);
    legend(labels)
    ylabel('Probability');
    title('Normal HMM');
    
    subplot(5,1,5)
    hold all
    plot(tvec,state_seq_vecs{i});
    plot(tvec,longitudinalPoissonModel.STATES{i}-.2); 
    plot(tvec,poissonModel.STATES{i}-.1); 
    plot(tvec,multinomialModel.STATES{i}+.1); 
    legend({'Actual','Predicted-Multilevel Poisson','Predicted-Poisson','Predicted-Normal'})
    ylabel('State')
    xlim([0 trial_duration]);
end