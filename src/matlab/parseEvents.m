function parseEvents(subject, date)

addpath('/home/bonaiuto/Projects/tool_learning/src/matlab/rhd');

% Get conditions from log files
log_dir=fullfile('/home/bonaiuto/Projects/tool_learning/logs/',subject);
log_files=dir(fullfile(log_dir,sprintf('*%s*.csv',datestr(datenum(date,'dd.mm.yy'),'yyyy-dd-mm'))));
log_file_datetimes=[];
for f_idx=1:length(log_files)
    [~,fname,ext]=fileparts(log_files(f_idx).name);
    name_parts=strsplit(fname,'_');
    log_file_datetimes(f_idx)=datenum(name_parts{end},'yyyy-dd-mm--HH-MM');
end

log_conditions={};
trial_idx=1;

[~,sorted_idx]=sort(log_file_datetimes);
for i=1:length(sorted_idx)
    fname=fullfile(log_dir,log_files(sorted_idx(i)).name);
    name_parts=strsplit(log_files(sorted_idx(i)).name,'_');
    fid = fopen(fname);
    tline = fgetl(fid);
    trials_started=false;
    last_trial_num=-1;
    while ischar(tline)
        if length(tline)==0
            trials_started=true;
            tline = fgetl(fid);
            continue;
        end
        if trials_started
            line_parts=strsplit(tline,',');
            action=line_parts{4};
            if strcmp(action,'Grasping') || strcmp(action,'motor-grasp')
                action='grasp';
            end
            location=line_parts{5};
            trial_num=str2num(line_parts{1});
            if trial_num~=last_trial_num && strcmp(line_parts{6},'StartLaser')
                if strcmp(name_parts{1},'visual')
                    log_conditions{trial_idx}=sprintf('%s_%s_%s',name_parts{1},location,action);
                else
                    log_conditions{trial_idx}=sprintf('%s_%s',name_parts{1},action);
                end
                trial_idx=trial_idx+1;
                last_trial_num=trial_num;
            end
            
        end
        tline = fgetl(fid);
    end
    fclose(fid);
end

    
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
    [amplifier_data,board_dig_in_data]=read_Intan_RHD2000_file(fullfile(data_dir,files(f_idx).name),0);

    [~,fname,ext]=fileparts(files(f_idx).name);

    srate=30000;
    trial_data=[];
    trial_data.times=linspace(1/srate,size(amplifier_data,2)/srate,size(amplifier_data,2));

%     figure();
%     for i=1:8
%         subplot(8,1,i);
%         plot(board_dig_in_data(i,:));
%         ylim([-.1 1.1]);
%     end

    % Figure out pulse code, reward, and error events
    event_sig=bi2de(board_dig_in_data([1 2 4],:)');
%     figure();
%     plot(event_sig);

    % Figure out condition
    pulse_codes=zeros(size(event_sig));
    pulse_codes(find(event_sig==7))=1;
    pulse_code_diff=diff(pulse_codes);
    signal_decreases=find(pulse_code_diff==-1);
    signal_increases=find(pulse_code_diff==1);
    if 0>0 %length(signal_decreases)>0 && length(signal_increases)>0
        start_idx=signal_decreases(1);
        end_idx=signal_increases(end);
        n_pulses=length(intersect(find(signal_increases>start_idx),find(signal_increases<end_idx)));
        if mod(n_pulses,2)==1

            trial_data.condition='';
            switch(n_pulses)
                case 3
                    trial_data.condition='visual_right_grasp';
                case 5
                    trial_data.condition='visual_right_rake_pull';
                case 7
                    trial_data.condition='visual_right_rake_push';
                case 9
                    trial_data.condition='visual_right_pliers';
                case 11
                    trial_data.condition='visual_right_stick';
                case 13
                    trial_data.condition='visual_left_grasp';
                case 15
                    trial_data.condition='visual_left_rake_pull';
                case 17
                    trial_data.condition='visual_left_rake_push';
                case 19
                    trial_data.condition='visual_left_pliers';
                case 21
                    trial_data.condition='visual_left_stick';
                case 23
                    trial_data.condition='motor_grasp';
                case 25
                    trial_data.condition='motor_rake';
            end
        else
            disp(sprintf('********* Not enough pulse codes for %s **********', fname));
            trial_data.condition=log_conditions{i};
        end
    else
        disp(sprintf('********* No pulse code for %s **********', fname));
        trial_data.condition=log_conditions{i};
    end
    % Find trial start/end
    recording_signal=board_dig_in_data(3,:);
    recording_signal_diff=diff(recording_signal);
    trial_start_idx=find(recording_signal_diff==1,1);
    trial_end_idx=find(recording_signal_diff==-1,1);
    trial_data.trial_start=trial_data.times(trial_start_idx);
    trial_data.trial_end=trial_data.times(trial_end_idx);

    % Find reward times
    reward_signal=zeros(size(event_sig));
    reward_signal(find(event_sig(trial_start_idx:trial_end_idx)==5)-1+trial_start_idx)=1;
    reward_signal_diff=diff(reward_signal);
    trial_data.reward_time=trial_data.times(find(reward_signal_diff==1,1));

    % Find error times
    error_signal=zeros(size(event_sig));
    error_signal(find(event_sig(trial_start_idx:trial_end_idx)==3)-1+trial_start_idx)=1;
    error_signal_diff=diff(error_signal);
    trial_data.error_time=trial_data.times(find(error_signal_diff==1,1));

    % Find manual reward times
    manual_reward_signal=zeros(size(event_sig));
    manual_reward_signal(find(event_sig(trial_start_idx:trial_end_idx)==1)-1+trial_start_idx)=1;
    manual_reward_signal_diff=diff(manual_reward_signal);
    trial_data.manual_reward_time=trial_data.times(find(manual_reward_signal_diff==1,1));

    % Find manual error times
    manual_error_signal=zeros(size(event_sig));
    manual_error_signal(find(event_sig(trial_start_idx:trial_end_idx)==6)-1+trial_start_idx)=1;
    manual_error_signal_diff=diff(manual_error_signal);
    trial_data.manual_error_time=trial_data.times(find(manual_error_signal_diff==1,1));

    % Figure out other events
    event_sig=bi2de(board_dig_in_data([4:8],:)');
    %figure();
    %plot(event_sig);

    % Visual task events
    if strcmp(trial_data.condition(1:6),'visual')
        % Laser on
        laser_signal=zeros(size(event_sig));
        laser_signal(find(event_sig==24))=1;
        % 25 if handle is held too?
        laser_signal(find(event_sig==25))=1;
        laser_signal_diff=diff(laser_signal);
        laser_increases=find(laser_signal_diff==1);
        laser_decreases=find(laser_signal_diff==-1);
        if length(laser_increases)>0 && length(laser_decreases)>0
            trial_data.laser_on_time=trial_data.times(laser_increases(1));
            trial_data.laser_off_time=trial_data.times(laser_decreases(end));
        else
            disp(sprintf('********* No laser on/off for %s **********', fname));
        end

        % Grasping center
        grasping_center_signal=zeros(size(event_sig));
        grasping_center_signal(find(event_sig==10))=1;
        grasping_center_signal_diff=diff(grasping_center_signal);
        trial_data.grasping_center_time=trial_data.times(find(grasping_center_signal_diff==1,1));

        % Place left
        place_left_signal=zeros(size(event_sig));
        place_left_signal(find(event_sig==12))=1;
        % 13 if handle is held too
        place_left_signal(find(event_sig==13))=1;
        place_left_signal_diff=diff(place_left_signal);
        place_left_time=trial_data.times(find(place_left_signal_diff==1,1));

        % Place right
        place_right_signal=zeros(size(event_sig));
        place_right_signal(find(event_sig==26))=1;
        % 27 if handle is held too
        place_right_signal(find(event_sig==27))=1;
        place_right_signal_diff=diff(place_right_signal);
        place_right_time=trial_data.times(find(place_right_signal_diff==1,1));        

        if strcmp(trial_data.condition(1:12),'visual_right')
            trial_data.place_time=place_right_time;
        else
            trial_data.place_time=place_left_time;
        end
    else
        % Hold off
        hold_signal=zeros(size(event_sig));
        hold_signal(find(event_sig==1))=1;
        hold_signal_diff=diff(hold_signal);
        trial_data.hold_off_time=trial_data.times(find(hold_signal_diff==-1,1));
    end

    save(fullfile(data_dir,sprintf('%s_evt.mat', fname)),'trial_data');
end