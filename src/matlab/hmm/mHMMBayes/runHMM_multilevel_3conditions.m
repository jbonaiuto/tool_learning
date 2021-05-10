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

metric='euclidean';
variable='EM';

for cond_idx=1:length(conditions)
    % Create output path if it doesnt exist
    output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
        'motor_grasp', '10w_mHMM', array, conditions{cond_idx});
    if exist(output_path,'dir')~=7
        mkdir(output_path);
    end

    if exist(fullfile(output_path,'data.mat'),'file')~=2
        % Otherwise export to CSV and save
        data=export_data_to_csv(exp_info, subject, array,...
            conditions(cond_idx), dates, dt, output_path);
        save(fullfile(output_path,'data.mat'),'data','-v7.3');
        clear data;
    end

    % Fit the model
    system(sprintf('Rscript ../../../R/hmm/fit_multilevel.R "%s"',...
        strrep(output_path,'\','/')));

    % Load best model (lowest AIC)
    models(cond_idx)=get_best_model(output_path, 'type', 'multilevel');
    
end

for cond_idx=1:length(conditions)
    model=models(cond_idx);
    if cond_idx>1
        model=align_models(models(1), model, metric, variable);
    end
    % Plot forward probs
    output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
       'motor_grasp', '10w_mHMM', array, conditions{cond_idx});
    load(fullfile(output_path,'data.mat'));
    plotHMM_aligned_condition(data, dates, conditions(cond_idx), model);
    
    plot_model_params(model, conditions(cond_idx));
    
    plot_fwd_probs_event_sorted(data, model, conditions, dates);
end
