clear all

addpath('../../..');
addpath('../../../spike_data_processing');
exp_info=init_exp_info();
subject='betta';

% Array to run model on
array='F1';
%array='F5hand';
%F5hand good channel sample:
%1,2,3,4,5,6,7,8,11,12,14,15,16,19,21,22,23,24,25,26,27,28,29,30,31,32

%good channels sample
% for F1
electrodes=[1 2 3 5 6 7 9 10 13 14 17 18 21 25 26 27 28 29 30 31 32];

% Conditions to run on
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};

dates={'11.03.19','12.03.19',...
   '13.03.19','14.03.19','15.03.19','18.03.19','19.03.19',...
   '20.03.19','21.03.19','25.03.19'};

% Create output path if it doesnt exist
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
     'motor_grasp', 'tv_cov', array);


% 10ms bins
dt=10;


if exist(output_path,'dir')~=7
    mkdir(output_path);
end

if exist(fullfile(output_path,'data.mat'),'file')~=2
    %Otherwise export to CSV and save
    data=export_data_to_csv(exp_info, subject, array, conditions, dates,...
        dt, output_path, electrodes);
    save(fullfile(output_path,'data.mat'),'data','-v7.3');
    clear data;
end

% Fit the model
system(sprintf('Rscript ../../../../R/hmm/fit_tv_covar.R "%s"',...
     strrep(output_path,'\','/')));

% Load best model (lowest AIC)
model=get_best_model(output_path, 'type', 'pgamma');


% Plot forward probs
load(fullfile(output_path,'data.mat'));
%plotHMM_aligned_condition(data, dates, conditions, model);
%plotHMM_aligned_condition_onetrial(data, dates, conditions, model);

plotHMM_aligned_condition_OneWindow(data, dates, conditions, model);

%plot_model_params(model, conditions);

%plot_fwd_probs_event_sorted(data, model, conditions, dates, output_path);

%run_state_trial_stats(subject, array, model, data, dates, conditions, output_path);

%run_perm_test_events(data, model, conditions, dates, threshold, dur_thresh);