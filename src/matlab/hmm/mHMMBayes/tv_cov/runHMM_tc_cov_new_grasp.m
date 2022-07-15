%runHMM_tc_cov_new_grasp(exp_info, subject, array)

addpath('../../..');
addpath('../../../spike_data_processing');

exp_info=init_exp_info();
subject='betta';
array='F1';

% Conditions to run on
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};

if strcmp(subject,'betta')
    dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
       '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19'};
%    dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19','05.03.19','07.03.19','08.03.19','11.03.19','12.03.19','13.03.19','14.03.19','15.03.19','18.03.19',...
%       '19.03.19','20.03.19','21.03.19','25.03.19','26.03.19','27.03.19','28.03.19','29.03.19','01.04.19','02.04.19','03.04.19','05.04.19','08.04.19','09.04.19',...
%       '10.04.19','12.04.19','15.04.19','16.04.19','17.04.19','18.04.19','19.04.19','23.04.19','24.04.19','26.04.19','03.05.19','07.05.19','09.05.19','14.05.19',...
%       '15.05.19','16.05.19','17.05.19','20.05.19','21.05.19','22.05.19','23.05.19','13.06.19','14.06.19','19.06.19','25.06.19','26.06.19','28.06.19','01.07.19',...
%       '02.07.19','03.07.19','04.07.19','05.07.19','08.07.19','11.07.19','12.07.19','15.07.19','17.07.19','18.07.19','19.07.19','22.07.19','23.07.19','24.07.19',...
%       '26.07.19','29.07.19','31.07.19','01.08.19','02.08.19','05.08.19','06.08.19','07.08.19','09.08.19','27.08.19','28.08.19','29.08.19','04.09.19','05.09.19',...
%       '06.09.19','09.09.19','10.09.19','12.09.19','18.09.19','25.09.19','27.09.19','04.10.19','07.10.19','08.10.19','10.10.19','11.10.19','14.10.19','16.10.19',...
%       '17.10.19','18.10.19','22.10.19','28.10.19','29.10.19','04.11.19','06.11.19','14.11.19','20.11.19','21.11.19','25.11.19'};
   
   
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

% if exist(fullfile(output_path,'data.mat'),'file')~=2
%     %Otherwise export to CSV and save
%     data=export_data_to_csv(exp_info, subject, array, conditions, dates,...
%         dt, output_path, electrodes);
%     save(fullfile(output_path,'data.mat'),'data','-v7.3');
%     clear data;
% end
% 
% % Fit the model
% system(sprintf('/home/bonaiuto/miniconda3/envs/hmm/bin/Rscript ../../../../R/hmm/fit_plnorm_tv_covar_new.R "%s"',...
%      strrep(output_path,'\','/')));

% Load best model (lowest AIC)
model=get_best_model(output_path, 'type', 'plnorm');
load(fullfile(output_path,'data.mat'));

plotHMM_aligned_condition(subject, array, data, dates, conditions, model,output_path);
plot_fwd_probs_event_sorted(subject, array, data, model, dates,output_path);


plot_model_params(subject, array, model, conditions,output_path);

run_state_trial_stats(model, data, dates, conditions);

run_perm_test_events(subject, array, data, model, conditions, dates, output_path);

system(sprintf('"C:/Program Files/R/R-4.1.3/bin/Rscript" ../../../R/hmm/shuffle_electrode_plnorm_tv_covar_new.R "%s" %d 1',...
    strrep(output_path,'\','/'), model.n_states));


plotHMM_aligned_condition_elec_shuffled(subject, array, data, dates, conditions, model,output_path);
plot_fwd_probs_event_sorted_elec_shuffled(subject, array, data, model, dates,output_path);

system(sprintf('"C:/Program Files/R/R-4.1.3/bin/Rscript" ../../../../R/hmm/shuffle_temp_plnorm_tv_covar_new.R "%s" %d 1',...
    strrep(output_path,'\','/'), model.n_states));

plotHMM_aligned_condition_temp_shuffled(data, dates, conditions, model);
plot_fwd_probs_event_sorted_temp_shuffled(data, model, dates);

system(sprintf('/home/bonaiuto/miniconda3/envs/hmm/bin/Rscript ../../../../R/hmm/analyze_covars.R "%s" %s',...
    strrep(output_path,'\','/'), model.fname));

