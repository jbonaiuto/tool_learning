dbstop if error
%clear all

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

metric='euclidean';
variable='TR';

% Create output path if it doesnt exist
output_path=fullfile(exp_info.base_output_dir, 'HMM', 'betta',...
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
if exist(fullfile(day_output_path,'data.mat'),'file')==2
    % Load data if already exists
    load(fullfile(day_output_path,'data.mat'));
else
    % Otherwise export to CSV and save
    data=export_data_to_csv(exp_info, subject, array, conditions,...
        dates(1), dt, day_output_path);
    save(fullfile(day_output_path,'data.mat'),'data','-v7.3');
end

% Fit the model
system(sprintf('"C:/Program Files/R/R-3.6.1/bin/Rscript" ../../../R/hmm/fit_condition_covar.R "%s"',...
    strrep(day_output_path,'\','/')));

% Load best model (lowest AIC)
last_model=get_best_model(day_output_path);

% Plot forward probs
<<<<<<< HEAD
plotHMM_aligned_condition(data, dates(1), conditions, last_model, array, subject);
=======
plotHMM_aligned_condition(data, dates(1), conditions, last_model,...
    'type', 'condition_covar');
>>>>>>> 40f203dae49bc6a1d17ca9b765bf5d500c2d875f

%% Run the remaining days
for d_idx=2:length(dates)
    date=dates{d_idx};
    
    day_output_path=fullfile(output_path,date);
    if exist(day_output_path,'dir')~=7
        mkdir(day_output_path);
    end
    if exist(fullfile(day_output_path,'data.mat'),'file')==2
        % Load data if already exists
        load(fullfile(day_output_path,'data.mat'));
    else
        % Otherwise export to CSV and save
        data=export_data_to_csv(exp_info, subject, array, conditions,...
            dates(d_idx), dt, day_output_path);
        save(fullfile(day_output_path,'data.mat'),'data','-v7.3');
    end

    % Fit the model
    system(sprintf('"C:/Program Files/R/R-3.6.1/bin/Rscript" ../../../R/hmm/fit_condition_covar.R "%s"',...
        strrep(day_output_path,'\','/')));
    
    % Load best model (lowest AIC)
    model=get_best_model(day_output_path);
    
    % Align to last model
    aligned_model=align_models(last_model, model, metric, variable);
    
    % Plot forward probs
    [aligned_forward_probs,f]=plotHMM_aligned_condition(data, dates(d_idx), conditions, aligned_model,...
        'type', 'condition_covar');

    saveas(f,fullfile(day_output_path, [model.name '_forward_probs.png']));
    saveas(f,fullfile(day_output_path, [model.name '_forward_probs.eps']), 'epsc');

    % Align to aligned model in next iteration
    last_model=aligned_model;    
end