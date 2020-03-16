function SEQ=create_symbol_vectors(trial_data)
% CREATE_SYMBOL_VECTORS Create symbol vectors for each trial
%
% Syntax: SEQ=create_symbol_vectors(trial_data)
%
% Inputs:
%    trial_data - cell array with a matrix of spikes for each trial
%
% Outputs:
%    SEQ - cell array of vector for each trial, with each element being the
%        index of the neuron that fired a spike in that time step. If
%        several fired at once, a random one is chosen
% 
% Example:
%     SEQ=create_symbol_vectors(trial_data)

SEQ={};
for j=1:length(trial_data)
    spikes=trial_data{j};
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
    SEQ{j}=vec;
end
