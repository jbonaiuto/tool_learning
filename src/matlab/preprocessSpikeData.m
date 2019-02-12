function preprocessSpikeData(subject, date)

data_dir=fullfile('/home/bonaiuto/Projects/tool_learning/recordings/rhd2000',subject,date);
files=dir(fullfile(data_dir,'*.rhd'));
file_datetimes=[];
for f_idx=1:length(files)
    [~,fname,ext]=fileparts(files(f_idx).name);
    name_parts=strsplit(fname,'_');
    file_datetimes(f_idx)=datenum(name_parts{end},'HHMMSS');
end
[~,sorted_idx]=sort(file_datetimes);

for i=1:length(sorted_idx)
    f_idx=sorted_idx(i);
    fname=files(f_idx).name;
    [~, name, ext]=fileparts(fname);

    addpath('/home/bonaiuto/Projects/tool_learning/src/matlab/rhd');
    addpath('/home/bonaiuto/Projects/tool_learning/src/matlab/mulab_data_cleaner');

    % Read rhd file - get amp data, digital input data, and sampling rate
    [amplifier_data,board_dig_in_data,sample_rate]=read_Intan_RHD2000_file(fullfile(data_dir,fname), false);

    % time to cut off at beginning and end of trial due to amplifier ringing (in seconds)
    cutoff_window=0.1;

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

        % Median filter (window length=3ms; Michaels et al., 2018)
        winlen=round(0.003*sample_rate)+1;
        filtered_data=medfilt1(amplifier_data,winlen,[],2);
        % Result subtracted from the raw signal, corresponding to a nonlinear high-pass filter (Michaels et al., 2018)
        amplifier_data=amplifier_data-filtered_data;

        % Lowpass filter
        % 4th order Butterworth
        n=4;
        flimit=5000;
        [b,a]=butter(n,2*flimit*2/sample_rate,'low');
        for ch_idx=1:size(amplifier_data,1)
            amplifier_data(ch_idx,:)=filtfilt(b,a,amplifier_data(ch_idx,:));
        end

        % PCA-based cleaning
        cleaned_data=zeros(size(amplifier_data));
        for array_idx=1:6
            x=CleanData(amplifier_data((array_idx-1)*32+1:array_idx*32,:),0);
            cleaned_data((array_idx-1)*32+1:array_idx*32,:)=x(:,1:end-2)';
        end


        % Save truncated recording signal
        save(fullfile(data_dir,sprintf('%s_rec_signal.mat', name)), 'rec_signal');

        % Save preprocessed data
        fid=fopen(fullfile(data_dir,sprintf('%s_preprocessed.raw', name)),'w');
        fwrite(fid,cleaned_data,'float');
        fclose(fid);
    end
end
