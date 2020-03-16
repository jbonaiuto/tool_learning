function poissonModel=run_longitudinal_simulation(params, day_data)

poissonModels=[];

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
    GLOBAL_EMITGUESS=rand(params.nPredictedStates,params.nNeurons);
    DAY_EMITGUESS=rand(length(day_data),params.nPredictedStates,params.nNeurons).*.1;
    

    % poissHMM
    [ESTTR,GLOBAL_ESTEMIT,DAY_ESTEMIT] = hmmtrainMultilevelPoiss(day_data,TRGUESS,...
        GLOBAL_EMITGUESS,DAY_EMITGUESS,params.dt,'verbose',true,...
        'maxiterations',params.maxIterations);
    poissonModels(i).ESTTR=ESTTR;
    poissonModels(i).GLOBAL_ESTEMIT=GLOBAL_ESTEMIT;
    poissonModels(i).DAY_ESTEMIT=DAY_ESTEMIT;
    poissonModels(i).STATES = {};
    poissonModels(i).PSTATES= {};
    poissonModels(i).LL=0;
    for j=1:length(day_data)
        trial_data=day_data{j};
        effectiveE=GLOBAL_ESTEMIT+squeeze(DAY_ESTEMIT(j,:,:));
        for k=1:length(trial_data)
            [poissonModels(i).STATES{end+1}, trial_LL]=hmmviterbiPoiss(trial_data{k},ESTTR,effectiveE,...
                params.dt);
            poissonModels(i).PSTATES{end+1} = hmmdecodePoiss(trial_data{k},ESTTR,effectiveE,...
                params.dt);
            poissonModels(i).LL=poissonModels(i).LL+trial_LL;
        end
    end        
end

[maxPoissLL,maxPoissIdx]=max([poissonModels.LL]);

poissonModel=poissonModels(maxPoissIdx);

