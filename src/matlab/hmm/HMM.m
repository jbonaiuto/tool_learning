function hmm_results=HMM(exp_info, subject, dates, array, conditions, model_name, varargin)

% Parse optional arguments
defaults=struct('type','multilevel_multivariate_poisson','resume',false);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

%% Create output directory if it doesn't exist
out_dir=fullfile(exp_info.base_output_dir, 'HMM', subject, model_name);
if exist(out_dir,'dir')~=7
    mkdir(out_dir);
end

if params.resume
    load(fullfile(out_dir,'hmm_results.mat'));
    iter_start_idx=hmm_results.n_iter+1;
    hmm_results.n_iter=hmm_results.n_iter+10;
else
    %% Create results structure
    hmm_results=[];
    hmm_results.subject=subject;
    % Dates data were recorded on
    hmm_results.dates=dates;
    % Array data used 
    hmm_results.array=array;
    % Trials used in these models
    hmm_results.trials=[];
    % Index of date in list of dates that each trial comes from
    hmm_results.trial_date=[];
    if strcmp(params.type,'univariate_multinomial')
        % Cell array - each element will contain a vector - sequence for each trial
        hmm_results.SEQ={};
    elseif strcmp(params.type,'multivariate_poisson')
        hmm_results.trial_spikes={};
    elseif strcmp(params.type,'multilevel_multivariate_poisson')
        hmm_results.day_spikes={};
    end
    % Number of different states to try
    hmm_results.n_state_possibilities=[2:10];
    % Number of training runs per state
    hmm_results.n_iter=10;
    % List of model structs
    hmm_results.models=[];
    
    iter_start_idx=1;
end

%% Load and concatenate spike data
addpath('../spike_data_processing');
date_data={};
for i=1:length(dates)
    load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dates{i},'multiunit','binned',...
        sprintf('fr_b_%s_%s_whole_trial.mat',array,dates{i})));
    date_data{i}=data;
    clear('datafr');
end
data=concatenate_data(date_data, 'spike_times', false);
clear('date_data');

% Filter data - RTs too fast or slow
data=filter_data(exp_info,data,'plot_corrs',true);
% Compute dt
dt=(data.bins(2)-data.bins(1))/1000;
   
%% Figure out which trials to use and get trial data
hmm_results.trials=zeros(1,length(data.metadata.condition));
for i=1:length(conditions)
    hmm_results.trials = hmm_results.trials | (strcmp(data.metadata.condition,conditions{i}));
end
hmm_results.trials=find(hmm_results.trials);
hmm_results.trial_date=data.trial_date(hmm_results.trials);
cond_data=squeeze(data.binned_spikes(1,:,hmm_results.trials,:));

trial_spikes={};

%% Get trial spikes
for g = 1:length(hmm_results.trials)
    % Get binned spikes for this trial from time 0 to time of reward
    trial_idx = hmm_results.trials(g);
    bin_idx=find((data.bins>=0) & (data.bins<(data.metadata.reward(trial_idx))));
    trial_data=squeeze(cond_data(:,g,bin_idx));
    trial_spikes{end+1}=trial_data;

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
end
    
if strcmp(params.type,'univariate_multinomial')
    hmm_results.SEQ={};
    for j=1:length(trial_spikes)
        hmm_results.SEQ{j}=create_symbol_vectors(trial_spikes{j});
    end    
elseif strcmp(params.type,'multivariate_poisson')
    hmm_results.trial_spikes=trial_spikes;
elseif strcmp(params.type,'multilevel_multivariate_poisson')
    for i=1:length(dates)
        hmm_results.day_spikes{i}=trial_spikes(hmm_results.trial_date==i);
    end
end

%% Train model using each possible number of states
for n=1:length(hmm_results.n_state_possibilities)
    n_states=hmm_results.n_state_possibilities(n);
    disp(sprintf('Trying %d states',n_states));
    
    iter_idx=iter_start_idx;
    
    % Run n times with this number of states
    for t=1:10
        
        converged=false;
        
        while ~converged
            % Initialize transition prob guess
            TRGUESS=[];
            for i=1:n_states
                for j=1:n_states
                    if i==j %the diagonal
                        % random around .99 because it is the
                        % transition probability to stay in the same state.                  
                        TRGUESS(i,j)= .99+.1*randn();
                    else
                        % random between 0 and .01
                        TRGUESS(i,j)=rand()*.01;
                    end
                end
            end
            % Normalize so probabilities add to 1
            TRGUESS=TRGUESS./repmat(sum(TRGUESS,2),1,n_states);

            % Initialize emission prob guess
            GLOBAL_EMITGUESS=500.*rand(n_states,32);
            DAY_EMITGUESS=(1000*rand(length(dates),n_states,32))-500.0;

            % Train model
            if strcmp(params.type,'univariate_multinomial')
                [ESTTR,ESTEMIT] = hmmtrain(hmm_results.SEQ, TRGUESS,...
                    GLOBAL_EMITGUESS, 'Symbols', [0:32]);
                converged=true;
            elseif strcmp(params.type,'multivariate_poisson')
                [ESTTR,ESTEMIT,converged] = hmmtrainPoiss(hmm_results.trial_spikes,...
                    TRGUESS, GLOBAL_EMITGUESS, dt, 'verbose', true);
            elseif strcmp(params.type,'multilevel_multivariate_poisson')
                [ESTTR,GLOBAL_ESTEMIT,DAY_ESTEMIT,converged] = hmmtrainMultilevelPoiss(hmm_results.day_spikes,...
                    TRGUESS, GLOBAL_EMITGUESS, DAY_EMITGUESS, dt, 'verbose', true,...
                    'annealing',false);
            end
        end
        
        % Compute log likelihood for each trial
        all_log_likelihood=[];
        if strcmp(params.type,'univariate_multinomial')
            for k = 1:length(hmm_results.trial_spikes);
               [PSTATES,logpseq] = hmmdecode(hmm_results.SEQ{k}, ESTTR,...
                   ESTEMIT, 'Symbols', [0:32]);
               % add logpseq to all_log_likelihood
               all_log_likelihood(end+1) = logpseq;
            end
        elseif strcmp(params.type,'multivariate_poisson')
            for k = 1:length(hmm_results.trial_spikes);
                [PSTATES,logpseq] = hmmdecodePoiss(hmm_results.trial_spikes{k},...
                    ESTTR, ESTEMIT, dt);
                % add logpseq to all_log_likelihood
                all_log_likelihood(end+1) = logpseq;
            end
        elseif strcmp(params.type,'multilevel_multivariate_poisson')
            for i=1:length(dates)
                trial_spikes=hmm_results.day_spikes{i};
                effectiveE=GLOBAL_ESTEMIT+squeeze(DAY_ESTEMIT(i,:,:));
                for k = 1:length(trial_spikes)
                    [PSTATES,logpseq] = hmmdecodePoiss(trial_spikes{k},...
                        ESTTR, effectiveE, dt);
                    all_log_likelihood(end+1) = logpseq;
                end
            end
        end
        % compute sum log likelihood
        sum_log_likelihood = sum(all_log_likelihood);
        
        % Save model results in list
        hmm_results.models(n,iter_idx).type=params.type;
        hmm_results.models(n,iter_idx).n_states=n_states;
        hmm_results.models(n,iter_idx).TRGUESS=TRGUESS;
        if strcmp(params.type,'multilevel_multivariate_poisson')
            hmm_results.models(n,iter_idx).GLOBAL_EMITGUESS=GLOBAL_EMITGUESS;
            hmm_results.models(n,iter_idx).DAY_EMITGUESS=DAY_EMITGUESS;
            hmm_results.models(n,iter_idx).GLOBAL_ESTEMIT=GLOBAL_ESTEMIT;
            hmm_results.models(n,iter_idx).DAY_ESTEMIT=DAY_ESTEMIT;
        else
            hmm_results.models(n,iter_idx).EMITGUESS=EMITGUESS;
            hmm_results.models(n,iter_idx).ESTEMIT=ESTEMIT;
        end
        hmm_results.models(n,iter_idx).ESTTR=ESTTR;
        hmm_results.models(n,iter_idx).sum_log_likelihood=sum_log_likelihood;
        hmm_results.models(n,iter_idx).state_labels={};
        for i=1:n_states
            hmm_results.models(n,iter_idx).state_labels{i}=num2str(i);
        end
        
        iter_idx=iter_idx+1;
    end
    
    % Save intermediate results
    save(fullfile(out_dir,'hmm_results.mat'),'hmm_results');
end

hmm_results=model_comparison(exp_info, hmm_results, model_name);

save(fullfile(out_dir,'hmm_results.mat'),'hmm_results');
% save(fullfile(out_dir,'data.mat'),'data');