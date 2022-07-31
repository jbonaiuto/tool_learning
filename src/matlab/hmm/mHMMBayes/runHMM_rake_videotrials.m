addpath('../..');
exp_info=init_exp_info();
subject='betta';%'betta'  'samovar'
array='F1';% 'F1'  'F5hand' 'F5mouth','46v-12r', '45a', 'F2'

NormWay='TrialNorm';       % 'TrialNorm' 'DayNorm' 'WeekNorm' 'AllNorm'       
NormTime='300';            % '500' for baseline from -500 to -200,  '300' baseline from -300 to 0

task='MotorRake'; %'MotorGrasp' 'MotorRake' 'VisualRake' 'VisualGrasp'

conditions={'motor_rake_center','motor_rake_right','motor_rake_left'};
%directions={'motor_rake_aligned','motor_rake_L_R2L','motor_rake_L_L2R','motor_rake_R_R2L','motor_rake_R_L2R'};
%directions={'motor_rake_cln_aligned','motor_rake_cln_R2L','motor_rake_cln_L2R'};
directions={'motor_rake_cln_aligned','motor_rake_cln_directions'};

if strcmp(subject,'betta')  
coder= 'ND';    
dates={'07.05.19','09.05.19','13.05.19','14.05.19','15.05.19','16.05.19','17.05.19','20.05.19','21.05.19','22.05.19','23.05.19','13.06.19','14.06.19',...
    '19.06.19','24.06.19','25.06.19','26.06.19','27.06.19','28.06.19','01.07.19','02.07.19','03.07.19','04.07.19','05.07.19','08.07.19','11.07.19','12.07.19',...
    '15.07.19','17.07.19','18.07.19','19.07.19','22.07.19','23.07.19','24.07.19','25.07.19','26.07.19','31.07.19','01.08.19','02.08.19','05.08.19','06.08.19','07.08.19',...
    '09.08.19','20.08.19','21.08.19','22.08.19','23.08.19','26.08.19','27.08.19','28.08.19','29.08.19','04.09.19','05.09.19','06.09.19','09.09.19','10.09.19','12.09.19',...
    '13.09.19','16.09.19','19.09.19','20.09.19','23.09.19','25.09.19','26.09.19','27.09.19','30.09.19','04.10.19','07.10.19','08.10.19','09.10.19','10.10.19','11.10.19',...
    '14.10.19','16.10.19','17.10.19','18.10.19'};
%            dates={'07.05.19','09.05.19','14.05.19','15.05.19','16.05.19','17.05.19','20.05.19','21.05.19','22.05.19',...
%                 '01.07.19','02.07.19','03.07.19','04.07.19','05.07.19','08.07.19','11.07.19','12.07.19','15.07.19',...
%                 '04.10.19','07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19'}; %dates removed for unsolved mysterious reasons:,'13.05.19' have to update the video table '15.05.19' '04.07.19','11.07.19',
% 
%             dates without days with metadata.direction of different size (I don't
%             know why)
%                  dates={'15.05.19','16.05.19','17.05.19','22.05.19',...
%                 '01.07.19','03.07.19','04.07.19','08.07.19','11.07.19','12.07.19','15.07.19',...
%                 '04.10.19','07.10.19','08.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19'}; 

    
elseif  strcmp(subject,'samovar')
coder= 'SK';
dates={'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21','29.06.21','30.06.21','02.07.21','06.07.21','08.07.21','09.07.21','13.07.21','14.07.21',...
    '15.07.21','16.07.21','27.07.21','28.07.21','29.07.21','30.07.21','03.08.21','04.08.21','05.08.21','06.08.21','10.08.21','11.08.21','12.08.21','13.08.21','17.08.21',...
    '18.08.21','19.08.21','20.08.21','24.08.21','25.08.21','27.08.21','31.08.21','01.09.21','02.09.21','03.09.21','07.09.21','08.09.21','09.09.21','10.09.21','14.09.21',...
    '15.09.21','17.09.21','21.09.21','22.09.21','23.09.21','24.09.21','29.09.21','30.09.21','01.10.21','05.10.21','06.10.21','07.10.21','08.10.21','11.10.21','12.10.21',...
    '13.10.21','14.10.21','26.10.21','27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'};

            % dates with rake and grasp sessions
            % dates={'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21','08.07.21','09.07.21','13.07.21','14.07.21',...
            %     '27.07.21','28.07.21','29.07.21','30.07.21','03.08.21','10.08.21','11.08.21','12.08.21','13.08.21',...
            %     '17.08.21','19.08.21','20.08.21','24.08.21','25.08.21','27.08.21','31.08.21','01.09.21','02.09.21','03.09.21','07.09.21',...
            %     '09.09.21','10.09.21','14.09.21','15.09.21','17.09.21','21.09.21','22.09.21','23.09.21','24.09.21','29.09.21','30.09.21','01.10.21',...
            %     '05.10.21','06.10.21','07.10.21','08.10.21','11.10.21','12.10.21','13.10.21','26.10.21','27.10.21','02.11.21'};
            %3 days at the begining, middle and end of the training with the most
                %clean trials. To test the HMM on Samovar's rake data.
                %dates={'15.06.21','16.06.21','17.06.21','18.08.21','19.08.21','20.08.21','28.10.21','02.11.21','03.11.21'};
end
                
dt=10;

%MU output path
output_path=fullfile(exp_info.base_output_dir, 'figures', 'MU', subject, task, array, 'aligned_OtherDir');

%HMM output path
%output_path=fullfile(exp_info.base_output_dir, 'HMM', subject, 'motor_rake', array, 'clean_trials_directions');
%output_path=fullfile(exp_info.base_output_dir, 'HMM', subject, 'motor_rake', array, 'clean_trials_HMM_test');

if exist(output_path,'dir')~=7
    mkdir(output_path);
end

%data=export_data_to_csv_rake_videotrials(exp_info, subject, array, conditions, directions, dates, dt, output_path,coder);
    data=export_data_to_csv_rake_CleanTrials(exp_info, subject, array, conditions, directions, dates, dt, output_path, coder);
    %save(fullfile(output_path,'data.mat'),'data','-v7.3');
    save(fullfile(output_path,'data.mat'),'data','-v7.3');

    
%system(sprintf('"C:/Program Files/R/R-3.6.1/bin/Rscript" ../../../R/hmm/fit.R "%s"', strrep(output_path,'\','/')));
    
%     T = readtable(fullfile(output_path, 'aic.csv'));
%     minAIC=min(T.aic);
%     forward_prob_idx=find(T.aic==minAIC);
%     n_states=T.states(forward_prob_idx);
%     run_idx=T.run(forward_prob_idx);

%data=data_week(data,dates);
%load(fullfile(output_path,'data.mat'));

 % plotMU_Heatmap_week_2(data, dates, conditions, directions, subject, array, output_path);
 % plotHMM_aligned_condition_rake_videotrials_2(data, dates, conditions, directions, subject, array, output_path);
 % plotMU_by_week(data, dates, conditions, directions, subject, array, output_path);
 % plotMU_heatmap_by_event(data, dates,conditions, directions,subject, array,output_path);
 % plotMU_heatmap_week_OneWindow(data, dates,conditions, directions, subject, array,output_path);
 % plotMU_heatmap_AllTrials_by_event(data, dates, subject, array);
 % plotMU_heatmap_AllTrials_norm(data, dates, subject, array, NormWay, NormTime, task,output_path);
   plotMU_heatmap_norm(data, dates, subject, array, directions, NormWay, NormTime, task,output_path);
 
