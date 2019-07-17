function preprocess_all_lfps(exp_info, subject, date_start_str)

date_start = datenum(date_start_str, 'dd.MM.yy');
date_now=datenum(now);

current_date = date_start;
while current_date <= date_now
    date_str = datestr(current_date,'dd.mm.yy');
    recording_path = fullfile('/data/tool_learning/recordings/rhd2000', subject, date_str);
    if exist(recording_path,'dir')==7
        preprocess_lfp(exp_info, subject, date_str);
    end
    current_date = current_date + day(1);
    date_now = datenum(now);
end