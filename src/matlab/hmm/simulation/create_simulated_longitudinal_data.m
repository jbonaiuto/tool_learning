function [trial_data, state_rates, day_state_rates, state_seq_vecs]=create_simulated_longitudinal_data(params)

state_rates = ceil(rand(params.nNeurons,params.nActualStates)*(params.maxFR*.75));
day_state_rates={};
trial_data={};
stateSeqs={};
state_seq_vecs={};
state_seq_durs={};
for j=1:params.nDays
    day_state_rates{j}=state_rates+ceil(randn(params.nNeurons,params.nActualStates)*(params.maxFR*.5));
    for i=1:params.nTrials
        stateDurMeans = normrnd(1,.1,1,params.nActualStates);
        stateDurStds = .2*normrnd(1,.2,1,params.nActualStates);
        seq = ceil(rand(1,params.stateSeqLength)*params.nActualStates);    
        [trial_data{end+1},state_seq_durs{end+1},state_seq_vecs{end+1}] = genPoissSpikes(day_state_rates{j},...
            seq,params.dt,stateDurMeans,stateDurStds,params.noise_level);
        stateSeqs{end+1}=seq;
    end
end
