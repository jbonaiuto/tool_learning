function [guessTR_global,guessE_global,guessE_day,logliks] = hmmtrainMultilevelPoiss(seqs,guessTR_global,guessE_global,guessE_day,dt,varargin)
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

tol = 1e-6;
trtol = tol;
etol = tol;
maxiter = 500;
verbose = false;
[numStates, checkTr] = size(guessTR_global);
if checkTr ~= numStates
    error(message('stats:hmmtrain:BadTransitions'));
end

% number of rows of e must be same as number of states

[checkE, numEmissions] = size(guessE_global);
if checkE ~= numStates
    error(message('stats:hmmtrain:InputSizeMismatch'));
end
if (numStates ==0 || numEmissions == 0)
    guessTR_global = [];
    guessE_global = [];
    return
end

if nargin > 4
    okargs = {'tolerance','maxiterations','verbose','trtol','etol'};
    dflts  = {[]         maxiter         verbose   []      []};
    [tol,maxiter,verbose,trtol,etol] = ...
        internal.stats.parseArgs(okargs, dflts, varargin{:});
    
    if ischar(verbose)
        verbose = any(strcmpi(verbose,{'on','true','yes'}));
    end    
end

if isempty(tol)
    tol = 1e-6;
end
if isempty(trtol)
    trtol = tol;
end
if isempty(etol)
    etol = tol;
end


if iscell(seqs)
    %numSeqs = numel(seqs);
    numDays = numel(seqs);
else
    error(message('stats:hmmtrain:BadSequence'));
end

% initialize the counters
TR = zeros(size(guessTR_global));
Enumer_global=zeros(numStates,numEmissions);
Edenom_global=zeros(numStates,1);    
Enumer_day=zeros(numDays,numStates,numEmissions);
Edenom_day=zeros(numDays,numStates);    

converged = false;
loglik = 1; % loglik is the log likelihood of all sequences given the TR and E
logliks = zeros(1,maxiter);
for iteration = 1:maxiter
    oldLL = loglik;
    loglik = 0;
    oldGuessE_global = guessE_global;
    oldGuessTR_global = guessTR_global;
    
    Enumer_global =  zeros(numStates,numEmissions);
    Edenom_global =  zeros(numStates,1);
    TR = zeros(size(guessTR_global));

    for day_idx = 1:numDays
        day_seqs = seqs{day_idx};
        numSeqs=numel(day_seqs);
        for seq_idx=1:numSeqs
            seq=day_seqs{seq_idx};
            seqLength = size(seq,2);

            % get the scaled forward and backward probabilities
            [~,logPseq,fs,bs,scale] = hmmdecodePoiss(seq,guessTR_global,guessE_global,dt);

            % f and b start at 0 so offset seq by one
            seq = [zeros(size(seq,1),1)  seq];

            poiss_prod=zeros(numStates,seqLength);
            for i=1:seqLength
                poiss_prod(:,i)=prod(poiss(guessE_global',seq(:,i+1)));
            end

            for k = 1:numStates
                for l = 1:numStates
                    TR(k,l) = TR(k,l)+sum((fs(k,1:seqLength)*guessTR_global(k,l).*bs(l,2:seqLength+1).*poiss_prod(l,:))./scale(2:seqLength+1));
                end
            end
            gamma = (fs(:,1:seqLength).*bs(:,1:seqLength))./repmat(sum(fs(:,1:seqLength).*bs(:,1:seqLength)),numStates,1);
            Enumer_global=Enumer_global+(seq(:,2:end)*gamma')';
            Edenom_global=Edenom_global+sum(gamma,2);
        end
    end
    totalTransitions = sum(TR,2);
    
    % avoid divide by zero warnings
    guessE_global = Enumer_global./(repmat(Edenom_global,1,numEmissions))/dt;
    guessTR_global  = TR./(repmat(totalTransitions,1,numStates));
    % if any rows have zero transitions then assume that there are no
    % transitions out of the state.
    if any(totalTransitions == 0)
        noTransitionRows = find(totalTransitions == 0);
        guessTR_global(noTransitionRows,:) = 0;
        guessTR_global(sub2ind(size(guessTR_global),noTransitionRows,noTransitionRows)) = 1;
    end
    % clean up any remaining Nans
    guessTR_global(isnan(guessTR_global)) = 0;
    guessE_global(isnan(guessE_global)) = 0;
    
    oldGuessE_day = guessE_day;
    for day_idx = 1:numDays
        effectiveE=guessE_global+squeeze(guessE_day(day_idx,:,:));
        Enumer_day =  zeros(numStates,numEmissions);
        Edenom_day =  zeros(numStates,1);
    
        day_seqs = seqs{day_idx};
        numSeqs=numel(day_seqs);
        for seq_idx=1:numSeqs
            seq=day_seqs{seq_idx};
            seqLength = size(seq,2);

            % get the scaled forward and backward probabilities
            [~,logPseq,fs,bs,scale] = hmmdecodePoiss(seq,guessTR_global,effectiveE,dt);

            loglik = loglik + logPseq;
            % f and b start at 0 so offset seq by one
            seq = [zeros(size(seq,1),1)  seq];

            poiss_prod=zeros(numStates,seqLength);
            for i=1:seqLength
                poiss_prod(:,i)=prod(poiss(effectiveE',seq(:,i+1)));
            end

            gamma = (fs(:,1:seqLength).*bs(:,1:seqLength))./repmat(sum(fs(:,1:seqLength).*bs(:,1:seqLength)),numStates,1);
            Enumer_day=Enumer_day+(seq(:,2:end)*gamma')';
            Edenom_day=Edenom_day+sum(gamma,2);
        end
        
        % avoid divide by zero warnings
        guesseffectiveE = Enumer_day./(repmat(Edenom_day,1,numEmissions))/dt;
        % clean up any remaining Nans
        guesseffectiveE(isnan(guesseffectiveE)) = 0;
        
        guessE_day(day_idx,:,:)=guesseffectiveE-guessE_global;
    end
        
    delta_LL=(abs(loglik-oldLL)/(1+abs(oldLL)));
    delta_TR=norm(guessTR_global - oldGuessTR_global,inf)./numStates;
    delta_E_global=norm(guessE_global - oldGuessE_global,inf)./numEmissions;
    delta_E_day=0;
    for day_idx = 1:numDays
        delta_E_day=delta_E_day+norm(squeeze(guessE_day(day_idx,:,:)) - squeeze(oldGuessE_day(day_idx,:,:)),inf)./numEmissions;
    end
    if verbose
        if iteration == 1
            fprintf('%s\n',getString(message('stats:hmmtrain:RelativeChanges')));
            fprintf('   Iteration       Log Lik    Transition     Global Emmission     Day Emission\n');
        else 
            fprintf('  %6d      %12g  %12g  %12g  %12g\n', iteration, ...
                delta_LL, delta_TR, delta_E_global, delta_E_day);
        end
    end
    % Durbin et al recommend loglik as the convergence criteria  -- we also
    % use change in TR and E. Use (undocumented) option trtol and
    % etol to set the convergence tolerance for these independently.
    %
    logliks(iteration) = loglik;
    if delta_LL < tol
        if delta_TR < trtol
            if delta_E_global < etol
                if delta_E_day < etol*numDays
                    if verbose
                        fprintf('%s\n',getString(message('stats:hmmtrain:ConvergedAfterIterations',iteration)))
                    end
                    converged = true;
                    break
                end
            end
        end
    end
end
if ~converged
    warning(message('stats:hmmtrain:NoConvergence', num2str( tol ), maxiter));
end
logliks(logliks ==0) = [];
