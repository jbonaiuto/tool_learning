function err=compute_errors(params, trial_data, model, state_seq_vecs)
    
err=[];
for i=1:length(trial_data)
    ideal_pstates=zeros(params.nPredictedStates,length(model.STATES{i}));
    for j=1:params.nPredictedStates
        ideal_pstates(j,find(state_seq_vecs{i}==j))=1;
    end
    err(i)=mean(sqrt(sum((ideal_pstates-model.PSTATES{i}).^2,2)));
end
