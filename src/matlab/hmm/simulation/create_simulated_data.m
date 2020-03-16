function [trial_data, state_rates, state_seq_vecs]=create_simulated_data(params)

state_rates = ceil(rand(params.nNeurons,params.nActualStates)*params.maxFR);
trial_data={};
stateSeqs={};
state_seq_vecs={};
state_seq_durs={};
for i=1:params.nTrials
    stateDurMeans = normrnd(1,.1,1,params.nActualStates);
    stateDurStds = .2*normrnd(1,.2,1,params.nActualStates);
    stateSeqs{i} = ceil(rand(1,params.stateSeqLength)*params.nActualStates);    
    [trial_data{i},state_seq_durs{i},state_seq_vecs{i}] = genPoissSpikes(state_rates,...
        stateSeqs{i},params.dt,stateDurMeans,stateDurStds,params.noise_level);
end
