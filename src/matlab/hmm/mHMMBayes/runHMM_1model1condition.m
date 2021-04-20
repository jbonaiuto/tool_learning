% 1 model with 1 condition over multiple days

dbstop if error
clear all
addpath('../..');
exp_info=init_exp_info();

%select all the parameters
subject='betta';
array='F5hand';
conditions={'motor_grasp_right'};
dates={'14.02.19','18.02.19','19.02.19','20.02.19','26.02.19','27.02.19','28.02.19','04.03.19','01.03.19','05.03.19','07.03.19',...
    '08.03.19','11.03.19','13.03.19','14.03.19','15.03.19','19.03.19','20.03.19','21.03.19','22.03.19','25.03.19',...
    '26.03.19','27.03.19','28.03.19','29.03.19','01.04.19','02.04.19','05.04.19','08.04.19','10.04.19','12.04.19','15.04.19','16.04.19',...
    '17.04.19','18.04.19','19.04.19','23.04.19','24.04.19','26.04.19','03.05.19','13.05.19','15.05.19','17.05.19','20.05.19','21.05.19'};

%select bin width
dt=10;

%creat the output path
output_path=fullfile(exp_info.base_output_dir, 'HMM', 'betta', 'grasp', 'mHMM', array, strjoin(conditions,'_'));
if exist(output_path,'dir')~=7
    mkdir(output_path);
end


%get a concatenated data structure (gathering each day data structure) and a csv file with date, trial, condition, electrode, timestep, value headers
data=export_data_to_csv_10w(exp_info, subject, array, conditions, dates, dt, output_path);

%get the forward probability csv file and the model rda file calling RStudio
system(sprintf('"C:/Program Files/R/R-3.6.1/bin/Rscript" ../../../R/hmm/days_mHMMfit.R "%s"', strrep(output_path,'\','/')));

%Select the forward_prob file base on the Akaike information criterion
T = readtable(fullfile(output_path,'aic.csv'));
minAIC=min(T.aic);
forward_prob_idx=find(T.aic==minAIC);
n_states=T.states(forward_prob_idx);
run_idx=T.run(forward_prob_idx);

%plot the HMM states sequence 
plotHMM_1model1condition(exp_info, array, data, dates, conditions, fullfile(output_path,sprintf('forward_probs_%dstates_%d.csv',n_states,run_idx)));

