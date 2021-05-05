function model=get_best_model(output_path, varargin)

% Parse optional arguments
defaults=struct('method','AIC+BIC', 'type','condition_covar');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

% Find num states and run with lowest AIC
T = readtable(fullfile(output_path, 'aic_bic.csv'));
minAIC=min(T.aic);
minBIC=min(T.bic);
minAICBIC=min(T.aic+T.bic);

if strcmp(params.method,'AIC')
    forward_prob_idx=find(T.aic==minAIC);
elseif strcmp(params.method,'BIC')
    forward_prob_idx=find(T.bic==minBIC);
else
    forward_prob_idx=find(T.aic+T.bic==minAICBIC);
end
n_states=T.states(forward_prob_idx);
run_idx=T.run(forward_prob_idx);

% Load model
model_name=sprintf('%dstates_%d',n_states,run_idx);
model=load_model(output_path,model_name, 'type',params.type);