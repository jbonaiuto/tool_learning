function model=get_model(exp_info, subject, model_name, varargin)

% Parse optional arguments
defaults=struct('n_states',[],'method','AIC+BIC');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

file_name=fullfile(exp_info.base_output_dir, 'HMM', subject, model_name, 'hmm_results.mat');
load(file_name);
hmm_results = model_comparison(exp_info, hmm_results, model_name,'method',params.method);
if length(params.n_states)==0
    model=hmm_results.models(hmm_results.best_model_idx(1),hmm_results.best_model_idx(2));
else
    idx=find(hmm_results.n_state_possibilities==params.n_states);
    model=hmm_results.models(idx,hmm_results.maxLL_idx_storing(idx));
end
