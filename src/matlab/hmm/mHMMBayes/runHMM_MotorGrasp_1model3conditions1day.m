% 1 model with 3 conditions per day

dbstop if error
addpath('../..');
exp_info=init_exp_info();

%select all the parameters
subject='betta';
array='F1';
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};
% dates={'27.02.19','28.02.19','04.03.19','01.03.19','05.03.19','07.03.19',...
% '08.03.19','11.03.19','13.03.19','14.03.19','15.03.19','19.03.19','20.03.19','21.03.19','22.03.19','25.03.19',...
% '26.03.19','27.03.19','28.03.19','29.03.19','01.04.19','02.04.19','08.04.19','10.04.19','12.04.19','15.04.19',...
% '17.04.19','18.04.19','19.04.19','23.04.19','24.04.19','26.04.19','03.05.19','13.05.19','17.05.19'};

dates={'27.02.19','28.02.19'};
    
metric='cosine'; %'euclidean','pearson','manhattan','spearman','cosine'
variable='TR'; %'TR','A'

%select bin width
dt=10;

%run a model for each day
for d_idx=1:length(dates)
    date=dates{d_idx};
    
    % if it's the last day of the list stop the script
    if d_idx==length(dates)
      disp('end of the list')
      return
    else
    nextday=dates{d_idx+1};
    end
    
    %creat the output paths for two consecutive days in order to align the second based on the previous one
    output_path_date=fullfile(exp_info.base_output_dir, 'HMM', 'betta', 'grasp', 'daymodel', date, array);
    output_path_nextday=fullfile(exp_info.base_output_dir, 'HMM', 'betta', 'grasp', 'daymodel', nextday, array);
    
    if exist(output_path_date,'dir')~=7
        mkdir(output_path_date);
    end
    
    T = readtable(fullfile(output_path_date, 'aic.csv'));
    minAIC=min(T.aic);
    forward_prob_idx=find(T.aic==minAIC);
    n_states=T.states(forward_prob_idx);
    run_idx=T.run(forward_prob_idx);
    
    if d_idx==1
        model1=load_model(fullfile(path, date, array),sprintf('%dstates_%d',n_states,run_idx));
    else 
        model1=model2;
    end
    
    %get data structure and a csv file
    data=export_data_to_csv(exp_info, subject, array, conditions, nextday, dt, output_path_nextday);
    
    T = readtable(fullfile(output_path_nextday, 'aic.csv'));
    minAIC=min(T.aic);
    forward_prob_idx=find(T.aic==minAIC);
    n_states=T.states(forward_prob_idx);
    run_idx=T.run(forward_prob_idx);
    
    %extract the forward probalities 
    model2=load_model(fullfile(path, nextday, array),sprintf('%dstates_%d',n_states,run_idx));
    
    model2=align_models(model1, model2, metric, variable);
    
    plotHMM_MotorGrasp_1model3conditions1day(data, nextday, conditions, array, model2, metric, variable);
    
end