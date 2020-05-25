function [data] = norm_binned_data(arrayname,alignname,condname,binsize,trial_dur);
% this function normalizes multiunit binned data
% arrayname is one of these: {'F1';'F5hand';'F5mouth';'46v-12r';'45A';'F2'}
% although correlations are based on F1 and F5hand only
% alignname is one of these: {'whole_trial';'fix_on';'go';'hand_mvmt_onset';'tool_mvmt_onset';'obj_contact';'place';'reward'}
% condname is one of these: {'motor_grasp_center';'motor_grasp_right';'motor_grasp_left';'motor_rake_center';'motor_rake_right';
%        'motor_rake_left';'motor_rake_food_center';'motor_rake_food_right';
%        'motor_rake_food_left';'motor_rake_center_catch';'visual_grasp_right';'visual_grasp_left';
%        'visual_rake_pull_right';'visual_rake_pull_left';'visual_pliers_right';'visual_pliers_left';'fixation';
%        'visual_rake_push_right';'visual_rake_push_left';'visual_stick_right';'visual_stick_left'};

% Loads the trial number table
% binsize is bin size to be used in rebinning the data (e.g. 20) 
% trial_dur is Trial duration to be used (e.g. 2000), can be up to 10000

% PARAMETERS
pathname1 = ('F:\Data\tooltask\preprocessed_data\betta\'); % Pathname where the recording sessions are
kernel_width=10; % Kernel width used to smooth data before normalizing
kernel=gausswin(kernel_width);
% Loads table "number_of_trials_per_day_table_betta.csv"
wta = readtable('C:\Users\gcoude\Documents\data\tooltask\number_of_trials_per_day_table_betta.csv');

%-----------
% Loads or creates a metadata file listing all possible arrays, conditions or aligment
if exist('C:\Users\gcoude\Documents\data\tooltask\scripts\info_array_cond_align') == 1
else
    listarray = {'F1';'F5hand';'F5mouth';'46v-12r';'45A';'F2'};
    listalign = {'whole_trial';'fix_on';'go';'hand_mvmt_onset';'tool_mvmt_onset';'obj_contact';'place';'reward'}; % number
    listcond = {'motor_grasp_center';'motor_grasp_right';'motor_grasp_left';'motor_rake_center';'motor_rake_right';
        'motor_rake_left';'motor_rake_food_center';'motor_rake_food_right';
        'motor_rake_food_left';'motor_rake_center_catch';'visual_grasp_right';'visual_grasp_left';
        'visual_rake_pull_right';'visual_rake_pull_left';'visual_pliers_right';'visual_pliers_left';'fixation';
        'visual_rake_push_right';'visual_rake_push_left';'visual_stick_right';'visual_stick_left'};
    save('C:\Users\gcoude\Documents\data\tooltask\scripts\info_array_cond_align','listarray','listalign','listcond');
end
load('C:\Users\gcoude\Documents\data\tooltask\scripts\info_array_cond_align');
%-----------
for dateidx = 1:length(wta.Date) % This processes the recording days in chronological order using the table
                                 % number_of_trials_per_day_table_betta.csv
                                 % Makes output directory if needed
    dirout=['F:\Data\tooltask\Mu_fr_commit_' alignname '\' arrayname '\' condname '\'];
    if exist(dirout)==7
    else
        mkdir(dirout);
    end
    
    % Loads data in chronological order following the table
    load([pathname1 strrep(wta.Date{dateidx},'.20','.') '\multiunit\binned\fr_b_' arrayname '_'...
        strrep(wta.Date{dateidx},'.20','.') '_' alignname '.mat']);
    data.firing_rate = data.firing_rate(:,:,:,1:trial_dur); % Takes data between 1 and specified trial duration
    
    %cdn_idx_real = 0;
    fr_newbin_smnorm = [];   % Creating firing data array with new bin size normalized
    cond_log = strcmp(data.metadata.condition,condname);
    
    if sum(cond_log) > 0 % Check if there are valid trials of the current condition
        sizefr = size(data.firing_rate);
        
        % Rebinning and smoothing part
        fr_reshape_tmp = data.firing_rate(1,1:sizefr(2),1:sizefr(3),1:...
            sizefr(4)-mod(sizefr(4),binsize)); % Removes modulus in case of specified trial duration
                                               % not being a multiple of specified bin size
        
        fr_reshape = reshape(fr_reshape_tmp,sizefr(2),sizefr(3),...
            binsize,(sizefr(4)-mod(sizefr(4),binsize))/binsize); % Reshape data
        frsum = sum(fr_reshape,3);                               % Sum spikes in the new binned dimension
        fr_newbin = reshape(frsum,sizefr(2),sizefr(3),size(fr_reshape,4));  % Removes the bin size dimension
        fr_newbin_sm = filter(kernel,6,fr_newbin,[],3);          % Smoothes data
        %----------------
        
        % Normalization part
        maxcond = max(max(fr_newbin_sm(:,cond_log,:),[],3),[],2); % Finds max discharge
        a = 1:size(fr_newbin_sm,2);
        fr_newbin_smnormtmp = []
        for t = a(cond_log)
            a(cond_log);
            for b = 1:size(fr_newbin_sm,3)
                fr_newbin_smnormtmp(:,t,b) = fr_newbin_sm(:,t,b)./maxcond; % Normalizes
            end
            fr_newbin_smnorm(1:size(fr_newbin_sm,1),t,1:size(fr_newbin_sm,3)) =...
                fr_newbin_smnormtmp(1:size(fr_newbin_sm,1),t,1:size(fr_newbin_sm,3));
            disp([wta.Date{dateidx} '  ' condname]);
        end
        %--------------
    end
    if sum(cond_log) > 0
        data.norm_data = fr_newbin_smnorm; % Writes in the structure the normalized data
        data.max{1,1} = condname;          % Writes in the structure the condition name of the normalized data
        data.max{1,2} = maxcond;           % Writes in the structure the max discharge used for normalizing data
    else
        data.max{1,1} = []; % Leaves it empty if no data
        data.max{1,2} = []; % Leaves it empty if no data
    end

% Saves data in output directory
newfilename = ['norm_fr_b_' arrayname '_'...
    strrep(wta.Date{dateidx},'.20','.') '_' alignname '.mat']
save([dirout newfilename],'data');
end


