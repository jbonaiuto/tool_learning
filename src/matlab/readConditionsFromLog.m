function conditions=readConditionsFromLog(subject, date)

% Get conditions from log files
log_dir=fullfile('/home/bonaiuto/Projects/tool_learning/logs/',subject);
date=datenum(date,'dd.mm.yy');
log_files=dir(fullfile(log_dir,sprintf('*%s-%d*.csv', datestr(date,'yyyy-dd'), str2num(datestr(date,'mm')))));
log_file_datetimes=[];
for f_idx=1:length(log_files)
    [~,fname,ext]=fileparts(log_files(f_idx).name);
    name_parts=strsplit(fname,'_');
    log_file_datetimes(f_idx)=datenum(name_parts{end},'yyyy-dd-mm--HH-MM');
end

conditions={};
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
                    conditions{trial_idx}=sprintf('%s_%s_%s',name_parts{1},location,action);
                else
                    conditions{trial_idx}=sprintf('%s_%s',name_parts{1},action);
                end
                trial_idx=trial_idx+1;
                last_trial_num=trial_num;
            end

        end
        tline = fgetl(fid);
    end
    fclose(fid);
end
