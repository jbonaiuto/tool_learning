function bin_all_data(exp_info, subject, varargin)

%define default values
defaults = struct('parallel_mode',false);
params = struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

% Events to align to
event_types={'trial_start', 'fix_on', 'go', 'hand_mvmt_onset',...
    'tool_mvmt_onset', 'obj_contact', 'place', 'reward'};

% Read all directories in preprocessed data directory
data_dir=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject);
d=dir(fullfile(data_dir, '*.*.*'));
d=d(2:end);
% Sort by date
d_datetimes=[];
for d_idx=1:length(d)
    d_datetimes(d_idx)=datenum(d(d_idx).name,'dd.mm.YY');
end
[~,sorted_idx]=sort(d_datetimes);
d=d(sorted_idx);

% Bin size
bin_size=1;

for i = 1:length(d)
    dateexp=d(i).name
    out_dir=fullfile(data_dir,dateexp,'multiunit','binned');
    
    % If this date has already been binned or is currently being binned
    if params.parallel_mode && exist(out_dir,'dir')==7
        continue
    end
    
    % If spike sorting has been done
    if exist(fullfile(data_dir,dateexp,'spikes'),'dir')==7
        if exist(out_dir,'dir')~=7
            mkdir(out_dir);
        end
        tic;
        
        % Load all data
        all_data=load_multiunit_data(exp_info,'betta',{dateexp}, 'arrays', [1:6]);
        for arr_idx=1:6
            
            % Get data just for this array
            array_data=crop_data(all_data, arr_idx);
            
            % Align to each event and bin
            for evt_idx=1:length(event_types)
                evt=event_types{evt_idx};
                out_file=fullfile(out_dir, sprintf('fr_b_%s_%s_%s.mat', exp_info.array_names{arr_idx}, dateexp, evt));

                % If not already binned
                if exist(out_file,'file')~=2
                    % Realign to event
                    data_ali=realign(array_data,evt);
                    % Bin
                    data_binned=bin_spikes(data_ali, [-1000 1000], bin_size,...
                        'baseline_evt', 'go','baseline_woi', [-500 0]);
                    % Compute firing rate
                    data=compute_firing_rate(data_binned, 'baseline_type', 'condition','win_len', 6);
                    save(out_file,'data');
                end
            end
            
            % Bin whole trial
            out_file=fullfile(out_dir, sprintf('fr_b_%s_%s_whole_trial.mat', exp_info.array_names{arr_idx}, dateexp));
            if exist(out_file,'file')~=2
                % Bin 
                data_binned=bin_spikes(array_data, [-1000 10000], bin_size,...
                    'baseline_evt', 'go','baseline_woi', [-500 0]);
                % Compute firing rate
                data=compute_firing_rate(data_binned, 'baseline_type', 'condition','win_len', 6);
                save(out_file,'data');
            end
        end
        toc
    end
end
