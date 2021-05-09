function model=get_best_model(output_path, varargin)

% Parse optional arguments
defaults=struct('method','AIC', 'type','condition_covar');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

% Find num states and run with lowest AIC
T = readtable(fullfile(output_path, 'aic_bic.csv'));

if strcmp(params.method,'AIC')
    min_aic=min(T.aic);
    n_states=T.states(find(T.aic==min_aic,1));
    run_idx=T.run(find(T.aic==min_aic,1));
    
    figure();
    plot(T.states,T.aic,'.');
    hold all;
    plot(n_states,min_aic,'or');
    xlabel('# states');
    ylabel('AIC');    
    
elseif strcmp(params.method,'BIC')
    min_bic=min(T.bic(state_rows));
    n_states=T.states(find(T.aic==min_bic,1));
    run_idx=T.run(find(T.aic==min_bic,1));
    
    figure();
    plot(T.states,T.bic,'.');
    hold all;
    plot(n_states,min_bic,'or');
    xlabel('# states');
    ylabel('BIC');
end

% Load model
model_name=sprintf('%dstates_%d',n_states,run_idx);
model=load_model(output_path,model_name, 'type',params.type);