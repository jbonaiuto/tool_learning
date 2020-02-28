function plot_all_eyedata(exp_info, subject, date_start_str)
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

date_data={};
% From start date until now
while datenum(current_date)<= date_now
    date_str = datestr(datenum(current_date),'dd.mm.yy')
    data_path=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, date_str, 'eyetracking');
    fname=fullfile(data_path, sprintf('%s_%s_eyedata.mat', subject, date_str));
    if exist(fname,'file')==2
        load(fname);
        date_data{end+1}=data;
    end    
    % Advance by 1 day
    current_date(3) = current_date(3)+1;
    date_now = datenum(now);
end

all_data=concatenate_data(date_data);
plot_eyedata(exp_info, all_data, 'type','density');