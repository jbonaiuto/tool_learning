function model=load_model(model_path, model_name, varargin)

%define default values
defaults = struct('reinit_metadata',false);  
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

model=[];

% Save basic model info
model.name=model_name;
model.path=model_path;
model.fname=sprintf('model_%s.rda',model.name);

% If model file from R exists
if exist(fullfile(model.path, model.fname),'file')==2
    
    % Load forward probabilities
    model.forward_probs_fname=sprintf('forward_probs_%s.csv',model.name);
    if exist(fullfile(model.path, model.forward_probs_fname),'file')==2
        model.forward_probs=readtable(fullfile(model.path, model.forward_probs_fname));
        
        % Determine number of states
        model.n_states=0;
        for i=1:length(model.forward_probs.Properties.VariableNames)
            var_name=model.forward_probs.Properties.VariableNames{i};
            if length(var_name)>8 && strcmp(var_name(1:8),'fw_prob_')
                model.n_states=model.n_states+1;
            end
        end
    end

    % Export transition probabilities if not done already
    model.trans_probs_fname=sprintf('trans_probs_%s.csv',model.name);
    if exist(fullfile(model.path, model.trans_probs_fname),'file')~=2
        system(sprintf('"C:/Program Files/R/R-3.6.1/bin/Rscript" ../../../R/hmm/extract_transition_probs.R %s %s', fullfile(model.path,model.fname),...
            fullfile(model.path,model.trans_probs_fname)));
    end
    % Load transition probabilities
    model_trans_probs=readtable(fullfile(model.path, model.trans_probs_fname));
    model.trans_mat=zeros(model.n_states,model.n_states);
    for i=1:size(model_trans_probs)
        model.trans_mat(model_trans_probs.From(i),model_trans_probs.To(i))=model_trans_probs.Prob(i);
    end
    
    % Initialize model metadata if not done already
    model.metadata_fname=sprintf('metadata_%s.mat',model.name);
    if exist(fullfile(model.path, model.metadata_fname),'file')~=2 || params.reinit_metadata
        init_model_metadata(model);
    end
    load(fullfile(model.path, model.metadata_fname));
    model.metadata=metadata;    
end
    