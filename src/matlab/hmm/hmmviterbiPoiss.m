function [currentState, logP] = hmmviterbiPoiss(seq,tr,e,dt,varargin)
%HMMVITERBI calculates the most probable state path for a sequence.
%   STATES = HMMVITERBI(SEQ,TRANSITIONS,EMISSIONS) given a sequence, SEQ,
%   calculates the most likely path through the Hidden Markov Model
%   specified by transition probability matrix, TRANSITIONS, and emission
%   probability matrix, EMISSIONS. TRANSITIONS(I,J) is the probability of
%   transition from state I to state J. EMISSIONS(K,L) is the probability
%   that symbol L is emitted from state K. 
%
%   HMMVITERBI(...,'SYMBOLS',SYMBOLS) allows you to specify the symbols
%   that are emitted. SYMBOLS can be a numeric array or a cell array of the
%   names of the symbols.  The default symbols are integers 1 through N,
%   where N is the number of possible emissions.
%
%   HMMVITERBI(...,'STATENAMES',STATENAMES) allows you to specify the
%   names of the states. STATENAMES can be a numeric array or a cell array
%   of the names of the states. The default statenames are 1 through M,
%   where M is the number of states.
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
%       [seq, states] = hmmgenerate(100,tr,e);
%       estimatedStates = hmmviterbi(seq,tr,e);
%
%       [seq, states] = hmmgenerate(100,tr,e,'Statenames',{'fair';'loaded'});
%       estimatesStates = hmmviterbi(seq,tr,e,'Statenames',{'fair';'loaded'});
%
%   See also HMMGENERATE, HMMDECODE, HMMESTIMATE, HMMTRAIN.

%   Reference: Biological Sequence Analysis, Durbin, Eddy, Krogh, and
%   Mitchison, Cambridge University Press, 1998.  

%   Copyright 1993-2011 The MathWorks, Inc.

poiss = @(lambda,n) (((lambda*dt).^repmat(n,1,size(lambda,2)))./repmat(factorial(n),1,size(lambda,2))).*exp(-lambda*dt); % formula for computing probability of each neurons spike count assuming Poisson spiking

% tr must be square

numStates = size(tr,1);
checkTr = size(tr,2);
if checkTr ~= numStates
    error(message('stats:hmmviterbi:BadTransitions'));
end

% number of rows of e must be same as number of states

checkE = size(e,1);
if checkE ~= numStates
    error(message('stats:hmmviterbi:InputSizeMismatch'));
end

numEmissions = size(e,2);
customStatenames = false;

% deal with options
if nargin > 4
    okargs = {'statenames'};
    [statenames] = ...
        internal.stats.parseArgs(okargs, {[]}, varargin{:});
    
    if ~isempty(statenames)
        numStateNames = length(statenames);
        if numStateNames ~= numStates
            error(message('stats:hmmviterbi:BadStateNames'));
        end
        customStatenames = true;
    end
end


% work in log space to avoid numerical issues
L = size(seq,2);
currentState = zeros(1,L);
if L == 0
    return
end
% logTR = log(tr);
% logE = log(e);
% 
% % allocate space
% pTR = zeros(numStates,L);
% % assumption is that model is in state 1 at step 0
% v = -Inf(numStates,1);
% v(1,1) = 0;
% vOld = v;
% 
% % loop through the model
% for count = 1:L
%     for state = 1:numStates
%         % for each state we calculate
%         % v(state) = e(state,seq(count))* max_k(vOld(:)*tr(k,state));
%         bestVal = -inf;
%         bestPTR = 0;
%         % use a loop to avoid lots of calls to max
%         for inner = 1:numStates 
%             val = vOld(inner) + logTR(inner,state);
%             if val > bestVal
%                 bestVal = val;
%                 bestPTR = inner;
%             end
%         end
%         % save the best transition information for later backtracking
%         pTR(state,count) = bestPTR;
%         % update v
%         %v(state) = logE(state,seq(count)) + bestVal;
%         v(state) = log(prod(poiss(e(state,:)',seq(count)))) + bestVal;
%     end
%     vOld = v;
% end
% 
% % decide which of the final states is post probable
% [logP, finalState] = max(v);
% 
% % Now back trace through the model
% currentState(L) = finalState;
% for count = L-1:-1:1
%     currentState(count) = pTR(currentState(count+1),count+1);
%     if currentState(count) == 0
%         error(message('stats:hmmviterbi:ZeroTransitionProbability', currentState( count + 1 )));
%     end
% end
% if customStatenames
%     currentState = reshape(statenames(currentState),1,L);
% end
% 
% 
PI=zeros(1,numStates);
PI(1)=1;
T1 = zeros(numStates,L);
T2 = zeros(numStates,L);
for i=1:numStates
    T1(i,1) = log(PI(i)) + log(prod(poiss(e(i,:)',seq(:,1))));
    T2(i,1) = 0;
end

for j=2:L
    for i=1:numStates
        vec1 = T1(:,j-1) + log(tr(:,i)) + log(prod(poiss(e(i,:)',seq(:,j))));
        vec2 = T1(:,j-1) + log(tr(:,i));
        T1(i,j) = max(vec1);
        [~,ind] = max(vec2);
        T2(i,j) = ind;
    end
end

[logP,bestPathEndState] = max(T1(:,end));
currentState = zeros(1,L);
currentState(end) = bestPathEndState;
for t=fliplr(1:(L-1))
    currentState(t) = T2(currentState(t+1),t+1);
end
end

