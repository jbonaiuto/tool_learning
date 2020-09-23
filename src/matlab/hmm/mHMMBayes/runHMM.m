addpath('../..');
exp_info=init_exp_info();
subject='betta';
array='F1';
conditions={'motor_grasp_right'};
dates={'13.03.19','14.03.19','15.03.19'};
dt=1;

data=export_data_to_csv(exp_info, subject, array, conditions, dates, dt);

system('../../../R/hmm/fit.R');

plotHMM_aligned(data, dates, conditions, 'forward_probs.csv');