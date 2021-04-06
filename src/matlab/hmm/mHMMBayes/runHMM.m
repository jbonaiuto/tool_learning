dbstop if error
clear all

addpath('../..');
exp_info=init_exp_info();
subject='betta';
array='F1';
%array='F5hand';
conditions={'motor_grasp_right'};
%conditions={'motor_grasp_left'};
%conditions={'motor_grasp_center'};
%conditions={'motor_grasp_right','motor_grasp_left','motor_grasp_center'};

dates={'14.02.19','18.02.19','19.02.19','20.02.19','21.02.19','25.02.19','26.02.19','27.02.19','28.02.19','04.03.19','01.03.19','05.03.19','07.03.19',...
    '08.03.19','11.03.19','13.03.19','14.03.19','15.03.19','19.03.19','20.03.19','21.03.19','22.03.19','25.03.19',...
    '26.03.19','27.03.19','28.03.19','29.03.19','01.04.19','02.04.19','05.04.19','08.04.19','09.04.19','10.04.19','12.04.19','15.04.19','16.04.19',...
    '17.04.19','18.04.19','19.04.19','23.04.19','24.04.19','26.04.19','03.05.19','07.05.19','09.05.19','13.05.19','15.05.19','17.05.19','20.05.19','21.05.19'};

%problematic days: '08.03.19'

%week4 (stage 1)
    %dates={'04.03.19','05.03.19','07.03.19','08.03.19'};
%week5 
    %dates={'13.03.19','14.03.19','15.03.19'};
    %dates={'11.03.19','12.03.19','13.03.19','14.03.19','15.03.19'};
%week6
    %dates={'19.03.19','20.03.19','21.03.19'};
    %dates={'19.03.19','20.03.19','21.03.19','22.03.19'};
%week7 
    %dates={'25.03.19','26.03.19'};
%week8 (stage 2)
    %dates={'27.03.19','28.03.19','29.03.19'};
%week7&8
    %dates={'25.03.19','26.03.19','27.03.19','28.03.19','29.03.19'};

dt=10;

output_path=fullfile(exp_info.base_output_dir, 'HMM', 'betta', 'grasp', 'mHMM', array, conditions);
if exist(output_path,'dir')~=7
    mkdir(output_path);
end


%data=export_data_to_csv(exp_info, subject, array, conditions, dates, dt);
data=export_data_to_csv_10w(exp_info, subject, array, conditions, dates, dt, output_path);

%system('"C:\Program Files\R\R-3.6.1\bin\Rscript" ../../../R/hmm/fit.R');
%system(sprintf('"C:/Program Files/R/R-3.6.1/bin/Rscript" ../../../R/hmm/days_mHMMfit.R "%s"', strrep(output_path,'\','/')));

T = readtable(fullfile(output_path,'aic.csv'));
minAIC=min(T.aic);
forward_prob_idx=find(T.aic==minAIC);
n_states=T.states(forward_prob_idx);
run_idx=T.run(forward_prob_idx);

%plotHMM_aligned(data, dates, conditions, sprintf('forward_probs_%dstates_%d.csv',n_states,run_idx));
%plotHMM_aligned(data, dates, conditions, sprintf('forward_probs_%d.csv',forward_prob_Idx));
plotHMM_aligned(data, dates, conditions, fullfile(output_path,sprintf('forward_probs_%dstates_%d.csv',n_states,run_idx)));

% n_runs=10;
% for i=1:n_runs
%     plotHMM_aligned(data, dates, conditions, sprintf('forward_probs_%d.csv',i));
% end
