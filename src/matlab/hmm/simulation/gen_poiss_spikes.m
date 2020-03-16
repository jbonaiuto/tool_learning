function [spikes, state_seq_vec] = gen_poiss_spikes(rates, state_seq, dt,...
    state_dur_means, state_dur_stds, noise_level)
% GEN_POISS_SPIKES Create a matrix of spike data for one trial
%
% Syntax: [spikes, state_seq_vec] = gen_poiss_spikes(rates, state_seq, dt,...
%    state_dur_means, state_dur_stds, noise_level
%
% Inputs:
%    rates - firing rate of each neuron in each state
%    state_seq - sequence of states for the trial
%    dt - time step
%    state_dur_means - mean duration of each state
%    state_dur_stds - std dev of duration of each state
%    noise_level - amount of noise to add
%
% Outputs:
%    spikes - matrix of spikes for this trial
%    state_seq_vec - the state index for each time point in trial
% 
% Example:
%     [spikes, state_seq_vec] = gen_poiss_spikes(rates, state_seq, .01,...
%         state_dur_means, state_dur_stds, 0);

% Generate sequences of state durations
state_seq_durs=zeros(1,length(state_seq));
% Generate sequence of state for each time step
state_seq_vec = [];
for i=1:length(state_seq)
    state_idx=state_seq(i);
    mean_duration=state_dur_means(state_idx);
    std_duration=state_dur_stds(state_idx);
    % Random duration with given mean and std, at least 0.05
    state_seq_durs(i) = max(.05, normrnd(mean_duration, std_duration));
    % Number of time points in this state
    n_time_pts=ceil(state_seq_durs(i)/dt);
    % Add state index n times to state sequence vector
    state_seq_vec(i) = [state_seq_vec repelem(state_idx,n_time_pts)];
end

% Spike matrix
spikes = zeros(size(rates,1),ceil(sum(state_seq_durs)/dt));
% For each neuron
for i=1:size(spikes,1)
    startInd=1;
    % Go through sequence of states
    for j=1:length(state_seq)
        % Current state duration
        curDur = state_seq_durs(j);
        % Get rate of this neuron in this state and add noise
        curRate = max([0 rates(i,state_seq(j))+round(noise_level*randn())]);
        % Generate spikes
        v = poissrnd(curRate*dt,1,ceil(curDur/dt));
        endInd = startInd + length(v) - 1;
        spikes(i,startInd:endInd) = v;
        startInd=startInd+length(v);
    end
end


