function [data] = norm_binned_data(exp_info, subject, arraynames, alignname,...
    condname, binsize)
% this function normalizes multiunit binned data
% exp_info is experimental info data structure (created with
%               init_exp_info.m)
% subject is the name of the monkey
% arraynames is one or more of these: {'F1';'F5hand';'F5mouth';'46v-12r';'45A';'F2'}
% although correlations are based on F1 and F5hand only
% alignname is one of these: {'whole_trial';'fix_on';'go';'hand_mvmt_onset';
%        'tool_mvmt_onset';'obj_contact';'place';'reward'}
% condname is one of these: {'motor_grasp_center';'motor_grasp_right';
%        'motor_grasp_left';'motor_rake_center';'motor_rake_right';
%        'motor_rake_left';'motor_rake_food_center';'motor_rake_food_right';
%        'motor_rake_food_left';'motor_rake_center_catch';'visual_grasp_right';'visual_grasp_left';
%        'visual_rake_pull_right';'visual_rake_pull_left';'visual_pliers_right';'visual_pliers_left';'fixation';
%        'visual_rake_push_right';'visual_rake_push_left';'visual_stick_right';'visual_stick_left'};

% Loads the trial number table
% binsize is bin size to be used in rebinning the data (e.g. 20) 

% PARAMETERS
pathname1 = fullfile(exp_info.base_data_dir, 'preprocessed_data', subject); % Pathname where the recording sessions are
% Loads table "number_of_trials_per_day_table_betta.csv"
wta = readtable(fullfile(pathname1, 'number_of_trials_per_day_table.csv'));

for array_idx=1:length(arraynames)
    arrayname=arraynames{array_idx};
    %-----------
    for dateidx = 1:length(wta.Date) % This processes the recording days in chronological order using the table
                                     % number_of_trials_per_day_table_betta.csv
                                     % Makes output directory if needed
        dirout=fullfile(pathname1, 'Mu_fr_commit', alignname, arrayname, condname);
        if exist(dirout,'dir')~=7
            mkdir(dirout);
        end

        % Loads data in chronological order following the table
        load(fullfile(pathname1, strrep(wta.Date{dateidx},'.20','.'), 'multiunit',...
            'binned', sprintf('fr_b_%s_%s_%s.mat',arrayname,...
            strrep(wta.Date{dateidx},'.20','.'),alignname)));

        cond_log = strcmp(data.metadata.condition,condname);

        if sum(cond_log) > 0 % Check if there are valid trials of the current condition

            % Rebinning and smoothing part
            data=rebin_spikes(data, binsize);
            data=compute_firing_rate(data,'win_len',100);
            %----------------

            % Normalization part
            maxcond = max(data.smoothed_firing_rate,[],4); % Finds max discharge
            data.norm_smoothed_firing_rate=data.smoothed_firing_rate./repmat(maxcond,1,1,1,size(data.smoothed_firing_rate,4));

            disp([wta.Date{dateidx} '  ' condname]);

            data.max{1,1} = condname;          % Writes in the structure the condition name of the normalized data
            data.max{1,2} = maxcond;           % Writes in the structure the max discharge used for normalizing data
        else
            data.max{1,1} = []; % Leaves it empty if no data
            data.max{1,2} = []; % Leaves it empty if no data
        end

        % Saves data in output directory
        newfilename = sprintf('norm_fr_b_%s_%s_%s.mat',arrayname,...
            strrep(wta.Date{dateidx},'.20','.'),alignname);
        save(fullfile(dirout, newfilename),'data');
    end
end


