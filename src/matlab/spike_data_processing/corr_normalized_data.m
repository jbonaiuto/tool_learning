 function [data_corr] = corr_normalized_data(exp_info,subject,arraynames,alignname,condname)
% This function correlates normalized multiunit binned data
% exp_info is experimental info data structure (created with
%               init_exp_info.m)
% subject is the name of the monkey
% arrayname is one or more of these: {'F1';'F5hand';'F5mouth';'46v-12r';'45A';'F2'}
%           although this has been tried with F1 and F5hand only 
% alignname is one of these:     
%           {'whole_trial';'fix_on';'go';'hand_mvmt_onset';'tool_mvmt_onset';
%           'obj_contact';'place';'reward'}
% condname is one of these: 
%          {'motor_grasp_center';'motor_grasp_right';'motor_grasp_left';
%          'motor_rake_center';'motor_rake_right';       
%          'motor_rake_left';'motor_rake_food_center';'motor_rake_food_right';
%          'motor_rake_food_left';'motor_rake_center_catch';
%          'visual_grasp_right';'visual_grasp_left';
%          'visual_rake_pull_right';'visual_rake_pull_left';'visual_pliers_right';
%          'visual_pliers_left';'fixation';      
%          'visual_rake_push_right';'visual_rake_push_left';'visual_stick_right';
%          'visual_stick_left';'visual_rake_push_right';'visual_rake_push_left';
%          'visual_stick_right';'visual_stick_left'};
% nbin is the number of bins of each trial and depends on the number of
%      bins of the normalized data
%--------------
% This part loads the trial number table
wta = readtable(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, 'number_of_trials_per_day_table.csv'));
%--------------
% This part merges the normalized data of each recording date
% in a single cell array
for array_idx = 1:length(arraynames)    
    d=dir(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, 'Mu_fr_commit', alignname, arraynames{array_idx}, condname, '*.mat'));
    for wta_idx = 1:length(wta.Date)
        for d_idx =1:length(d)
            if contains(d(d_idx).name,strrep(wta.Date{wta_idx},'.20','.')) % Checks if recording date in directory
                                                                           % is listed in the trial table
                load(fullfile(d(d_idx).folder, d(d_idx).name));
                disp(wta.Date{wta_idx});                                % Display ongoing date processing
                logic_cond = strcmp(data.metadata.condition,condname);
                if sum(logic_cond) > 0 && isfield(data,'norm_smoothed_firing_rate')   % Proceeds if condition and normalized data
                                                                     % exist for a particular day
                    rec_days{array_idx,wta_idx} = squeeze(data.norm_smoothed_firing_rate(1,:,logic_cond,:));
                end
            end
        end
    end
end
%--------------
% This part shifts the bin dimension from 3rd to 1st position for an easier
% array reshaping to come
for day_idx = 1:size(rec_days,2)
    for array_idx = 1:length(arraynames)
        if length(rec_days{array_idx,day_idx})>0
            rec_days_shift{array_idx,day_idx} = shiftdim(rec_days{array_idx,day_idx},2);
        end
    end
end
%--------------
% This is the actual reshaping of the cell array from N BINS X 32 ELECTRODE X N DAY TRIALS
% into an array of N DAY TRIALS X (32 ELECTRODES * N BINS)
for day_idx = 1:size(rec_days,2)
    for array_idx = 1:length(arraynames)
        if length(rec_days{array_idx,day_idx})>0
            rec_days_reshape{array_idx,day_idx}  = reshape(rec_days_shift{array_idx,day_idx},...
                size(rec_days_shift{array_idx,day_idx},1)*size(rec_days_shift{array_idx,day_idx},2),...
                size(rec_days_shift{array_idx,day_idx},3))';
        end
    end
end
%--------------
% This part concatenates all arrays (currently F1 and F5hand) to form a cell array
% of DAY TRIALS X (2 ELECTRODE ARRAYS * 32 ELECTRODES * N BINS)
for day_idx = 1:size(rec_days,2)
    rec_days_concat{1,day_idx} = [];
    for array_idx=1:length(arraynames)
        rec_days_concat{1,day_idx} = [rec_days_concat{1,day_idx} rec_days_reshape{array_idx,day_idx}];
    end
end
%--------------
% This part takes the cell array and makes an ordinary array of
% ALL TRIALS X ALL BINS(2 ELECTRODES ARRAY * 32 ELECTRODES * N BINS)
trial_bin=[];
for day_idx = 1:size(rec_days_concat,2)
    x=rec_days_concat{day_idx};
    if ~isempty(x)
        trial_bin = [trial_bin;x];
    end
end
median_trial_bin=nanmedian(trial_bin,1);

%--------------
% This part correlates each trial vs the rest
% value_rest_tr = [];
% value_tr = [];
% value_rest_tr_mean = [];
% value_rest_tr_std = [];
% rho = [];
for day_idx = 1:size(rec_days_concat,2)
    x=rec_days_concat{day_idx};
    x(isnan(x))=0;
    day_rho=[];
    if ~isempty(x)
        for i=1:size(x,1)
            day_rho(i)=corr(x(i,:)',median_trial_bin','type','Spearman');
        end
    end
    data_corr{day_idx,2}=day_rho;
    data_corr{day_idx,1} = wta.Date(day_idx);
end

figure();
hist([data_corr{:,2}],100);
xlabel('Correlation');
ylabel('Num Trials');
title(condname);

% Saves data in directory
save(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, sprintf('corr_days_%s_%s.mat',strjoin(arraynames,'_'), condname)), 'data_corr');
