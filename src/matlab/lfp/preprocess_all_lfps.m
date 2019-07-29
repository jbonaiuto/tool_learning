function preprocess_all_lfps(exp_info, subject, date_start_str)

date_start = datevec(date_start_str, 'dd.mm.yy');
date_now=datenum(now);
   
current_date = date_start;

while datenum(current_date)<= date_now
    date_str = datestr(datenum(current_date),'dd.mm.yy');
    recording_path = fullfile('/media/ferrarilab/2C042E4D35A4CAFF/tool_learning/data/recordings/rhd2000', subject, date_str);
    if exist(recording_path,'dir')==7
        preprocess_lfp(exp_info, subject, date_str);
    end    
    current_date(3) = current_date(3)+1;
    date_now = datenum(now);
end