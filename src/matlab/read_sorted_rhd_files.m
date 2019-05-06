function files=read_sorted_rhd_files(data_dir)

files=dir(fullfile(data_dir,'*.rhd'));
file_datetimes=[];
for f_idx=1:length(files)
    [~,fname,ext]=fileparts(files(f_idx).name);
    name_parts=strsplit(fname,'_');
    file_datetimes(f_idx)=datenum(name_parts{end},'HHMMSS');
end
[~,sorted_idx]=sort(file_datetimes);
files=files(sorted_idx);
