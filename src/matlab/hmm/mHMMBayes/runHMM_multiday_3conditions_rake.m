clear all

addpath('../..');
addpath('../../spike_data_processing');
exp_info=init_exp_info();
subject='betta';
%subject='samovar';

% Array to run model on
 array='F1';
%array='F5hand';
%array='46v-12r';
%array='F5mouth';

% Conditions to run on
%conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};
conditions={'motor_rake_center','motor_rake_right','motor_rake_left'};

% Days to run on
% dates={'11.06.21','15.06.21','16.06.21','17.06.21','22.06.21',...
%      '23.06.21','25.06.21','29.06.21','30.06.21'};
dates={'09.05.19','14.05.19'};

 
%dates={'18.05.21','19.05.21','20.05.21','21.05.21','25.05.21',...
%     '26.05.21','27.05.21','01.06.21','03.06.21','04.06.21'};

% dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
%    '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19',...
%    '13.03.19','14.03.19','15.03.19','18.03.19','19.03.19',...
%    '20.03.19','21.03.19','25.03.19'};

% Create output path if it doesnt exist
%output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
%     'motor_grasp', '10d_multiday_condHMM_18052021', array);
%output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
%   'motor_grasp', '5w_multiday_condHMM', array);
 output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_rake', 'mayday2_condHMM', array);

% 10ms bins
dt=10;
%dt=1;


if exist(output_path,'dir')~=7
    mkdir(output_path);
end



%if exist(fullfile(output_path,'data.mat'),'file')~=2
    % Otherwise export to CSV and save
    data=export_data_to_csv(exp_info, subject, array, conditions, dates,...
        dt, output_path);
    save(fullfile(output_path,'data.mat'),'data','-v7.3');
    %clear data;
%end

load(fullfile(output_path,'data.mat'));
% Fit the model
% system(sprintf('Rscript ../../../R/hmm/fit_condition_covar.R "%s"',...
%      strrep(output_path,'\','/')));

% Load best model (lowest AIC)
model=get_best_model(output_path, 'type', 'condition_covar');
load(fullfile(output_path,'model.mat'));
model.path=output_path;

% Plot forward probs
load(fullfile(output_path,'data.mat'));
plotHMM_aligned_condition(data, dates, conditions, model);
%plotHMM_aligned_condition_onetrial(data, dates, conditions, model);
%plotHMM_aligned_condition_rake(data, dates, conditions, model);

plot_model_params(model, conditions);

plot_fwd_probs_event_sorted(data, model, conditions, dates);