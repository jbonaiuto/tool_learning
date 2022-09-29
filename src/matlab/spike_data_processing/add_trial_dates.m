subject='betta';
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
    dn=datenum(d(d_idx).name,'dd.mm.YY');
    d_datetimes(d_idx)=dn;
end
[~,sorted_idx]=sort(d_datetimes);
d=d(sorted_idx);

for i = 1:length(d)
    date=d(i).name
    out_dir=fullfile(data_dir,date,'multiunit','binned');
    
    for arr_idx=1:6

        % Align to each event and bin
        for evt_idx=1:length(event_types)
            evt=event_types{evt_idx};
            out_file=fullfile(out_dir, sprintf('fr_b_%s_%s_%s.mat', exp_info.array_names{arr_idx}, date, evt));

            if exist(out_file,'file')==2
                load(out_file);
                if ~isfield(data,'trial_date')
                    data.trial_date=ones(1,data.ntrials);
                    save(out_file,'data','-v7.3');
                end
            end
        end

        % Bin whole trial
        out_file=fullfile(out_dir, sprintf('fr_b_%s_%s_whole_trial.mat', exp_info.array_names{arr_idx}, date));
        if exist(out_file,'file')==2
            load(out_file);
            if ~isfield(data,'trial_date')
                data.trial_date=ones(1,data.ntrials);
                save(out_file,'data','-v7.3');
            end
        end
    end
end
