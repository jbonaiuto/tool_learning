function [trial_data, state_rates, state_seq_vecs]=create_simulated_data(params)
% CREATE_SIMULATED_DATA Create simulated data for HMM
%
% Syntax: [trial_data, state_rates, state_seq_vecs]=create_simulated_data(params)
%
% Inputs:
%    params - structure of simulaton parameters
%
% Outputs:
%    trial_data - cell array with a matrix of spikes for each trial
%    state_rates - for each state, firing rate of each neuron
%    state_seq_vecs - cell array - the state index for each time point in
%        trial, for each trial
% 
% Example:
%     [trial_data, state_rates, state_seq_vecs]=create_simulated_data(params)

% Initialize firing rate for each neuron in each state
state_rates = ceil(rand(params.nNeurons,params.nActualStates)*params.maxFR);

% Initialize trial spikes and state sequence vectors
trial_data={};
state_seq_vecs={};

% For each trial
for i=1:params.nTrials
    
    % Generate random state mean and std dev durations
    state_dur_means = normrnd(1,.1,1,params.nActualStates);
    state_dur_stds = .2*normrnd(1,.2,1,params.nActualStates);
    
    % Generate random state sequences
    state_seq = ceil(rand(1,params.stateSeqLength)*params.nActualStates);    
    
    % Generate trial spikes and state sequence vector
    [trial_data{i},state_seq_vecs{i}] = gen_poiss_spikes(state_rates,...
        state_seq, params.dt, state_dur_means, state_dur_stds,...
        params.noise_level);
end
