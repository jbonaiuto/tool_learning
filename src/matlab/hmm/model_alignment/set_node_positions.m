function set_node_positions(S, X, ref_model, new_model)
    X2=S.getNodePositions();
    for i=1:new_model.n_states
        state_name=new_model.state_labels{i};
        j=find(strcmp(ref_model.state_labels,state_name));
        if length(j)
            X2(i,:)=X(j,:);
        end
    end
    S.setNodePositions(X2);
end