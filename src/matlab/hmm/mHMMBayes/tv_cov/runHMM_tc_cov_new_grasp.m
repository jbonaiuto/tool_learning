%runHMM_tc_cov_new_grasp

addpath('../../..');
addpath('../../../spike_data_processing');

exp_info=init_exp_info();
subject='betta';%'betta'  'samovar'
array='F1';% 'F1'  'F5hand' 'F5mouth','46v-12r', '45a', 'F2'

% Conditions to run on
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};

if strcmp(subject,'betta')
    dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
       '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19'};
   
    %good channels sample
    % for F1
    if strcmp(array, 'F1')
        electrodes=[1 2 3 5 6 7 9 10 13 14 17 18 21 25 26 27 28 29 30 31 32];
    % For F5hand
    elseif strcmp(array,'F5hand')
        electrodes=[1 3 4 6 11 12 19 21 22 23 27 28 29 30 31 32];
    end
elseif strcmp(subject,'samovar')
    dates={'21.04.21', '22.04.21', '28.04.21', '29.04.21', '30.04.21',...
        '04.05.21', '06.05.21', '07.05.21', '11.05.21', '14.05.21'};
    %good channels sample
    % for F1
    if strcmp(array, 'F1')
        electrodes=[4 5 6 7 9 10 11 13 14 15 16 17 18 19 20 21 22 23 25 26 27 28 29 30 31];
    end
end

% Create output path if it doesnt exist
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
     'motor_grasp', 'tv_cov_new', array);

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
% system(sprintf('/home/bonaiuto/miniconda3/envs/hmm/bin/Rscript ../../../../R/hmm/fit_plnorm_tv_covar_new.R "%s"',...
%      strrep(output_path,'\','/')));

% Load best model (lowest AIC)
model=get_best_model(output_path, 'type', 'plnorm');
load(fullfile(output_path,'data.mat'));

plotHMM_onetrial_raster(subject, array, electrodes, data, dates, conditions, model, output_path);

plotHMM_aligned(model, data);
plot_fwd_probs_event_sorted(subject, array, data, model, dates,output_path);

PSTH_OnOff_MostLikelyStateSequence(model,electrodes,data)

plot_model_params(model, conditions);

run_state_trial_stats(model, data, dates, conditions, output_path);

run_perm_test_events(data, model, dates)

system(sprintf('/home/bonaiuto/miniconda3/envs/hmm/bin/Rscript ../../../../R/hmm/shuffle_electrode_plnorm_tv_covar_new.R "%s" %d 1',...
    strrep(output_path,'\','/'), model.n_states));

plotHMM_aligned_elec_shuffled(model, data)
plot_fwd_probs_event_sorted_elec_shuffled(subject, array, data, model, dates,output_path);

system(sprintf('/home/bonaiuto/miniconda3/envs/hmm/bin/Rscript ../../../../R/hmm/shuffle_temp_plnorm_tv_covar_new.R "%s" %d 1',...
    strrep(output_path,'\','/'), model.n_states));

plotHMM_aligned_temp_shuffled(model, data)
plot_fwd_probs_event_sorted_temp_shuffled(subject, array, data, model, dates,output_path);

system(sprintf('/home/bonaiuto/miniconda3/envs/hmm/bin/Rscript ../../../../R/hmm/analyze_covars.R "%s" %s',...
    strrep(output_path,'\','/'), model.fname));

export_kinematics(data, output_path)

plot_kinematics(data)

run_perm_test_events_temp_shuffled(data, model)
run_perm_test_events_elec_shuffled(data, model)