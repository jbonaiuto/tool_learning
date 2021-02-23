dbstop if error
clear all

addpath('../..');
exp_info=init_exp_info();
subject='betta';
array='F1';
%array='F5hand';
%array='46v-12r';

%conditions={'motor_rake_center','motor_rake_right','motor_rake_left'};
conditions={'AlignedTrial'};
   
%week 15
    dates={'14.05.19'};
    %dates={'14.05.19'},'15.05.19','17.05.19'};
    %dates={'07.10.19','08.10.19','09.10.19'};

dt=10;

for d_idx=1:length(dates)
    date=dates{d_idx};
    output_path=fullfile(exp_info.base_output_dir, 'HMM', 'betta', 'rake', date, array);
    if exist(output_path,'dir')~=7
        mkdir(output_path);
    end
    
    data=export_data_to_csv_rake(exp_info, subject, array, conditions, date, dt, output_path);

    %system(sprintf('"C:/Program Files/R/R-3.6.1/bin/Rscript" ../../../R/hmm/fit.R "%s"', strrep(output_path,'\','/')));
    
    T = readtable(fullfile(output_path, 'aic.csv'));
    minAIC=min(T.aic);
    forward_prob_idx=find(T.aic==minAIC);
    n_states=T.states(forward_prob_idx);
    run_idx=T.run(forward_prob_idx);

    plotHMM_aligned_condition_rake_videotrials(data, date, conditions, array, fullfile(output_path,sprintf('forward_probs_%dstates_%d.csv',n_states,run_idx)));
    %plotHMM_aligned(data, dates, conditions, sprintf('forward_probs_%dstates_%d.csv',forward_prob_Idx));

    % n_runs=10;
    % for j=2:n_states
    %     for i=1:n_runs
    %         %plotHMM_aligned(data, dates, conditions, sprintf('forward_probs_%d.csv',i));
    %         plotHMM_aligned(data, dates, conditions, sprintf('forward_probs_%dstates_%d.csv',j,i));
    %     end
    % end
end