function HMM(exp_info, subject, dates, conditions, model_name)

%% Create results structure
hmm_results=[];
hmm_results.subject=subject;
% Dates data were recorded on
hmm_results.dates=dates;
% Trials used in these models
hmm_results.trials=[];
% Cell array - each element will contain a vector - sequence for each trial
hmm_results.SEQ={};
% Number of different states to try
hmm_results.n_state_possibilities=[2:10];
% Number of training runs per state
hmm_results.n_iter=10;
% List of model structs
hmm_results.models=[];

%% Create output directory if it doesn't exist
out_dir=fullfile(exp_info.base_output_dir, 'HMM', subject, model_name);
if exist(out_dir,'dir')~=7
    mkdir(out_dir);
end

%% Load and concatenate spike data
addpath('../spike_data_processing');
date_data={};
for i=1:length(dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dates{i},'multiunit','binned',...
        sprintf('fr_b_F1_%s_whole_trial.mat',dates{i})));
    date_data{i}=data;
    clear('datafr');
end
data=concatenate_data(date_data, 'spike_times', false);
clear('date_data');
   
%% Figure out which trials to use and get trial data
hmm_results.trials=zeros(1,length(data.metadata.condition));
for i=1:length(conditions)
    hmm_results.trials = hmm_results.trials | (strcmp(data.metadata.condition,conditions{i}));
end
hmm_results.trials=find(hmm_results.trials);
cond_data=squeeze(data.binned_spikes(1,:,hmm_results.trials,:));

%% Create symbol sequence vectors for each trial
for g = 1:length(hmm_results.trials)

    % Get binned spikes for this trial from time 0 to time of reward
    trial_idx = hmm_results.trials(g);
    bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(trial_idx))));
    trial_data=squeeze(cond_data(:,g,bin_idx));
    
    % Debugging figure
%     figure();
%     [i,j]=find(trial_data>0);
%     plot(j,i,'.');
%     hold all
%     for i=1:length(data.metadata.event_types)
%         evt_type=data.metadata.event_types{i};
%         evt_times=data.metadata.(evt_type);
%         plot([evt_times(trial_idx) evt_times(trial_idx)],ylim(),'- ');
%     end
%     title(num2str(motor_trials_idx));
%     xlim([0 data.metadata.reward(motor_trials_idx)+100]);
%     ylim([0 33]);

    % Create symbol sequence for this trial
    vec = [];
    % Go through each bin
    for i = 1:length(bin_idx)
        % Find all electrodes that spiked in this bin
        x = find(trial_data(:,i) == 1);
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
    
    % Add vec to SEQ
    hmm_results.SEQ{end+1}=vec;
end
        
%% Train model using each possible number of states
for n=1:length(hmm_results.n_state_possibilities)
    n_states=hmm_results.n_state_possibilities(n);
    disp(sprintf('Trying %d states',n_states));
    
    % Run n times with this number of states
    for t=1:hmm_results.n_iter
        
        % Initialize transition prob guess
        TRGUESS=[];
        for i=1:n_states
            for j=1:n_states
                if i==j %the diagonal
                    % random between .8 and 1, above 0.8 because it is the
                    % transition probability to stay in the same state.                  
                    TRGUESS(i,j)= .8+rand()*.2;
                else
                    % random between 0 and .5
                    TRGUESS(i,j)=rand()*.01;
                end
            end
        end
        % Normalize so probabilities add to 1
        TRGUESS=TRGUESS./repmat(sum(TRGUESS,2),1,n_states);
        
        % Initialize emission prob guess
        EMITGUESS=[];
        for i=1:n_states
            state_emission=rand(1,33);
            % Normalize so probabilities add to 1
            state_emission=state_emission./sum(state_emission);
            EMITGUESS(i,:)=state_emission;
        end
        
        % Train model
        [ESTTR,ESTEMIT] = hmmtrain(hmm_results.SEQ,TRGUESS,EMITGUESS,'Symbols',[0:32]);
        
        % Compute log likelihood for each trial
        all_log_likelihood=[];
        for k = 1:length(hmm_results.SEQ);
            [PSTATES,logpseq] = hmmdecode(hmm_results.SEQ{k},ESTTR,ESTEMIT,'Symbols',[0:32]);
            % add logpseq to all_log_likelihood
            all_log_likelihood(end+1) = logpseq;
        end
        % compute sum log likelihood
        sum_log_likelihood = sum(all_log_likelihood);
        
        % Save model results in list
        hmm_results.models(n,t).n_states=n_states;
        hmm_results.models(n,t).TRGUESS=TRGUESS;
        hmm_results.models(n,t).EMITGUESS=EMITGUESS;
        hmm_results.models(n,t).ESTTR=ESTTR;
        hmm_results.models(n,t).ESTEMIT=ESTEMIT;
        hmm_results.models(n,t).sum_log_likelihood=sum_log_likelihood;                        
    end
    
    % Save intermediate results
    save(fullfile(out_dir,'hmm_results.mat'),'hmm_results');
end

hmm_results=select_best_model(exp_info, hmm_results, model_name);

save(fullfile(out_dir,'hmm_results.mat'),'hmm_results');
save(fullfile(out_dir,'data.mat'),'data');

% mult_state_trials=[];
% for i=1:length(hmm_results.SEQ)
%     STATES = hmmviterbi(hmm_results.SEQ{i},hmm_results.ESTTR,hmm_results.ESTEMIT,'Symbols',[0:32]);
%     unique_states=unique(STATES);
%     if length(unique_states)>1
%         disp(sprintf('Trial %d', i));
%         mult_state_trials(end+1)=i;
%     end
% end

