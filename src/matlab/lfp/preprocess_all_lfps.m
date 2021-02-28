function preprocess_all_lfps(exp_info, subject, date_start_str)

date_start = datevec(date_start_str, 'dd.mm.yy');
date_now=datenum(now);
   
current_date = date_start;

intan_data_dirs={'/media/ferrarilab/2C042E4D35A4CAFF/tool_learning/data/recordings/rhd2000',...
    '/media/ferrarilab/Maxtor/tool_learning/data/recordings/rhd2000'};
plexon_data_dirs={'/media/ferrarilab/2C042E4D35A4CAFF/tool_learning/data/recordings/plexon',...
    '/media/ferrarilab/Maxtor/tool_learning/data/recordings/plexon'};

while datenum(current_date)<= date_now
    date_str = datestr(datenum(current_date),'dd.mm.yy');
    intan_recording_path = '';
    for x=1:length(intan_data_dirs)
        potential_path=fullfile(intan_data_dirs{x}, subject, date_str);
        if exist(potential_path,'dir')==7
            intan_recording_path=potential_path;
            break
        end
    end
    plexon_recording_path = '';
    for x=1:length(plexon_data_dirs)
        potential_path=fullfile(plexon_data_dirs{x}, subject, date_str);
        if exist(potential_path,'dir')==7
            plexon_recording_path=potential_path;
            break
        end
    end
    if length(intan_recording_path)>0 && length(plexon_recording_path)>0
        preprocess_lfp(exp_info, subject, date_str);
    end    
    current_date(3) = current_date(3)+1;
    date_now = datenum(now);
end