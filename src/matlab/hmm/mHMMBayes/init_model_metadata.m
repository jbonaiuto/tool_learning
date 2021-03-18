function init_model_metadata(model)

metadata=[];
metadata.state_labels={};
for i=1:model.n_states
    metadata.state_labels{i}=num2str(i);
end

save(fullfile(model.path, model.metadata_fname),'metadata');