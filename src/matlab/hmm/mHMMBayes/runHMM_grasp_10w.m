dbstop if error
clear all

addpath('../..');
exp_info=init_exp_info();
subject='betta';

array='F1';
%array='F5hand';
%array='46v-12r';
%array='F5mouth';

conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};

%10 weeks model
    dates={'04.03.19','05.03.19'};%,'07.03.19','08.03.19','11.03.19','13.03.19','14.03.19','15.03.19','19.03.19','20.03.19','21.03.19','22.03.19','25.03.19',...
    %'26.03.19','27.03.19','28.03.19','29.03.19','01.04.19','02.04.19','05.04.19','08.04.19','09.04.19','10.04.19','12.04.19','15.04.19','16.04.19',...
    %'17.04.19','18.04.19','19.04.19','23.04.19','24.04.19','26.04.19','03.05.19','07.05.19','09.05.19','13.05.19','15.05.19','16.05.19','17.05.19'};
    
dt=10;

output_path=fullfile(exp_info.base_output_dir, 'HMM', 'betta', 'grasp', '10w_condHMM', array);
if exist(output_path,'dir')~=7
    mkdir(output_path);
end

data=export_data_to_csv_10w(exp_info, subject, array, conditions, dates, dt, output_path);

%system(sprintf('"C:/Program Files/R/R-3.6.1/bin/Rscript" ../../../R/hmm/fit_10w.R "%s"', strrep(output_path,'\','/')));

% T = readtable(fullfile(output_path, 'aic.csv'));
% minAIC=min(T.aic);
% forward_prob_idx=find(T.aic==minAIC);
% n_states=T.states(forward_prob_idx);
% run_idx=T.run(forward_prob_idx);
% 
% plotHMM_aligned_condition_grasp(data, date, conditions, array, fullfile(output_path,sprintf('forward_probs_%dstates_%d.csv',n_states,run_idx)));
