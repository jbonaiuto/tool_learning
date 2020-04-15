% HMM vs. poissHMM
clear all;
params=[];
params.nTrials=100;
params.nNeurons = 32;
params.nActualStates = 3;
params.nPredictedStates = 3;
params.maxFR = 15;
params.stateSeqLength = 10;
params.dt = .01;
params.maxIterations = 500;
params.numRuns=1;
params.noise_level=0;

[trial_data, state_rates, state_seq_vecs]=create_simulated_data(params);
[poissonModel, multinomialModel]=run_simulation(params, trial_data);
    
correspondingStatesPoiss = getCorrespondingStates(state_rates, poissonModel.ESTEMIT');
correspondingStatesMulti = getCorrespondingStates(state_rates, multinomialModel.ESTEMIT(:,2:end)');

poissonModel=relabel_states(poissonModel, correspondingStatesPoiss);
multinomialModel=relabel_states(multinomialModel, correspondingStatesMulti);

poiss_err=compute_errors(params, trial_data, poissonModel, state_seq_vecs);
multinomial_err=compute_errors(params, trial_data, multinomialModel, state_seq_vecs);

disp(sprintf('Poisson HMM mean error=%.4f', mean(poiss_err)));
disp(sprintf('Multinomial HMM mean error=%.4f', mean(multinomial_err)));

err_diff=multinomial_err-poiss_err;
[min_err,min_idx]=min(poiss_err);
[max_err,max_idx]=max(multinomial_err);

idxs=[min_idx max_idx];

for idx=1:length(idxs);
    i=idxs(idx);
    spike_data=trial_data{i};
    trial_duration=size(spike_data,2)*params.dt;
    tvec=linspace(params.dt,trial_duration,size(spike_data,2));
    trial_state_seq=state_seq_vecs{i};
    
    figure;
    subplot(4,1,1);
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
    
    subplot(4,1,2);
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
    
    subplot(4,1,3);
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
    title('Multinomial HMM');
    
    subplot(4,1,4)
    hold all
    plot(tvec,state_seq_vecs{i});
    plot(tvec,poissonModel.STATES{i}); 
    plot(tvec,multinomialModel.STATES{i}); 
    legend({'Actual','Predicted-Poisson','Prediced-Multinomial'})
    ylabel('State')
    xlim([0 trial_duration]);
end