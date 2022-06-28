function state_idx=get_state_idx(model)

max_state_id=max(cellfun(@str2num, model.metadata.state_labels));
state_idx=-1*ones(1,max_state_id);
for i=1:max_state_id
    idx=find(strcmp(model.metadata.state_labels,num2str(i)));
    if length(idx)
        state_idx(i)=idx;
    end
end