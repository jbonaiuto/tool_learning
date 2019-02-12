function trial_limits=readTrialStartStopTimes(subject, date)

addpath('/home/bonaiuto/Projects/tool_learning/src/matlab/rhd');

data_dir=fullfile('/home/bonaiuto/Projects/tool_learning/recordings/rhd2000',subject,date);
files=dir(fullfile(data_dir,'*.rhd'));
file_datetimes=[];
for f_idx=1:length(files)
    [~,fname,ext]=fileparts(files(f_idx).name);
    name_parts=strsplit(fname,'_');
    file_datetimes(f_idx)=datenum(name_parts{end},'HHMMSS');
end
[~,sorted_idx]=sort(file_datetimes);

trial_limits=[];

trial_idx=1;

for i=1:length(sorted_idx)
    f_idx=sorted_idx(i);
    [amplifier_data,board_dig_in_data]=read_Intan_RHD2000_file(fullfile(data_dir,files(f_idx).name),0);

    [~,fname,ext]=fileparts(files(f_idx).name);

    srate=30000;
    times=linspace(1/srate,size(amplifier_data,2)/srate,size(amplifier_data,2));

%     figure();
%     for i=1:8
%         subplot(8,1,i);
%         plot(board_dig_in_data(i,:));
%         ylim([-.1 1.1]);
%     end

    % Find trial start/end
    recording_signal=board_dig_in_data(3,:);
    recording_signal_diff=diff(recording_signal);
    trial_start_idx=find(recording_signal_diff==1,1);
    trial_end_idx=find(recording_signal_diff==-1,1);
    trial_limits(trial_idx,1)=times(trial_start_idx);
    trial_limits(trial_idx,2)=times(trial_end_idx);

    trial_idx=trial_idx+1;
end