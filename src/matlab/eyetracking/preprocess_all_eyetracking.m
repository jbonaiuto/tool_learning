function preprocess_all_eyetracking(exp_info, subject, date_start_str)
% PREPROCESS_ALL_EYETRACKING Perform gaze calibration and eye data
% extraction for all days from start date until now
%
% Syntax: preprocess_all_eyetracking(exp_info, subject, date_start_str)
%
% Inputs:
%    exp_info - experimental info data structure (created with
%               init_exp_info.m)
%    subject - subject name
%    date_start_str - start date to process (mm.dd.YY)
%
% Example:
%     preprocess_all_eyetracking(exp_info, 'betta', '26.02.19');

date_start = datevec(date_start_str, 'dd.mm.yy');
date_now=datenum(now);
   
current_date = date_start;

% Possible paths where intan and plexon data can be found
intan_data_dirs={'/media/ferrarilab/2C042E4D35A4CAFF/tool_learning/data/recordings/rhd2000',...
    '/media/ferrarilab/Maxtor/tool_learning/data/recordings/rhd2000'};
plexon_data_dirs={'/media/ferrarilab/2C042E4D35A4CAFF/tool_learning/data/recordings/plexon',...
    '/media/ferrarilab/Maxtor/tool_learning/data/recordings/plexon'};

% From start date until now
while datenum(current_date)<= date_now
    date_str = datestr(datenum(current_date),'dd.mm.yy')
    
    % Find intan files for this day
    intan_recording_path = '';
    for x=1:length(intan_data_dirs)
        potential_path=fullfile(intan_data_dirs{x}, subject, date_str);
        if exist(potential_path,'dir')==7
            intan_recording_path=potential_path;
            break
        end
    end
    
    % Find plexon files for this day
    plexon_recording_path = '';
    for x=1:length(plexon_data_dirs)
        potential_path=fullfile(plexon_data_dirs{x}, subject, date_str);
        if exist(potential_path,'dir')==7
            plexon_recording_path=potential_path;
            break
        end
    end
    
    % If recording exists for this day
    if length(intan_recording_path)>0 && length(plexon_recording_path)>0
        
        % Try t calibrate automatically (success is -1 if no calibration
        % for that day, 0 if unsuccessful, 1 if successful
        gaze_calibration(exp_info, subject, date_str,...
            plexon_recording_path);
        
        % Ask user to accept calibration
        accept=input('Accept?');
        
        % If not accepted, calibrate manually until accepted
        if accept==0
            while accept==0
                gaze_calibration(exp_info, subject, date_str,...
                    plexon_recording_path, 'mode', 'manual');
                accept=input('Accept?');
            end
        end
        % Use calibration to extract gaze data for that day
        extract_gaze_data(exp_info, subject, date_str,...
            plexon_recording_path);
        %plot_eyedata(exp_info, subject, date_str);
    end    
    
    % Advance by 1 day
    current_date(3) = current_date(3)+1;
    date_now = datenum(now);
end