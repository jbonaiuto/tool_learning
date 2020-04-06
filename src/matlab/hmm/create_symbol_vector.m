function vec=create_symbol_vector(spikes)
% CREATE_SYMBOL_VECTORS Create symbol vector for a trial
%
% Syntax: vec=create_symbol_vectors(spikes)
%
% Inputs:
%    spikes - matrix of spikes for a trial (electrodes x bins)
%
% Outputs:
%    vec - vector with each element being the
%        index of the neuron that fired a spike in that time step. If
%        several fired at once, a random one is chosen
% 
% Example:
%     vec=create_symbol_vectors(vec)

% Create symbol sequence for this trial
vec = [];
% Go through each bin
for i = 1:size(spikes,2)
    % Find all electrodes that spiked in this bin
    x = find(spikes(:,i) == 1);
    % If any electrodes spiked
    if ~isempty(x)
        % Symbol is electrode ID if only one spiked
        if length(x) == 1
            vec(i) = x;
        % If more than one spiked, symbol is the ID of a random one
        else
            rand_idx=randi(numel(x));
            vec(i)= x(rand_idx);
        end
    % No electrodes spiked during this bin
    else
        vec(i) = 0;
    end
end

