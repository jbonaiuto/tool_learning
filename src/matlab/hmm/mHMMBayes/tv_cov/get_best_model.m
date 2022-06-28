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
T = readtable(fullfile(output_path, sprintf('%s_aic_bic.csv',params.type)));

aic=T.aic;
bic=T.bic;
states=T.states;
run=T.run;

if strcmp(params.method,'AIC')
    min_aic=min(aic);
    n_states=states(find(aic==min_aic,1));
    run_idx=run(find(aic==min_aic,1));
    
    if params.plot
        figure();
        plot(states,aic-max(aic),'.');
        hold all;
        plot(n_states,min_aic-max(aic),'or');
        mean_per_n_states=[];
        for i=min(states):max(states)
            rows=find(states==i);
            mean_per_n_states(end+1)=mean(aic(rows)-max(aic));
        end
        plot(min(states):max(states),mean_per_n_states,'og');
        xlim([min(states)-1 max(states)+1]);
        xlabel('# states');
        ylabel('\Delta AIC');    
    end
    
elseif strcmp(params.method,'BIC')
    min_bic=min(bic);
    n_states=states(find(bic==min_bic,1));
    run_idx=run(find(bic==min_bic,1));
    
    if params.plot
        figure();
        plot(states,bic-max(bic),'.');
        hold all;
        plot(n_states,min_bic-max(bic),'or');
        mean_per_n_states=[];
        for i=min(states):max(states)
            rows=find(states==i);
            mean_per_n_states(end+1)=mean(bic(rows)-max(bic));
        end
        plot(min(states):max(states),mean_per_n_states,'og');
        xlim([min(states)-1 max(states)+1]);
        xlabel('# states');
        ylabel('\Delta BIC');
    end
end

% Load model
model_name=sprintf('%s_%dstates_%d',params.type,n_states,run_idx);
model=load_model(output_path,model_name, 'type',params.type);
