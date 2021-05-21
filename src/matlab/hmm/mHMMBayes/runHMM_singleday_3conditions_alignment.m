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

% 10ms bins
dt=10;

% Create output path if it doesnt exist
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '10w_singleday_condHMM', array);
if exist(output_path,'dir')~=7
    mkdir(output_path);
end

%% Run the first day
last_date=dates{1};
day_output_path=fullfile(output_path,dates{1});
if exist(day_output_path,'dir')~=7
    mkdir(day_output_path);
end
if exist(fullfile(day_output_path,'data.mat'),'file')~=2
    % Otherwise export to CSV and save
    data=export_data_to_csv(exp_info, subject, array, conditions,...
        dates(1), dt, day_output_path);
    save(fullfile(day_output_path,'data.mat'),'data','-v7.3');
    clear data;
end

% Fit the model
system(sprintf('Rscript ../../../R/hmm/fit_condition_covar.R "%s"',...
    strrep(day_output_path,'\','/')));

% Load best model (lowest AIC)
model=get_best_model(day_output_path, 'type', 'condition_covar');
prev_models=[model];

% Plot forward probs
load(fullfile(day_output_path,'data.mat'));
[aligned_forward_probs,f]=plotHMM_aligned_condition(data, dates(1),...
    conditions, model);
saveas(f,fullfile(day_output_path, [model.name '_forward_probs.png']));
saveas(f,fullfile(day_output_path, [model.name '_forward_probs.eps']), 'epsc');
    
%% Run the remaining days
for d_idx=2:length(dates)
    date=dates{d_idx};
    
    day_output_path=fullfile(output_path,date);
    if exist(day_output_path,'dir')~=7
        mkdir(day_output_path);
    end
    if exist(fullfile(day_output_path,'data.mat'),'file')~=2
        % Otherwise export to CSV and save
        data=export_data_to_csv(exp_info, subject, array, conditions,...
            dates(d_idx), dt, day_output_path);
        save(fullfile(day_output_path,'data.mat'),'data','-v7.3');
        clear data;
    end

    % Fit the model
    system(sprintf('Rscript ../../../R/hmm/fit_condition_covar.R "%s"',...
        strrep(day_output_path,'\','/')));
    
    % Load best model (lowest AIC)
    model=get_best_model(day_output_path, 'type', 'condition_covar');
    
    % Align to last model
    aligned_model=align_models(prev_models, model);
    
    % Plot forward probs
    load(fullfile(day_output_path,'data.mat'));
    [aligned_forward_probs,f]=plotHMM_aligned_condition(data, dates(d_idx),...
        conditions, aligned_model);

    saveas(f,fullfile(day_output_path, [aligned_model.name '_forward_probs.png']));
    saveas(f,fullfile(day_output_path, [aligned_model.name '_forward_probs.eps']), 'epsc');

    % Align to aligned model in next iteration
    prev_models(end+1)=aligned_model;    
end
