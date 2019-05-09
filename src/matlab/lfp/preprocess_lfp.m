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
raw_data_dir=fullfile(exp_info.base_data_dir, 'recording', subject,...
    recording_date);

% Read and sort raw data files
addpath('..');
files=read_sorted_rhd_files(raw_data_dir);
rmpath('..');

addpath('../rhd');
addpath('../mulab_data_cleaner');

% Directory to save processed LFPs to
output_dir=fullfile(exp_info.base_data_dir, 'preprocessed_data', ...
    subject, recording_date);
mkdir(output_dir);

% Read trial events and info
events=readtable(fullfile(exp_info.base_data_dir, 'preprocessed_data', ...
    subject, recording_date, 'trial_events.csv'));
trialinfo=readtable(fullfile(exp_info.base_data_dir, 'preprocessed_data',...
    subject,recording_date,'trial_info.csv'));

% time to cut off at beginning and end of trial due to amplifier ringing (in seconds)
cutoff_window=0.1;

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
    
    % Get this trial's condition
    condition=trialinfo.condition{trialinfo.trial==(trial_idx-1)};

    % Read rhd file - get amp data, digital input data, and sampling rate
    data_fname=fullfile(raw_data_dir,fname);
    [ampl_data,dig_in_data,srate]=read_Intan_RHD2000_file(data_fname,...
        false);

    % Number of samples to remove from beginning and end
    window=cutoff_window*srate;

    % Remove window from beginning and end of trial
    ampl_data=ampl_data(:,window+1:end-window);

    % Get recording signal
    rec_signal=dig_in_data(3,:);
    % Remove window from beginning and end of recording_signal
    rec_signal=rec_signal(window+1:end-window);

    % Skip if erroneous (recording signal is just a one time step blip)
    if length(find(rec_signal==1))>1 && rec_signal(1)<1
        
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
        % Find where recording signal goes from 0 to 1, only get first
        % instance because sometimes the signal drops and quickly comes
        % back
        trial_start_idx = find(rec_signal_diff == 1,1);
        trial_start_time = times(trial_start_idx);
        
        % Center times on trial start time
        times=times-trial_start_time;

        % Data structure to hold trial data
        trial_data.label={};
        for a=1:length(exp_info.array_names)
            for c=1:32
                trial_data.label{end+1}=sprintf('%s_%d',exp_info.array_names{a},c);
            end
        end
        trial_data.fsample=srate;
        trial_data.trial={cleaned_data};
        trial_data.time={times};        
        % Trial info - first column is condition index, second is correct
        % or not, remaining are time of each event or NaN if event does not
        % occur in this trial
        trial_data.trialinfo=ones(1,2+length(exp_info.event_types)).*nan;
        trial_data.trialinfo(1)=find(strcmp(exp_info.conditions,condition));
        trial_data.trialinfo(2)=strcmp(trialinfo.correct{trialinfo.trial==(trial_idx-1)},'True');
        trial_rows=find(events.trial==(trial_idx-1));
        for j=1:length(trial_rows)
            evt_idx=find(strcmp(exp_info.event_types,events.event(trial_rows(j))));
            trial_data.trialinfo(2+evt_idx)=events.time(trial_rows(j))/1000.0;
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

data.fsample=ds_rate;

% Save data
save(fullfile(output_dir, sprintf('%s_%s_lfp.mat', subject, recording_date)), 'data');

if params.plot
    cfg=[];
    ft_databrowser(cfg,data);
end