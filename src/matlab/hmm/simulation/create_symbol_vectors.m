function SEQ=create_symbol_vectors(trial_data)

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
