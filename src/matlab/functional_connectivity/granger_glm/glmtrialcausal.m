function [beta_new,devnew,stats] = glmtrialcausal(Y,y,trigger,ht,w,varargin)

%================================================================
%  GLM fitting based on submatrices after excluding the effect
%  of the spiking history of trigger neuron, when input data 
%  structure is [neurons x samples x trials]
%================================================================
%
%  This code is made for the case when input matrix Y is too huge
%  Y is partioned into many small submatrices of (k x 1)-dimension
%  This code is based on bnlrCG.m (Demba) and
%
%   References:
%      Dobson, A.J. (1990), "An Introduction to Generalized Linear
%         Models," CRC Press.
%      McCullagh, P., and J.A. Nelder (1990), "Generalized Linear
%         Models," CRC Press.
%
% Input arguments:
%        stim: stimulus
%           Y: measurement data (#Neurons x #Samples x #Trails)
%           y: index number of input (neuron) to analyze
%     trigger: index number of a neuron whose effect will be excluded
%          ht: model order (using AIC or BIC)
%           w: duration of non-overlapping spike counting window
%
% Output arguments:
%     beta_new: estimated GLM parameters (p x 1)
%
%================================================================
% SangGyun Kim
% Neuroscience Statistics Research Lab (BCS MIT)
% April 13. 2009
%================================================================

% Parse optional arguments
defaults=struct('n_splits', 10);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

% Counting window
WIN = zeros(ht/w,ht);
for iwin = 1:ht/w
    WIN(iwin,(iwin-1)*w+1:iwin*w) = 1;
end

% CG parameters
cgeps = 1e-3;
cgmax = 30;

% LR parameters
Irmax = 100;
Ireps = 0.05;

% Dimension of Y (# Channels x # Samples x # Trials)
[CHN SAM TRL] = size(Y); 

% Removing trigger neuron
if trigger == 1
    Yc = Y(trigger+1:end,:,:);
elseif trigger == CHN
    Yc = Y(1:trigger-1,:,:);
else
    Yc = [Y(1:trigger-1,:,:); Y(trigger+1:end,:,:)];
end

% % Update Y aftering excluding trigger neuron
% clear Y;
% Y = Yc;

% Dimension of new Yc
[CHN SAM TRL] = size(Yc);
% Design matrix, including DC column of all ones (1st or last)
for itrial = 1:TRL 
    SAM = max(find(~isnan(Yc(1,:,itrial))));
    
    temp = ones(SAM-ht,1);
    for ichannel = 1:CHN 
        for hh = 0:3:ht-3
            temp0 = Yc(ichannel,ht-hh:SAM-1-hh,itrial)' + Yc(ichannel,ht-1-hh:SAM-2-hh,itrial)' + Yc(ichannel,ht-2-hh:SAM-3-hh,itrial)';
            temp = [temp temp0];
        end
    end
    BIGXsub{itrial} = temp;
    %end
    int_leng = fix((SAM-ht)/params.n_splits);
    for isplit = 1:params.n_splits
        Xsub{isplit+(itrial-1)*params.n_splits} = BIGXsub{itrial}(int_leng*(isplit-1)+1:int_leng*isplit,:);
    end
end

% Making output matrix Ysub{}
for itrial = 1:TRL
 
    SAM = max(find(~isnan(Y(1,:,itrial))));
    int_leng = fix((SAM-ht)/params.n_splits);
    
    BIGYsub{itrial} = Y(y,ht+1:SAM,itrial)';
    for isplit = 1:params.n_splits
        Ysub{isplit+(itrial-1)*params.n_splits} = BIGYsub{itrial}(int_leng*(isplit-1)+1:int_leng*isplit);
    end
end

% Logistic regression
i = 0;
% Initialization
P = length(Xsub{1});

p = CHN*ht/w + 1;
beta_old = zeros(p,1);
% W = {Wsub{kk}} & z = {zsub{kk}}
for iepoch = 1:TRL*params.n_splits
    eta{iepoch} = Xsub{iepoch}*beta_old;
    musub{iepoch} = exp(eta{iepoch})./(1+exp(eta{iepoch}));
    Wsub{iepoch} = diag(musub{iepoch}).*diag(1-musub{iepoch});
    zsub{iepoch} = eta{iepoch} + (Ysub{iepoch}-musub{iepoch}).*(1./diag(Wsub{iepoch}));
end

% Scaled deviance
devold = 0;
for iepoch = 1:TRL*params.n_splits
    devold = devold - 2*(Ysub{iepoch}'*log(musub{iepoch})+(1-Ysub{iepoch})'*log(1-musub{iepoch}));
end
devnew = 0;
devdiff = abs(devnew - devold);

% Iterative weighted least-squares
while (i < Irmax && devdiff > Ireps)

    A = zeros(p,p);
    for iepoch = 1:TRL*params.n_splits
        A = A + Xsub{iepoch}'*Wsub{iepoch}*Xsub{iepoch};
    end
    %A = A + A' - diag(diag(A));

    b = zeros(p,1);
    for iepoch = 1:TRL*params.n_splits
        b = b + Xsub{iepoch}'*Wsub{iepoch}*zsub{iepoch};
    end

    % Conjugate gradient method for symmetric postive definite matrix A
    beta_new = cgs(A,b,cgeps,cgmax,[],[],beta_old);
    beta_old = beta_new;

    for iepoch = 1:TRL*params.n_splits
        eta{iepoch} = Xsub{iepoch}*beta_old;
        musub{iepoch} = exp(eta{iepoch})./(1+exp(eta{iepoch}));
        Wsub{iepoch} = diag(musub{iepoch}).*diag(1-musub{iepoch});
        zsub{iepoch} = eta{iepoch} + (Ysub{iepoch}-musub{iepoch}).*(1./diag(Wsub{iepoch}));
    end

    % Scaled deviance
    devnew = 0;
    for iepoch = 1:TRL*params.n_splits
        devnew = devnew - 2*(Ysub{iepoch}'*log(musub{iepoch})+(1-Ysub{iepoch})'*log(1-musub{iepoch}));
    end
    devdiff = abs(devnew - devold);
    devold = devnew;

    i = i+1;

end

% % Compute additional statistics
% stats.dfe = 0;
% stats.s = 0;
% stats.sfit = 0;
% stats.covb = inv(A);
% stats.se = sqrt(diag(stats.covb));
% stats.coeffcorr = stats.covb./sqrt((repmat(diag(stats.covb),1,p).*repmat(diag(stats.covb)',p,1)));
% stats.t = 0;
% stats.p = 0;
% stats.resid = 0;
% stats.residp = 0;
% stats.residd = 0;
% stats.resida = 0;