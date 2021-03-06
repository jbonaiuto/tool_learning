function [guessTR,guessE,logliks,converged] = hmmtrainPoiss(seqs,guessTR,guessE,dt,varargin)
%HMMTRAIN maximum likelihood estimator of model parameters for an HMM.
%   [ESTTR, ESTEMIT] = HMMTRAIN(SEQS,TRGUESS,EMITGUESS) estimates the
%   transition and emission probabilities for a Hidden Markov Model from
%   sequences, SEQS, using the Baum-Welch algorithm.  SEQS can be a row
%   vector containing a single sequence, a matrix with one sequence per
%   row, or a cell array of sequences.  TRGUESS and EMITGUESS are initial
%   estimates of the transition and emission probability matrices.
%   TRGUESS(I,J) is the estimated probability of transition from state I to
%   state J. EMITGUESS(K,SYM) is the estimated probability that symbol SYM
%   is emitted from state K.
%
%   HMMTRAIN(...,'ALGORITHM',ALGORITHM) allows you to select the
%   training algorithm. ALGORITHM can be either 'BaumWelch' or 'Viterbi'.
%   The default algorithm is BaumWelch.
%
%   HMMTRAIN(...,'SYMBOLS',SYMBOLS) allows you to specify the symbols
%   that are emitted. SYMBOLS can be a numeric array or a cell array of the
%   names of the symbols.  The default symbols are integers 1 through M,
%   where N is the number of possible emissions.
%
%   HMMTRAIN(...,'TOLERANCE',TOL) allows you to specify the tolerance
%   used for testing convergence of the iterative estimation process.
%   The default tolerance is 1e-6.
%
%   HMMTRAIN(...,'MAXITERATIONS',MAXITER) allows you to specify the
%   maximum number of iterations for the estimation process. The default
%   number of iterations is 500.
%
%   HMMTRAIN(...,'VERBOSE',true) reports the status of the algorithm at
%   each iteration.
%
%   HMMTRAIN(...,'PSEUDOEMISSIONS',PSEUDOE) allows you to specify
%   pseudocount emission values for the Viterbi training algorithm.
%
%   HMMTRAIN(...,'PSEUDOTRANSITIONS',PSEUDOTR) allows you to specify
%   pseudocount transition values for the Viterbi training algorithm.
%
%   If the states corresponding to the sequences are known then use
%   HMMESTIMATE to estimate the model parameters.
%
%   This function always starts the model in state 1 and then makes a
%   transition to the first step using the probabilities in the first row
%   of the transition matrix. So in the example given below, the first
%   element of the output states will be 1 with probability 0.95 and 2 with
%   probability .05.
%
%   Examples:
%
% 		tr = [0.95,0.05;
%             0.10,0.90];
%
% 		e = [1/6,  1/6,  1/6,  1/6,  1/6,  1/6;
%            1/10, 1/10, 1/10, 1/10, 1/10, 1/2;];
%
%       seq1 = hmmgenerate(100,tr,e);
%       seq2 = hmmgenerate(200,tr,e);
%       seqs = {seq1,seq2};
%       [estTR, estE] = hmmtrain(seqs,tr,e);
%
%   See also  HMMGENERATE, HMMDECODE, HMMESTIMATE, HMMVITERBI.

%   Reference: Biological Sequence Analysis, Durbin, Eddy, Krogh, and
%   Mitchison, Cambridge University Press, 1998.

%   Copyright 1993-2011 The MathWorks, Inc.

poiss = @(lambda,n) (((lambda*dt).^repmat(n,1,size(lambda,2)))./repmat(factorial(n),1,size(lambda,2))).*exp(-lambda*dt); % formula for computing probability of each neurons spike count assuming Poisson spiking

defaults = struct('tolerance', 1e-6, 'maxiterations', 500,...
    'verbose', false, 'trtol', 1e-6, 'etol', 1e-6,...
    'annealing', true);  %define default values
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

[numStates, checkTr] = size(guessTR);
if checkTr ~= numStates
    error('Size of transition matrix guess doesnt match number of states');
end

% number of rows of e must be same as number of states
[checkE, numEmissions] = size(guessE);
if checkE ~= numStates
    error('Size of global emission matrix guess doesnt match number of states');
end

if isnumeric(seqs)
    [numSeqs, seqLength] = size(seqs);
    cellflag = false;
elseif iscell(seqs)
    numSeqs = numel(seqs);
    cellflag = true;
else
    error('seqs must either be a matrix (one trial) or a cell array of matrices (one for each trial)');
end

% initialize the counters
TR = zeros(size(guessTR));
pseudoTR = TR;
Enumer=zeros(numStates,numEmissions);
Edenom=zeros(numStates,1);    
pseudoEnumer = Enumer;
pseudoEdenom = Edenom;

converged = false;
loglik = 1; % loglik is the log likelihood of all sequences given the TR and E
logliks = zeros(1,params.maxiterations);
for iteration = 1:params.maxiterations
    oldLL = loglik;
    loglik = 0;
    oldGuessE = guessE;
    oldGuessTR = guessTR;
    for count = 1:numSeqs
        if cellflag
            seq = seqs{count};
            seqLength = size(seq,2);
        else
            seq = seqs(count,:);
        end
        
        % get the scaled forward and backward probabilities
        [~,logPseq,fs,bs,scale] = hmmdecodePoiss(seq,guessTR,guessE,dt);
        
        loglik = loglik + logPseq;
        % f and b start at 0 so offset seq by one
        seq = [zeros(size(seq,1),1)  seq];

        poiss_prod=zeros(numStates,seqLength);
        for i=1:seqLength
            poiss_prod(:,i)=prod(poiss(guessE',seq(:,i+1)));
        end
        
        for k = 1:numStates
            for l = 1:numStates
                TR(k,l) = TR(k,l)+sum((fs(k,1:seqLength)*guessTR(k,l).*bs(l,2:seqLength+1).*poiss_prod(l,:))./scale(2:seqLength+1));
            end
        end
        gamma = (fs(:,1:seqLength).*bs(:,1:seqLength))./repmat(sum(fs(:,1:seqLength).*bs(:,1:seqLength)),numStates,1);
        Enumer=Enumer+(seq(:,2:end)*gamma')';
        Edenom=Edenom+sum(gamma,2);
    end
    totalTransitions = sum(TR,2);
    
    % avoid divide by zero warnings
    guessE = Enumer./(repmat(Edenom,1,numEmissions))/dt;
    guessTR  = TR./(repmat(totalTransitions,1,numStates));
    % if any rows have zero transitions then assume that there are no
    % transitions out of the state.
    if any(totalTransitions == 0)
        noTransitionRows = find(totalTransitions == 0);
        guessTR(noTransitionRows,:) = 0;
        guessTR(sub2ind(size(guessTR),noTransitionRows,noTransitionRows)) = 1;
    end
    % clean up any remaining Nans
    guessTR(isnan(guessTR)) = 0;
    guessE(isnan(guessE)) = 0;
    
    % Simulated annealing
    if params.annealing
        perturbedTR=guessTR;
        % Randomly select half of TR matrix rows
        selected_rows=randperm(numStates,round(numStates/2));
        % for each selected row i, choose a single column j
        for i=1:length(selected_rows)
            probs=ones(1,numStates).*(.5/(numStates-1));
            probs(selected_rows(i))=.5;
            j=randsample(numStates,1,true,probs);
            % Transition probabilities in the resulting matrix indices were then
            % each increased by a random factor
            perturbedTR(selected_rows(i),j)=perturbedTR(selected_rows(i),j)+.1*rand();
            % followed by a normalization of the rest of the transition 
            % probabilities in the same row, such that each row will still sum
            % to 1. 
            perturbedTR(selected_rows(i),:)=perturbedTR(selected_rows(i),:)./sum(perturbedTR(selected_rows(i),:));
        end
        % Next, the difference between the log-likelihoods of the original and
        % the candidate parameters was computed:
        perturbedLL=0;
        for count = 1:numSeqs
            if cellflag
                seq = seqs{count};
                seqLength = size(seq,2);
            else
                seq = seqs(count,:);
            end

            % get the scaled forward and backward probabilities
            [~,logPseq,fs,bs,scale] = hmmdecodePoiss(seq,perturbedTR,guessE,dt);

            perturbedLL = perturbedLL + logPseq;
        end
        deltaLL=loglik-perturbedLL;

        % The candidate parameters were then accepted with probability
        inv_temp=1./iteration;
        accept_prob=min([1,inv_temp.*exp(-.003*deltaLL)]);
        if rand()<accept_prob
            if params.verbose
                disp(sprintf('inv_temp=%.4f, deltaLL=%.4f, accept_prob=%.4f, perturbing', inv_temp, deltaLL, accept_prob));
            end
            guessTR=perturbedTR;
            loglik=perturbedLL;
        end
    end
        
    if params.verbose
        if iteration == 1
            fprintf('%s\n',getString(message('stats:hmmtrain:RelativeChanges')));
            fprintf('   Iteration       Log Lik    Transition     Emmission\n');
        else 
            fprintf('  %6d      %12g  %12g  %12g\n', iteration, ...
                (abs(loglik-oldLL)./(1+abs(oldLL))), ...
                norm(guessTR - oldGuessTR,inf)./numStates, ...
                norm(guessE - oldGuessE,inf)./numEmissions);
        end
    end
    % Durbin et al recommend loglik as the convergence criteria  -- we also
    % use change in TR and E. Use (undocumented) option trtol and
    % etol to set the convergence tolerance for these independently.
    %
    logliks(iteration) = loglik;
    if (abs(loglik-oldLL)/(1+abs(oldLL))) < params.tolerance
        if norm(guessTR - oldGuessTR,inf)/numStates < params.trtol
            if norm(guessE - oldGuessE,inf)/numEmissions < params.etol
                if params.verbose
                    fprintf('%s\n',getString(message('stats:hmmtrain:ConvergedAfterIterations',iteration)))
                end
                converged = true;
                break
            end
        end
    end
    Enumer =  pseudoEnumer;
    Edenom =  pseudoEdenom;
    TR = pseudoTR;
end
if ~converged
    warning(message('stats:hmmtrain:NoConvergence', num2str( params.tolerance ), params.maxiterations));
end
logliks(logliks ==0) = [];
