function [poisson_model, multinomial_model]=run_simulation(params, trial_data)
% RUN_SIMULATION Run simulation using univarite multinomial and univariate
% Poisson HMMs
%
% Syntax: [poisson_model, multinomial_model]=run_simulation(params, trial_data)
%
% Inputs:
%    params - structure of simulaton parameters
%    trial_data - cell array with a matrix of spikes for each trial
%
% Outputs:
%    poisson_model - fitted Poisson model
%    multinomial_model - fitted multinomial model 
% 
% Example:
%     [poisson_model, multinomial_model]=run_simulation(params, trial_data)

addpath('..');

% Create symbol vectors for each trial for multinomial model
SEQ=create_symbol_vectors(trial_data);

% All models
poisson_models=[];
multinomial_models=[];

% Run multiple times
for i=1:params.numRuns 
    
    % Initialize state transition probability guess
    TRGUESS=zeros(params.nPredictedStates, params.nPredictedStates);
    for j=1:params.nPredictedStates
        for k=1:params.nPredictedStates
            if (j == k)
                TRGUESS(j,k) = .99;
            else
                TRGUESS(j,k) = .01/(params.nPredictedStates-1);
            end
        end
    end
    % Initialize emission probability guess
    EMITGUESS=rand(params.nPredictedStates,params.nNeurons+1);

    % Poisson HMM
    [ESTTR,ESTEMIT] = hmmtrainPoiss(trial_data,TRGUESS,...
        EMITGUESS(:,1:params.nNeurons),params.dt,'verbose',true,...
        'maxiterations',params.maxIterations,'annealing',false);
    poisson_models(i).ESTTR=ESTTR;
    poisson_models(i).ESTEMIT=ESTEMIT;
    % Decode trials
    poisson_models(i).STATES = {};
    poisson_models(i).PSTATES= {};
    poisson_models(i).LL=0;
    for j=1:length(trial_data)
        [poisson_models(i).STATES{j}, trial_LL]=hmmviterbiPoiss(trial_data{j},ESTTR,ESTEMIT,...
            params.dt);
        poisson_models(i).PSTATES{j} = hmmdecodePoiss(trial_data{j},ESTTR,ESTEMIT,...
            params.dt);
        poisson_models(i).LL=poisson_models(i).LL+trial_LL;
    end
    
    % multivariate HMM
    [ESTTR,ESTEMIT] = hmmtrain(SEQ,TRGUESS,EMITGUESS,'verbose',false,...
        'Symbols',[0:params.nNeurons],'maxiterations',params.maxIterations);
    multinomial_models(i).ESTTR=ESTTR;
    multinomial_models(i).ESTEMIT=ESTEMIT;
    % Decode trials
    multinomial_models(i).STATES = {};
    multinomial_models(i).PSTATES= {};
    multinomial_models(i).LL=0;
    for j=1:length(SEQ)
        [multinomial_models(i).STATES{j}, trial_LL]=hmmviterbi(SEQ{j},ESTTR,ESTEMIT,...
            'Symbols',[0:params.nNeurons]);
        multinomial_models(i).PSTATES{j} = hmmdecode(SEQ{j},ESTTR,ESTEMIT,...
            'Symbols',[0:params.nNeurons]);
        multinomial_models(i).LL=multinomial_models(i).LL+trial_LL;
    end
end

% Find models that maximize log likelihood
[maxPoissLL,maxPoissIdx]=max([poisson_models.LL]);
[maxMultinomialLL,maxMultinomialIdx]=max([multinomial_models.LL]);

poisson_model=poisson_models(maxPoissIdx);
multinomial_model=multinomial_models(maxMultinomialIdx);

rmpath('..');