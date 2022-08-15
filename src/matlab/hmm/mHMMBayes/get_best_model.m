function model=get_best_model(output_path, varargin)

% Parse optional arguments
defaults=struct('method','AIC', 'type','condition_covar', 'plot', false);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

% Find num states and run with lowest AIC
T = readtable(fullfile(output_path, 'plnorm_aic_bic.csv'));

if strcmp(params.method,'AIC')
    min_aic=min(T.aic);
    n_states=T.states(find(T.aic==min_aic,1));
    run_idx=T.run(find(T.aic==min_aic,1));
    
    if params.plot
        figure();
        plot(T.states,T.aic-max(T.aic),'.');
        hold all;
        plot(n_states,min_aic-max(T.aic),'or');
        mean_per_n_states=[];
        for i=min(T.states):max(T.states)
            rows=find(T.states==i);
            mean_per_n_states(end+1)=mean(T.aic(rows)-max(T.aic));
        end
        plot(min(T.states):max(T.states),mean_per_n_states,'og');
        xlim([min(T.states)-1 max(T.states)+1]);
        xlabel('# states');
        ylabel('\Delta AIC');    
    end
    
elseif strcmp(params.method,'BIC')
    min_bic=min(T.bic);
    n_states=T.states(find(T.bic==min_bic,1));
    run_idx=T.run(find(T.bic==min_bic,1));
    
    if params.plot
        figure();
        plot(T.states,T.bic-max(T.bic),'.');
        hold all;
        plot(n_states,min_bic-max(T.bic),'or');
        mean_per_n_states=[];
        for i=min(T.states):max(T.states)
            rows=find(T.states==i);
            mean_per_n_states(end+1)=mean(T.bic(rows)-max(T.bic));
        end
        plot(min(T.states):max(T.states),mean_per_n_states,'og');
        xlim([min(T.states)-1 max(T.states)+1]);
        xlabel('# states');
        ylabel('\Delta BIC');
    end
end

% Load model
model_name=sprintf('%dstates_%d',n_states,run_idx);
model=load_model(output_path, model_name, 'type',params.type);