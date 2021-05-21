clear all

addpath('../..');
addpath('../../spike_data_processing');
exp_info=init_exp_info();
subject='betta';

% Array to run model on
array='F1';
%array='F5hand';
%array='46v-12r';
%array='F5mouth';

% Conditions to run on
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};

% Days to run on
dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
    '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19'};


% Load multi-day
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '10w_multiday_condHMM', array);

% Load best model (lowest AIC)
multiday_model=get_best_model(output_path, 'type', 'condition_covar');

% Plot forward probs
load(fullfile(output_path,'data.mat'));
plotHMM_aligned_condition(data, dates, conditions, multiday_model);

plot_fwd_probs_event_sorted(data, multiday_model, conditions, dates)


% Load multilevel
datasets={};
multilevel_models={};

for cond_idx=1:length(conditions)
    % Create output path if it doesnt exist
    output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
        'motor_grasp', '10w_mHMM', array, conditions{cond_idx});
        
    % Load best model (lowest AIC)
    model=get_best_model(output_path, 'type', 'multilevel');
    
    % Align to last model
    aligned_model=align_models([multiday_model], model);
    multilevel_models{cond_idx}=aligned_model;
    
    load(fullfile(output_path,'data.mat'));    
    datasets{cond_idx}=data;
    
    %plotHMM_aligned_condition(data, dates, conditions(cond_idx), aligned_model);
    %plot_fwd_probs_event_sorted(data, aligned_model, conditions(cond_idx), dates)
        
end

plotHMM_aligned_condition_combine_models(datasets, dates, conditions, multilevel_models);



% Single day models
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '10w_singleday_condHMM', array);

datasets={};
singleday_models={};
prev_models=[multiday_model];

%% Run the remaining days
for d_idx=1:length(dates)
    date=dates{d_idx};
    
    day_output_path=fullfile(output_path,date);
    % Load best model (lowest AIC)
    model=get_best_model(day_output_path, 'type', 'condition_covar');
    
    % Align to last model
    aligned_model=align_models(prev_models, model);
    singleday_models{d_idx}=aligned_model;
    
    load(fullfile(day_output_path,'data.mat'));
    datasets{d_idx}=data;
        
    %plotHMM_aligned_condition(data, dates(d_idx), conditions, aligned_model);
    %plot_fwd_probs_event_sorted(data, aligned_model, conditions(cond_idx), dates)
    
    % Align to aligned model in next iteration
    prev_models(end+1)=aligned_model;    
end

plotHMM_aligned_condition_combine_days(datasets, dates,conditions, singleday_models);