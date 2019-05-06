function data=preprocess_lfp(exp_info, subject, recording_date)

spm('defaults','eeg');

data_dir=fullfile('/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/recording',...
    subject,recording_date);
addpath('..');
files=read_sorted_rhd_files(data_dir);
rmpath('..');

addpath('../rhd');
addpath('../mulab_data_cleaner');

output_dir=fullfile('/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/output/data/lfp',subject,recording_date);
mkdir(output_dir);

events=readtable(fullfile('/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/preprocessed_data',subject,recording_date,'trial_events.csv'));
trialinfo=readtable(fullfile('/home/bonaiuto/Dropbox/Projects/inProgress/tool_learning/data/preprocessed_data',subject,recording_date,'trial_info.csv'));
% time to cut off at beginning and end of trial due to amplifier ringing (in seconds)
cutoff_window=0.1;

% Downsampled sampling rate
ds_rate=256;

% Concatenated data
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

for i=1:length(files)
    fname=files(i).name
    [~, name, ext]=fileparts(fname);
    
    condition=trialinfo.condition{trialinfo.trial==(i-1)};

    % Read rhd file - get amp data, digital input data, and sampling rate
    [amplifier_data,board_dig_in_data,sample_rate]=read_Intan_RHD2000_file(fullfile(data_dir,fname), false);

    % Number of samples to remove from beginning and end
    window=cutoff_window*sample_rate;

    % Remove window from beginning and end of trial
    amplifier_data=amplifier_data(:,window+1:end-window);

    % Get recording signal
    rec_signal=board_dig_in_data(3,:);
    % Remove window from beginning and end of recording_signal
    rec_signal=rec_signal(window+1:end-window);

    % Skip if erroneous (recording signal is just a one time step blip)
    if length(find(rec_signal==1))>1

        % PCA-based cleaning
        cleaned_data=zeros(size(amplifier_data));
        for array_idx=1:6
            x=CleanData(amplifier_data((array_idx-1)*32+1:array_idx*32,:),0);
            cleaned_data((array_idx-1)*32+1:array_idx*32,:)=x(:,1:end-2)';
        end

        times=[1/sample_rate:1/sample_rate:size(amplifier_data,2)/sample_rate];

        rec_signal_diff = diff(rec_signal);
        trial_start_idx = find(rec_signal_diff == 1);
        trial_start_time = times(trial_start_idx);
        times=times-trial_start_time;

        trial_data.label={};
        for a=1:length(exp_info.array_names)
            for c=1:32
                trial_data.label{end+1}=sprintf('%s_%d',exp_info.array_names{a},c);
            end
        end
        trial_data.fsample=30000;
        trial_data.trial={cleaned_data};
        trial_data.time={times};        
        trial_data.trialinfo=ones(1,2+length(exp_info.event_types)).*nan;
        trial_data.trialinfo(1)=find(strcmp(exp_info.conditions,condition));
        trial_data.trialinfo(2)=strcmp(trialinfo.correct{trialinfo.trial==(i-1)},'True');
        trial_rows=find(events.trial==(i-1));
        for j=1:length(trial_rows)
            evt_idx=find(strcmp(exp_info.event_types,events.event(trial_rows(j))));
            trial_data.trialinfo(2+evt_idx)=events.time(trial_rows(j))/1000.0;
        end
       
        % Lowpass filter
        trial_data.trial{1}=ft_preproc_lowpassfilter(trial_data.trial{1},...
            trial_data.fsample, 100, 6, 'but', 'twopass', 'reduce');

        % Downsample
        cfg=[];
        cfg.resamplefs=256;
        cfg.detrend='yes';
        ds_data=ft_resampledata(cfg, trial_data);

        cleaned_data=ds_data.trial{1};
        % Mean-center
        for chan_idx=1:size(cleaned_data,1)
            chan_data=cleaned_data(chan_idx,:);
            clean_chan_data=clean_jumps(chan_data);
            cleaned_data(chan_idx,:)=clean_chan_data;
        end
        ds_data.trial{1}=cleaned_data;
        
        % Highpass filter
        ds_data.trial{1}=ft_preproc_highpassfilter(ds_data.trial{1},...
            ds_data.fsample, .1, 6, 'but', 'twopass', 'reduce');        
        final_data=ds_data.trial{1};
        
%         for j=1:6
%             figure();
%             for k=1:32
%                 subplot(4,8,k);
%                 hold on
%                 plot([1/sample_rate:1/sample_rate:size(amplifier_data,2)/sample_rate],amplifier_data((j-1)*32+k,:),'b');
%                 plot([1/ds_data.fsample:1/ds_data.fsample:size(final_data,2)/ds_data.fsample],final_data((j-1)*32+k,:),'r');
%             end
%         end
                
        % Append
        cfg=[];
        cfg.keepsampleinfo='no';
        if length(data.trial)>0
            data=ft_appenddata(cfg, data, ds_data);
        else
            data=ds_data;
        end

    end
end

data.fsample=256;

% Save condition data
save(fullfile(output_dir, sprintf('%s_%s_lfp.mat', subject, recording_date)), 'data');
