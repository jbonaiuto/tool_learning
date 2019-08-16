function data=preprocess_lfp(exp_info, subject, recording_date, varargin)

% Parse optional arguments
defaults=struct('plot',false);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end


spm('defaults','eeg');

% Directory where raw data is stored
raw_data_dir=fullfile('/media/ferrarilab/2C042E4D35A4CAFF/tool_learning/data/recordings/rhd2000', subject,...
    recording_date);

% Read and sort raw data files
addpath('..');
files=read_sorted_rhd_files(raw_data_dir);
rmpath('..');

addpath('../rhd');
addpath('../mulab_data_cleaner');

if length(files)>0
    disp(recording_date);
    
    % Directory to save processed LFPs to
    output_dir=fullfile(exp_info.base_data_dir, 'preprocessed_data', ...
        subject, recording_date, 'lfps');
    mkdir(output_dir);

    % Read trial events and info
    events=readtable(fullfile(exp_info.base_data_dir, 'preprocessed_data', ...
        subject, recording_date, 'trial_events.csv'));
    trialinfo=readtable(fullfile(exp_info.base_data_dir, 'preprocessed_data',...
        subject,recording_date,'trial_info.csv'));

    % time to cut off at beginning and end of trial due to amplifier ringing (in seconds)
    %cutoff_window=0.1;

    % Downsampled sampling rate
    ds_rate=256;

    % Lowpass filter threshold
    lowpass_thresh=100;

    % Highpass filter threshold
    highpass_thresh=1.0;

    % Empty structure to store concatenated data (from all trials)
    data.label={};
    for a=1:length(exp_info.array_names)
        for c=1:32
            data.label{end+1}=sprintf('%s_%d',exp_info.array_names{a},c);
        end
    end
    data.fsample=ds_rate;
    data.time={};
    data.trial={};
    data.trialinfo=[];

    trial_idx=1;

    for i=1:length(files)
        fname=files(i).name
        [~, name, ext]=fileparts(fname);
        i
        
        % Read rhd file - get amp data, digital input data, and sampling rate
        data_fname=fullfile(raw_data_dir,fname);
        [ampl_data,dig_in_data,srate]=read_Intan_RHD2000_file(data_fname,...
            false);
        
        % Get recording signal
        rec_signal=dig_in_data(3,:);

        % PCA-based cleaning
        cleaned_data=zeros(size(ampl_data));
        for array_idx=1:length(exp_info.array_names)
            x=CleanData(ampl_data((array_idx-1)*exp_info.ch_per_array+1:array_idx*exp_info.ch_per_array,:),0, size(ampl_data,2));
            cleaned_data((array_idx-1)*exp_info.ch_per_array+1:array_idx*exp_info.ch_per_array,:)=x(:,1:end-2)';
        end

        % Determine time (in seconds) for each data point
        sec_per_pnt=1/srate;
        npts=size(ampl_data,2);
        times=[sec_per_pnt:sec_per_pnt:npts*sec_per_pnt];

        % Figure out the start time of the trial based on recording signal
        rec_signal_diff = diff(rec_signal);

        % Find recording start and stop times
        trial_start=find(rec_signal_diff==1);
        trial_end=find(rec_signal_diff==-1);

        trial_start_times=[];
        trial_end_times=[];

        % If there is at least one start and stop time
        if length(trial_start)>0 && length(trial_end)>0

            add_extra=false;
            extra_start_time=-1;
            extra_end_time=-1;
            if length(trial_start) > length(trial_end)
                last_trial_start = trial_start(end);
                % Recording goes until end of file
                dur_step = length(rec_signal) - last_trial_start;
                % Ignore single time step blups
                if dur_step > 1
                    add_extra=true;
                    extra_start_time=times(last_trial_start);
                    extra_end_time=times(end);
                end
                trial_start = trial_start(1:end-1);
            elseif length(trial_end) > length(trial_start)
                first_trial_end = trial_end(1);
                % Recording starts at beginning of file
                dur_step = first_trial_end;
                % Ignore single time step blips
                if dur_step > 1
                    trial_start_times(end+1)=times(1);
                    trial_end_times(end+1)=times(first_trial_end);
                end
                trial_end = trial_end(2:end);
            end
            
            % Number of time steps between each up and down state switch
            dur_steps=trial_end-trial_start;

            % For each trial in the file
            for j=1:length(dur_steps)
                % Ignore single time step blups
                if dur_steps(j)>1
                    trial_start_times(end+1)=times(trial_start(j));
                    trial_end_times(end+1)=times(trial_end(j));
                end
            end
            
            if add_extra
                trial_start_times(end+1)=extra_start_time;
                trial_end_times(end+1)=extra_end_time;
            end

        % If there is a trial start and no trial end
        elseif length(trial_start)>0 && length(trial_end)==0
            % Recording goes until end of file
            dur_step = length(rec_signal) - trial_start(1);
            % Ignore single time step blups
            if dur_step > 1
                trial_start_times(end+1)=times(trial_start(1));
                trial_end_times(end+1)=times(end);
            end

        % If there is a trial end and no trial start
        elseif length(trial_start)==0 && length(trial_end)>0
            % Recording starts at beginning of file
            dur_step = trial_end;
            % Ignore single time step blips
            if dur_step > 1
                trial_start_times(end+1)=times(1);
                trial_end_times(end+1)=times(trial_end(1));
            end
        end

        for start_idx=1:length(trial_start_times)

            t_info_idxs=find(strcmp(trialinfo.intan_file,fname));
            t_info_idx=t_info_idxs(start_idx);
            
            % Get this trial's condition
            condition=trialinfo.condition{t_info_idx};

            % Center times on trial start time
            trial_times=times-trial_start_times(start_idx);
            idx=intersect(find(trial_times>=-1),...
                find(trial_times<=trial_end_times(start_idx)-trial_start_times(start_idx)+1));

            % Data structure to hold trial data
            trial_data.label={};
            for a=1:length(exp_info.array_names)
                for c=1:32
                    trial_data.label{end+1}=sprintf('%s_%d',exp_info.array_names{a},c);
                end
            end
            trial_data.fsample=srate;
            
            % Cut off beginning and end (because of amplifier ringing)            
            clean_trial_data=cleaned_data(:,idx);
            clean_trial_times=trial_times(idx);
            % Number of samples to remove from beginning and end
            %window=cutoff_window*srate;
            %if length(clean_trial_data)>2*window
            %    % Remove window from beginning and end of trial
            %    clean_trial_data=clean_trial_data(:,window+1:end-window);
            %    clean_trial_times=clean_trial_times(window+1:end-window);
            %end
            
            trial_data.trial={clean_trial_data};
            trial_data.time={clean_trial_times};        
            % Trial info - first column is condition index, second is
            % good trial or not, remaining are time of each event or NaN if event does not
            % occur in this trial
            trial_data.trialinfo=ones(1,2+length(exp_info.event_types)).*nan;
            trial_data.trialinfo(1)=find(strcmp(exp_info.conditions,condition));
            trial_data.trialinfo(2)=strcmp(trialinfo.status{t_info_idx},'good');
            trial_rows=find(events.trial==(t_info_idx-1));
            for j=1:length(trial_rows)
                evt_type=events.event(trial_rows(j));
                evt_idx=find(strcmp(exp_info.event_types,evt_type));
                evt_time=events.time(trial_rows(j))/1000.0;
                % Only include event if it occurs within the trial
                if evt_time>=0 && evt_time<=trial_end_times(start_idx)-trial_start_times(start_idx)
                    trial_data.trialinfo(2+evt_idx)=evt_time;
                end
            end

            % Lowpass filter
            trial_data.trial{1}=ft_preproc_lowpassfilter(trial_data.trial{1},...
                trial_data.fsample, lowpass_thresh, 6, 'but', 'twopass', 'reduce');

            % Downsample
            cfg=[];
            cfg.resamplefs=ds_rate;
            cfg.detrend='yes';
            ds_data=ft_resampledata(cfg, trial_data);

            % Highpass filter
            ds_data.trial{1}=ft_preproc_highpassfilter(ds_data.trial{1},...
                ds_data.fsample, highpass_thresh, 6, 'but', 'twopass', 'reduce');        

            % Append
            cfg=[];
            cfg.keepsampleinfo='no';
            if length(data.trial)>0
                data=ft_appenddata(cfg, data, ds_data);
            else
                data=ds_data;
            end

            trial_idx=trial_idx+1;
        end
    end

    assert(trial_idx-1==length(trialinfo.trial));
    
    data.fsample=ds_rate;

    % Save data
    save(fullfile(output_dir, sprintf('%s_%s_lfp.mat', subject, recording_date)), 'data');

    if params.plot
        cfg=[];
        ft_databrowser(cfg,data);
    end
end