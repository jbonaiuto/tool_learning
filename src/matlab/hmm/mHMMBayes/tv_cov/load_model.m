function model=load_model(model_path, model_name, varargin)

%define default values
defaults = struct('reinit_metadata',false, 'type','condition_covar');  
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
model.fname=sprintf('model_tv_%s.rda',model.name);
model.type=params.type;

% If model file from R exists
if exist(fullfile(model.path, model.fname),'file')==2
    
    % Load forward probabilities
    model.forward_probs_fname=sprintf('forward_probs_tv_%s.csv',model.name);
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
    
    % Initialize model metadata if not done already
    model.metadata_fname=sprintf('metadata_tv_%s.mat',model.name);
    if exist(fullfile(model.path, model.metadata_fname),'file')~=2 || params.reinit_metadata
        init_model_metadata(model);
    end
    load(fullfile(model.path, model.metadata_fname));
    model.metadata=metadata;  

    % Export transition probabilities if not done already
    model.trans_probs_fname=sprintf('trans_probs_tv_%s.csv',model.name);
    if exist(fullfile(model.path, model.trans_probs_fname),'file')~=2
        system(sprintf('Rscript ../../../../R/hmm/extract_transition_probs.R "%s" "%s"', fullfile(model.path,model.fname),...
            fullfile(model.path,model.trans_probs_fname)));
    end
    % Load transition probabilities
    model_trans_probs=readtable(fullfile(model.path, model.trans_probs_fname));
    model.trans_mat=zeros(model.n_states,model.n_states);
    for i=1:size(model_trans_probs)
        model.trans_mat(model_trans_probs.From(i),model_trans_probs.To(i))=model_trans_probs.Prob(i);
    end
    
    if strcmp(model.type,'condition_covar')
        % Export condition covariates if not done already
        model.cond_trans_covs_fname=sprintf('cond_trans_covs_%s.csv',model.name);        
        if exist(fullfile(model.path, model.cond_trans_covs_fname),'file')~=2
	    system(sprintf('Rscript ../../../../R/hmm/extract_condition_transition_covs.R "%s" "%s" "%s"', fullfile(model.path,model.fname),...
                fullfile(model.path,model.cond_trans_covs_fname), model.path));
        end
        % Load condition covariates
        model_cond_trans_covs=readtable(fullfile(model.path, model.cond_trans_covs_fname));
        model.metadata.conditions=unique(model_cond_trans_covs.Cov);
        model.cond_trans_cov_med_mat=zeros(length(model.metadata.conditions),model.n_states,model.n_states);
        model.cond_trans_cov_cci_upr_mat=zeros(length(model.metadata.conditions),model.n_states,model.n_states);
        model.cond_trans_cov_cci_lwr_mat=zeros(length(model.metadata.conditions),model.n_states,model.n_states);
        for i=1:size(model_cond_trans_covs)
	    cond_idx=find(strcmp(model.metadata.conditions,model_cond_trans_covs.Cov{i}));
	    model.cond_trans_cov_med_mat(cond_idx,model_cond_trans_covs.From(i),model_cond_trans_covs.To(i))=model_cond_trans_covs.MedVal(i);
	    model.cond_trans_cov_cci_upr_mat(cond_idx,model_cond_trans_covs.From(i),model_cond_trans_covs.To(i))=model_cond_trans_covs.CCI_upr(i);
	    model.cond_trans_cov_cci_lwr_mat(cond_idx,model_cond_trans_covs.From(i),model_cond_trans_covs.To(i))=model_cond_trans_covs.CCI_lwr(i);
	end
    end
    
    % Export emission probabilities if not done already
    model.emiss_probs_fname=sprintf('emiss_probs_tv_%s.csv',model.name);
    if exist(fullfile(model.path, model.emiss_probs_fname),'file')~=2
        system(sprintf('Rscript ../../../../R/hmm/extract_emission_probs.R "%s" "%s"', fullfile(model.path,model.fname),...
            fullfile(model.path,model.emiss_probs_fname)));
    end
    % Load emission probabilities
    model_emiss_probs=readtable(fullfile(model.path, model.emiss_probs_fname));
    model.emiss_alpha_mat=zeros(model.n_states,length(unique(model_emiss_probs.Electrode)));
    model.emiss_beta_mat=zeros(model.n_states,length(unique(model_emiss_probs.Electrode)));
    for i=1:size(model_emiss_probs)
        model.emiss_alpha_mat(model_emiss_probs.State(i),model_emiss_probs.Electrode(i))=model_emiss_probs.Alpha(i);
        model.emiss_beta_mat(model_emiss_probs.State(i),model_emiss_probs.Electrode(i))=model_emiss_probs.Beta(i);
    end
    
    
    
      
end
    