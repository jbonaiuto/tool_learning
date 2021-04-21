function model=get_best_model(output_path)

% Find num states and run with lowest AIC
T = readtable(fullfile(output_path, 'aic.csv'));
minAIC=min(T.aic);
forward_prob_idx=find(T.aic==minAIC);
n_states=T.states(forward_prob_idx);
run_idx=T.run(forward_prob_idx);

% Load model
model_name=sprintf('%dstates_%d',n_states,run_idx);
model=load_model(output_path,model_name);