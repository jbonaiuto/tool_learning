function extract_gaze_data(exp_info, subject, date, plexon_data_path)

addpath('../spike_data_processing');

% Load trial info
info_file=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        date, 'trial_info.csv');
info=readtable(info_file);
    
% Load calibration
out_path=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, date, 'eyetracking');
calib_file=fullfile(out_path, sprintf('%s_%s_calibration.mat', subject, date));
if exist(calib_file,'file')==2
    load(calib_file);

    plex_files=unique(info.plexon_file);
    plex_trial_data={};
    
    for plx_idx=1:length(plex_files)
        if length(plex_files{plx_idx})>0
            % Load plexon file
            plex_data=readPLXFileC(fullfile(plexon_data_path, plex_files{plx_idx}),'all');

            % Get x, y channel data
            x_chan=find(strcmp({plex_data.ContinuousChannels.Name},'FP31'));
            y_chan=find(strcmp({plex_data.ContinuousChannels.Name},'FP32'));
            x = double(plex_data.ContinuousChannels(x_chan).Values)/25000;
            y = double(plex_data.ContinuousChannels(y_chan).Values)/25000;

            % Filter data into trials
            fs=plex_data.ADFrequency;
            event_data=plex_data.EventChannels;
            [T,X,Y]=eventide_gaze_filter_task('EVT28','EVT29',event_data,x,y,fs);

            for i=1:length(X)
                X_x=[];
                Y_y=[];
                for j=1:length(X{i})
                    res=backward_projection([X{i}(j) Y{i}(j)]);
                    X_x(j)=calibration.betaX(1)+calibration.betaX(2)*res(1);
                    Y_y(j)=calibration.betaY(1)+calibration.betaY(2)*res(3);
                end
                X{i}=X_x';
                Y{i}=Y_y';
            end
            trial_data=[];
            trial_data.X=X;
            trial_data.Y=Y;
            trial_data.T=T;
            plex_trial_data{plx_idx}=trial_data;
        end
    end

    data=[];
    data.dates={date};
    data.subject=subject;
    data.ntrials=0;

    data.eyedata=[];
    data.eyedata.date=[];
    data.eyedata.trial=[];
    data.eyedata.rel_trial=[];
    data.eyedata.x={};
    data.eyedata.y={};
    data.eyedata.t={};

    % Create metadata structure
    event_types={'trial_start','fix_on','go','hand_mvmt_onset','tool_mvmt_onset',...
        'obj_contact','place','reward'};
    data.metadata=[];
    data.metadata.event_types=event_types;
    for evt_idx=1:length(event_types)
        data.metadata.(event_types{evt_idx})=[];
    end
    data.metadata.condition={};

    % Load metadata
    evt_file=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        date, 'trial_events.csv');
    evts=readtable(evt_file);


    good_trial_idx=info.overall_trial(find(strcmp(info.status,'good')));
    data.n_trials=length(good_trial_idx);

    for i=1:length(good_trial_idx)
        row_idx=find(info.overall_trial==good_trial_idx(i));
        condition=info.condition{row_idx};
        for evt_idx=1:length(event_types)
            event_type=event_types{evt_idx};
            mapped_event_type=map_event_type(condition, event_type);
            if length(mapped_event_type)
                evt_times=evts.time(intersect(find(evts.trial==good_trial_idx(i)),...
                    find(strcmp(evts.event,mapped_event_type))));
                if length(evt_times)
                    data.metadata.(event_type)=[data.metadata.(event_type) evt_times(1)];
                else
                    data.metadata.(event_type)=[data.metadata.(event_type) NaN];
                end
            else
                data.metadata.(event_type)=[data.metadata.(event_type) NaN];
            end
        end
        data.metadata.condition{i}=condition;

        plex_file=info.plexon_file{row_idx};
        plex_file_idx=info.plexon_trial_idx(row_idx);
        j=find(strcmp(plex_files,plex_file));
        trial_x=plex_trial_data{j}.X{plex_file_idx+1};
        trial_y=plex_trial_data{j}.Y{plex_file_idx+1};
        trial_t=plex_trial_data{j}.T{plex_file_idx+1};

        data.eyedata.date(i)=1;
        data.eyedata.trial(i)=i;
        data.eyedata.rel_trial(i)=i;
        data.eyedata.x{i}=trial_x;
        data.eyedata.y{i}=trial_y;
        data.eyedata.t{i}=trial_t;

    end

    out_fname=sprintf('%s_%s_eyedata.mat', subject, date);
    save(fullfile(out_path, out_fname), 'data');
end