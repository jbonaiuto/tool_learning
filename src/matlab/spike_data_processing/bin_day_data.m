function bin_day_data(exp_info, subject, date, varargin)

%define default values
defaults = struct('overwrite',false);
params = struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

% Events to align to
event_types={'trial_start', 'fix_on', 'go', 'hand_mvmt_onset',...
    'tool_mvmt_onset', 'obj_contact', 'place', 'reward'};

data_dir=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject);
out_dir=fullfile(data_dir,date,'multiunit','binned');
    
% Bin size
bin_size=1;

% If spike sorting has been done
if exist(fullfile(data_dir,date,'spikes'),'dir')==7
    if exist(out_dir,'dir')~=7
        mkdir(out_dir);
    end
    tic;

    % Load all data
    all_data=load_multiunit_data(exp_info,subject,{date}, 'arrays', [1:6]);
    for arr_idx=1:6

        % Get data just for this array
        array_data=crop_data(all_data, arr_idx);

        % Align to each event and bin
        for evt_idx=1:length(event_types)
            evt=event_types{evt_idx};
            out_file=fullfile(out_dir, sprintf('fr_b_%s_%s_%s.mat', exp_info.array_names{arr_idx}, date, evt));

            % If not already binned
            %if params.overwrite || exist(out_file,'file')~=2
                % Realign to event
                data_ali=realign(array_data,evt);
                % Bin
                data_binned=bin_spikes(data_ali, [-1000 1000], bin_size,...
                    'baseline_evt', 'go','baseline_woi', [-500 0]);
                % Compute firing rate
                data=compute_firing_rate(data_binned, 'baseline_type', 'condition','win_len', 60);
                data.trial_date=ones(1,data.ntrials);
                disp(out_file);
                save(out_file,'data','-v7.3');
            %end
        end

        % Bin whole trial
        out_file=fullfile(out_dir, sprintf('fr_b_%s_%s_whole_trial.mat', exp_info.array_names{arr_idx}, date));
        %if params.overwrite || exist(out_file,'file')~=2
            % Bin 
            data_binned=bin_spikes(array_data, [-1000 10000], bin_size,...
                'baseline_evt', 'go','baseline_woi', [-500 0]);
            % Compute firing rate
            data=compute_firing_rate(data_binned, 'baseline_type', 'condition','win_len', 60);
            data.trial_date=ones(1,data.ntrials);
            disp(out_file);
            save(out_file,'data','-v7.3');
        %end
    end
    toc
end
