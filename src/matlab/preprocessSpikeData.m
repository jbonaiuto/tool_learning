function preprocessSpikeData(subject, date)

data_dir=fullfile('/data/tool_learning/recordings/rhd2000',subject,date);
files=dir(fullfile(data_dir,'*.rhd'));
file_datetimes=[];
for f_idx=1:length(files)
    [~,fname,ext]=fileparts(files(f_idx).name);
    name_parts=strsplit(fname,'_');
    file_datetimes(f_idx)=datenum(name_parts{end},'HHMMSS');
end
[~,sorted_idx]=sort(file_datetimes);

addpath('/home/ferrarilab/tool_learning/src/matlab/rhd');

for i=1:length(sorted_idx)
    f_idx=sorted_idx(i);
    fname=files(f_idx).name
    [~, name, ext]=fileparts(fname);

    % Read rhd file - get amp data, digital input data, and sampling rate
    [amplifier_data,board_dig_in_data,sample_rate]=read_Intan_RHD2000_file(fullfile(data_dir,fname), false);

    % Get recording signal
    rec_signal=board_dig_in_data(3,:);
    
    % Skip if erroneous (recording signal is just a one time step blip)
    if length(find(rec_signal==1))>1 && rec_signal(1)<1

        % Save recording signal
        save(fullfile(data_dir,sprintf('%s_rec_signal.mat', name)), 'rec_signal');

    end
end
