function model=relabel_states(model, new_labels)

old_model=model;
for i=1:size(old_model.ESTTR,1)
    for j=1:size(old_model.ESTTR,2)
        model.ESTTR(i,j)=old_model.ESTTR(new_labels(i),new_labels(j));
    end
end
for i=1:size(old_model.ESTEMIT,1)
    model.ESTEMIT(i,:)=old_model.ESTEMIT(new_labels(i),:);
end
for i=1:length(old_model.PSTATES)
    model.PSTATES{i}=old_model.PSTATES{i}(new_labels,:);
end
for i=1:length(old_model.STATES)
    transformed_STATES=old_model.STATES{i};
    for j=1:size(old_model.ESTTR,1)
        transformed_STATES(old_model.STATES{i}==new_labels(j))=j;
    end
    model.STATES{i}=transformed_STATES;
end
    