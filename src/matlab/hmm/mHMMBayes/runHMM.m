dbstop if error
clear all

addpath('../..');
exp_info=init_exp_info();
subject='betta';
%array='F1';
array='F5hand';
conditions={'motor_grasp_right'};
%conditions={'motor_grasp_left'};
%conditions={'motor_grasp_center'};
%conditions={'motor_grasp_right','motor_grasp_left','motor_grasp_center'};

%week4 (stage 1)
    dates={'04.03.19','05.03.19','07.03.19','08.03.19'};
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

data=export_data_to_csv(exp_info, subject, array, conditions, dates, dt);

system('"C:\Program Files\R\R-3.6.1\bin\Rscript" ../../../R/hmm/fit.R');

T = readtable('aic.csv');
minAIC=min(T.aic);
forward_prob_idx=find(T.aic==minAIC);
n_states=T.states(forward_prob_idx);
run_idx=T.run(forward_prob_idx);

plotHMM_aligned(data, dates, conditions, sprintf('forward_probs_%dstates_%d.csv',n_states,run_idx));
%plotHMM_aligned(data, dates, conditions, sprintf('forward_probs_%d.csv',forward_prob_Idx));

% n_runs=10;
% for i=1:n_runs
%     plotHMM_aligned(data, dates, conditions, sprintf('forward_probs_%d.csv',i));
% end
