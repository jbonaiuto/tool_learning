 function [data_corr] = corr_normalized_data(arrayname,alignname,condname,nbin);
% This function correlates normalized multiunit binned data
% arrayname is one or more of these: {'F1';'F5hand';'F5mouth';'46v-12r';'45A';'F2'}
% although this has been tried with F1 and F5hand only 
% alignname is one of these: {'whole_trial';'fix_on';'go';'hand_mvmt_onset';'tool_mvmt_onset';'obj_contact';'place';'reward'}
% condname is one of these: {'motor_grasp_center';'motor_grasp_right';'motor_grasp_left';'motor_rake_center';'motor_rake_right';
%        'motor_rake_left';'motor_rake_food_center';'motor_rake_food_right';
%        'motor_rake_food_left';'motor_rake_center_catch';'visual_grasp_right';'visual_grasp_left';
%        'visual_rake_pull_right';'visual_rake_pull_left';'visual_pliers_right';'visual_pliers_left';'fixation';
%        'visual_rake_push_right';'visual_rake_push_left';'visual_stick_right';'visual_stick_left'};'visual_rake_push_right';'visual_rake_push_left';'visual_stick_right';'visual_stick_left'};
% nbin is the number of bins of each trial and depends on the number of
% bins of the normalized data
%--------------
% This part loads the trial number table
wta = readtable('C:\Users\gcoude\Documents\data\tooltask\number_of_trials_per_day_table_betta.csv');
%--------------
% This part merges the normalized data of each recording date
% in a single cell array
for array_idx = 1:length(arrayname)    
    d=dir(['F:\Data\tooltask\Mu_fr_commit_' alignname '\F5hand\' condname '\' '*.mat']);
    for wta_idx = 1:length(wta.Date)
        for d_idx =1:length(d)
            if contains(d(d_idx).name,strrep(wta.Date{wta_idx},'.20','.')) % Checks if recording date in directory
                                                                           % is listed in the trial table
                load([d(d_idx).folder '\' d(d_idx).name]);
                disp(wta.Date{wta_idx});                                % Display ongoing date processing
                logic_cond = strcmp(data.metadata.condition,condname);
                if sum(logic_cond) > 0 & isfield(data,'norm_data')   % Proceeds if condition and normalized data
                                                                     % exist for a particular day
                    rec_days{array_idx,wta_idx} = data.norm_data(:,logic_cond,:);
                end
            end
        end
    end
end
%--------------
% This part shifts the bin dimension from 3rd to 1st position for an easier
% array reshaping to come
for day_idx = 1:size(rec_days,2)
    for array_idx = 1:length(arrayname)
        rec_days_shift{array_idx,day_idx} = shiftdim(rec_days{array_idx,day_idx},2);
    end
end
%--------------
% This is the actual reshaping of the cell array from N BINS X 32 ELECTRODE X N DAY TRIALS
% into an array of N DAY TRIALS X (32 ELECTRODES * N BINS)
for day_idx = 1:size(rec_days,2)
    for array_idx = 1:length(arrayname)
    rec_days_reshape{array_idx,day_idx}  = reshape(rec_days_shift{array_idx,day_idx},...
        size(rec_days_shift{array_idx,day_idx},1)*size(rec_days_shift{array_idx,day_idx},2),...
        size(rec_days_shift{array_idx,day_idx},3))';
    end
end
%--------------
% This part concatenates two arrays (currently F1 and F5hand) to form a cell array
% of DAY TRIALS X (2 ELECTRODE ARRAYS * 32 ELECTRODES * N BINS)
for day_idx = 1:size(rec_days,2)
    rec_days_concat{1,day_idx} = [rec_days_reshape{1,day_idx} rec_days_reshape{2,day_idx}];
             valid_day_name(day_idx) = wta.Date(day_idx);
             fn = getfield(wta,condname);
             n_trial(day_idx) = fn(day_idx);
end
%--------------
% This part takes the cell array and makes an ordinary array of
% ALL TRIALS X ALL BINS(2 ELECTRODES ARRAY * 32 ELECTRODES * N BINS)
trial_bin=[];
for day_idx = 1:size(rec_days_concat,2)
    x=rec_days_concat{day_idx};
    if isempty(x)==0
        s(day_idx,1)=size(x,1);
        trial_bin = [trial_bin;x];
    end
end
%--------------
% This part correlates each trial vs the rest
% value_rest_tr = [];
% value_tr = [];
% value_rest_tr_mean = [];
% value_rest_tr_std = [];
% rho = [];
for tr_idx = 1:size(trial_bin,1)
    value_rest_tr=trial_bin([1:size(trial_bin,1)]~=tr_idx,:);
    value_tr=trial_bin(:,tr_idx);
    for nbin = 1:size(trial_bin,1)
        value_rest_tr_mean(nbin) = mean(value_rest_tr(isnan(value_rest_tr(:,nbin))==0,nbin),1);
        value_rest_tr_std(nbin) = std(value_rest_tr(isnan(value_rest_tr(:,nbin))==0,nbin),[],1);
    end
    x=value_tr;
    x = x(isnan(x)==0);
    y=value_rest_tr_mean';
    y = y(isnan(x)==0);
    rho(tr_idx)=corr(x,y);
end
%--------------
% This part reshapes the correlation from a 1 X ALL TRIALS array
% into a cell array of 2 (DATE, CORRELATIONS OF THAT DAY) X ALL RECORDING DAYS 
nd = wta.NthDayOfExperiment
fn(isnan(fn))=0;
cfn = cumsum(fn);
dayuni = unique(nd);
for durd = 1:length(dayuni)
    logw = nd == dayuni(durd);
    sw(durd) = sum(fn(logw));
end
csw = cumsum(sw);
rhotmp=rho;
x=[];
for durd = 1:length(sw)
    data_corr{durd,2} = rhotmp(1,1:(sw(durd)));
    nx = rhotmp(1,sw(durd)+1:end);
    rhotmp = nx;
    data_corr{durd,1} = wta.Date(durd);
end
% Saves data in directory
save(['F:\Data\tooltask\corr\corr_days_F1_F5hand_' condname], 'data_corr');