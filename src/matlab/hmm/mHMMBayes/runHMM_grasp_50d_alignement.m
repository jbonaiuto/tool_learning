dbstop if error
%clear all

addpath('../..');
exp_info=init_exp_info();
subject='betta';
array='F1';

metric='euclidean';
variable='TR';

conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};


dates={'27.02.19','28.02.19','04.03.19','01.03.19','05.03.19','07.03.19',...
'08.03.19','11.03.19','13.03.19','14.03.19','15.03.19','19.03.19','20.03.19','21.03.19','22.03.19','25.03.19',...
'26.03.19','27.03.19','28.03.19','29.03.19','01.04.19','02.04.19','08.04.19','10.04.19','12.04.19','15.04.19',...
'17.04.19','18.04.19','19.04.19','23.04.19','24.04.19','26.04.19','03.05.19','13.05.19','17.05.19','21.05.19'};
%dates={'01.03.19','05.03.19','07.03.19','08.03.19'};

path='E:\project\tool_learning\data\output\HMM\betta\grasp\50_models\';

dt=10;

for d_idx=1:length(dates)
    date=dates{d_idx};
    
    if d_idx==length(dates)
      disp('end of the list')
      return
    else
    nextday=dates{d_idx+1};
    end
    
    output_path_date=fullfile(exp_info.base_output_dir, 'HMM', 'betta', 'grasp', '50_models', date, array);
    output_path_nextday=fullfile(exp_info.base_output_dir, 'HMM', 'betta', 'grasp', '50_models', nextday, array);
    
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
    
    data=export_data_to_csv(exp_info, subject, array, conditions, nextday, dt, output_path_nextday);
    T = readtable(fullfile(output_path_nextday, 'aic.csv'));
    minAIC=min(T.aic);
    forward_prob_idx=find(T.aic==minAIC);
    n_states=T.states(forward_prob_idx);
    run_idx=T.run(forward_prob_idx);
    
    model2=load_model(fullfile(path, nextday, array),sprintf('%dstates_%d',n_states,run_idx));
   
    
    
    model2=align_models(model1, model2, metric, variable);
    
    plotHMM_model_aligned(data, nextday, conditions, array, model2);
    
end