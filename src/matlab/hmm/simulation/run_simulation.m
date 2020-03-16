function [poissonModel, multinomialModel]=run_simulation(params, trial_data)

SEQ=create_symbol_vectors(trial_data);

poissonModels=[];
multinomialModels=[];

for i=1:params.numRuns    
    for j=1:params.nPredictedStates
        for k=1:params.nPredictedStates
            if (j == k)
                TRGUESS(j,k) = .99;
            else
                TRGUESS(j,k) = .01/(params.nPredictedStates-1);
            end
        end
    end
    EMITGUESS=rand(params.nPredictedStates,params.nNeurons+1);

    % poissHMM
    [ESTTR,ESTEMIT] = hmmtrainPoiss(trial_data,TRGUESS,...
        EMITGUESS(:,1:params.nNeurons),params.dt,'verbose',true,...
        'maxiterations',params.maxIterations);
    poissonModels(i).ESTTR=ESTTR;
    poissonModels(i).ESTEMIT=ESTEMIT;
    poissonModels(i).STATES = {};
    poissonModels(i).PSTATES= {};
    poissonModels(i).LL=0;
    for j=1:length(trial_data)
        [poissonModels(i).STATES{j}, trial_LL]=hmmviterbiPoiss(trial_data{j},ESTTR,ESTEMIT,...
            params.dt);
        poissonModels(i).PSTATES{j} = hmmdecodePoiss(trial_data{j},ESTTR,ESTEMIT,...
            params.dt);
        poissonModels(i).LL=poissonModels(i).LL+trial_LL;
    end
    
    % normal HMM
    [ESTTR,ESTEMIT] = hmmtrain(SEQ,TRGUESS,EMITGUESS,'verbose',false,...
        'Symbols',[0:params.nNeurons],'maxiterations',params.maxIterations);
    multinomialModels(i).ESTTR=ESTTR;
    multinomialModels(i).ESTEMIT=ESTEMIT;
    multinomialModels(i).STATES = {};
    multinomialModels(i).PSTATES= {};
    multinomialModels(i).LL=0;
    for j=1:length(SEQ)
        [multinomialModels(i).STATES{j}, trial_LL]=hmmviterbi(SEQ{j},ESTTR,ESTEMIT,...
            'Symbols',[0:params.nNeurons]);
        multinomialModels(i).PSTATES{j} = hmmdecode(SEQ{j},ESTTR,ESTEMIT,...
            'Symbols',[0:params.nNeurons]);
        multinomialModels(i).LL=multinomialModels(i).LL+trial_LL;
    end
end

[maxPoissLL,maxPoissIdx]=max([poissonModels.LL]);
[maxMultinomialLL,maxMultinomialIdx]=max([multinomialModels.LL]);

poissonModel=poissonModels(maxPoissIdx);
multinomialModel=multinomialModels(maxMultinomialIdx);

