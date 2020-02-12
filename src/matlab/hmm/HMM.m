function HMM(exp_info, subject, dates, conditions)

addpath('../spike_data_processing');
date_data={};
for i=1:length(dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, dates{i},'multiunit','binned',sprintf('fr_b_F1_%s_whole_trial.mat',dates{i})));
    date_data{i}=data;
    clear('datafr');
end
data=concatenate_data(date_data, 'spike_times', false);
clear('date_data');
   
cond_trials=zeros(1,length(data.metadata.condition));
for i=1:length(conditions)
    cond_trials = cond_trials | (strcmp(data.metadata.condition,conditions{i}));
end
cond_trials=find(cond_trials);
cond_data=squeeze(data.binned_spikes(1,:,cond_trials,:));

% Cell array - each element will contain a vector - sequence for each trial
SEQ= {};

% Loop over each motor trial
for g = 1:length(cond_trials)
    motor_trials_idx = cond_trials(g);
    bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(motor_trials_idx)+100)));
    motor_trial_data=squeeze(cond_data(:,g,bin_idx));
    
    % Debugging figure
%     figure();
%     [i,j]=find(motor_trial_data>0);
%     plot(j,i,'.');
%     hold all
%     for i=1:length(data.metadata.event_types)
%         evt_type=data.metadata.event_types{i};
%         evt_times=data.metadata.(evt_type);
%         plot([evt_times(motor_trials_idx) evt_times(motor_trials_idx)],ylim(),'- ');
%     end

    % Create symbol sequence for this trial
    vec = [];
    % Go through each bin
    for i = 1:length(bin_idx)
        % Find all electrodes that spiked in this bin
        x = find(motor_trial_data(:,i) == 1);
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
    SEQ{end+1}=vec;
end

% Number of different states to try
n_state_possibilities=[2:10];
%n_state_possibilities=[5];
% Number of training runs per state
n_runs=10;

% List of model structs
models=[];
        
% Try each possible number of states
for n=1:length(n_state_possibilities)
    n_states=n_state_possibilities(n);
    disp(sprintf('Trying %d states',n_states));
    
    % Run n times with this number of states
    for t=1:n_runs
        
        % Initialize transition prob guess
        TRGUESS=[];
        for i=1:n_states
            for j=1:n_states
                if i==j %the diagonal
                    % random between .5 and 1, above 0.5 because it is the
                    % transition probability to stay in the same state.
                  
                    TRGUESS(i,j)= .5+rand()*.5;
                else
                    % random between 0 and .5
                    TRGUESS(i,j)=rand()*.5;
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
        [ESTTR,ESTEMIT] = hmmtrain(SEQ,TRGUESS,EMITGUESS,'Symbols',[0:32]);
        
        % Compute log likelihood for each trial
        all_log_likelihood=[];
        for k = 1:length(SEQ);
            [PSTATES,logpseq] = hmmdecode(SEQ{k},ESTTR,ESTEMIT,'Symbols',[0:32]);
            % add logpseq to all_log_likelihood
            all_log_likelihood(end+1) = logpseq;
        end
        % compute sum log likelihood
        sum_log_likelihood = sum(all_log_likelihood);
        
        % Save model results in list
        models(n,t).n_states=n_states;
        models(n,t).TRGUESS=TRGUESS;
        models(n,t).EMITGUESS=EMITGUESS;
        models(n,t).ESTTR=ESTTR;
        models(n,t).ESTEMIT=ESTEMIT;
        models(n,t).sum_log_likelihood=sum_log_likelihood;                
    end
end

% AIC for each number of possible states
AIC_storing = zeros(length(n_state_possibilities),1);
% Index of the run with the maximm log likelihood for each possible number
% of states
maxLL_idx_storing = zeros(length(n_state_possibilities),1);
% Max log likelihood over runs for each possible number of states
maxLL_storing = zeros(length(n_state_possibilities),1);

% Go through each possible number of states
for n=1:length(n_state_possibilities)
    n_states=n_state_possibilities(n);
    
    % Find run with the max log likelihood
    [LL,max_idx]=max([models(n,:).sum_log_likelihood]);
    
    % Compute AIC for this run
    AIC=2*((33-1)*n_states+(n_states-1)*n_states)-(2*LL);
    
    % Store results
    maxLL_storing(n)=LL;
    maxLL_idx_storing(n)=max_idx;
    AIC_storing(n) = AIC;
end

% Plot max log likelihood and AIC
f=figure();
subplot(2,1,1);
plot(n_state_possibilities,maxLL_storing);
xlabel('nstates');
ylabel('LL');
subplot(2,1,2);
plot(n_state_possibilities,AIC_storing);
xlabel('nstates');
ylabel('AIC');
% saveas(f,fullfile('C:\Users\kirchher\project\tool_learning\output\figures\HMM\betta\stage1_F1_motor_grasp_AIC_maxLL\',['stage1_F1_motor_grasp_right_AIC_maxLL_5states(2)_13.03.19' '.png']));
% saveas(f,fullfile('C:\Users\kirchher\project\tool_learning\output\figures\HMM\betta\stage1_F1_motor_grasp_AIC_maxLL\',['stage1_F1_motor_grasp_right_AIC_maxLL_5states(2)_13.03.19' '.eps']), 'epsc');

% Find number of states that minimized AIC
[AIC_min,min_AIC_idx]=min(AIC_storing);

% Save results
hmm_results=[];
hmm_results.dates=dates;
hmm_results.trials=cond_trials;
hmm_results.SEQ=SEQ;
hmm_results.n_state_possibilities=n_state_possibilities;
hmm_results.n_iter=n_runs;
hmm_results.n_states=n_state_possibilities(min_AIC_idx);
hmm_results.AIC_storing=AIC_storing;
hmm_results.maxLL_idx_storing=maxLL_idx_storing;
hmm_results.maxLL_storing=maxLL_storing;
hmm_results.models=models;
hmm_results.best_model_idx=[min_AIC_idx maxLL_idx_storing(min_AIC_idx)];


%save('C:/Users/kirchher/project/tool_learning/data/HMM/betta/betta_stage1_F1_go_hmm.mat','hmm_results');
save('C:\Users\kirchher\project\tool_learning\data\HMM\betta\motor_grasp_right\betta_stage1_F1_hmm_test_5states(2)_13.03.19.mat','hmm_results');

% mult_state_trials=[];
% for i=1:length(SEQ)
%     STATES = hmmviterbi(SEQ{i},hmm_results.ESTTR,hmm_results.ESTEMIT,'Symbols',[0:32]);
%     unique_states=unique(STATES);
%     if length(unique_states)>1
%         disp(sprintf('Trial %d', i));
%         mult_state_trials(end+1)=i;
%     end
% end

