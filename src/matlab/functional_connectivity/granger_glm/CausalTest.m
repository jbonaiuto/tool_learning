% Dimension of X (# Channels x # Samples x # Trials)
function causal_results=CausalTest(X, aic, bhat, LLK)
defaults=struct('n_splits', 10);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

% Load  data
%load data_real_catM1.mat;
%load data_real_nonmove.mat;
%load result_real_catM1.mat;
%load spikes.mat;
%load spikes_results.mat;

% Dimension of X (# Channels x # Samples x # Trials)
[CHN SMP TRL] = size(X);

% Selected spiking history orders by AIC
%ht = [1 11 1 5 18 17 1 1 15 17 1 11 1 9 5];        
% ht = [1 1 1 1 1 1 1 1 1 1 1 7 1 2 1];       % Non-movement

ht=[];
for i=1:CHN
    min_aic=min(aic(3:3:60,i));
    optim_h=find(aic(3:3:60,i)==min_aic);
    ht(i)=optim_h;
end

% Re-optimizing a model after excluding a trigger neuron's effect and then
% Estimating causality matrices based on the likelihood ratio
for target = 1:CHN
    LLK0(target) = LLK(3*ht(target),target);
    for trigger = 1:CHN
        % MLE after excluding trigger neuron
        [bhatc{target,trigger},devnewc{target,trigger}] = glmtrialcausal(X,target,trigger,3*ht(target),3,'n_splits',params.n_splits);
        
        % Log likelihood obtained using a new GLM parameter and data, which
        % exclude trigger
        LLKC(target,trigger) = log_likelihood_trialcausal(bhatc{target,trigger},X,trigger,3*ht(target),target);
               
        % Log likelihood ratio
        LLKR(target,trigger) = LLKC(target,trigger) - LLK0(target);
        
        % Sign (excitation and inhibition) of interaction from trigger to target
        % Averaged influence of the spiking history of trigger on target
        SGN(target,trigger) = sign(sum(bhat{3*ht(target),target}(ht(target)*(trigger-1)+2:ht(target)*trigger+1)));
    end
end

% Granger causality matrix, Phi
Phi = -SGN.*LLKR;

% ==== Significance Testing ====
% Causal connectivity matrix, Psi, w/o FDR
D = -2*LLKR;                                     % Deviance difference
alpha = 0.05;
for ichannel = 1:CHN
    temp1(ichannel,:) = D(ichannel,:) > chi2inv(1-alpha,ht(ichannel)/2);
end
Psi1 = SGN.*temp1;

% Causal connectivity matrix, Psi, w/ FDR
fdrv = 0.01;
temp2 = FDR(D,fdrv,ht);
Psi2 = SGN.*temp2;

causal_results=[];
causal_results.ht=ht;
causal_results.LK0=LLK0;
causal_results.bhatc=bhatc;
causal_results.devnewc=devnewc;
causal_results.LLKC=LLKC;
causal_results.LLKR=LLKR;
causal_results.SGN=SGN;
causal_results.Phi=Phi;
causal_results.Psi1=Psi1;
causal_results.Psi2=Psi2;

% save('CausalMaps','bhatc','LLK0','LLKC','LLKR','D','SGN','Phi','Psi1','Psi2');
