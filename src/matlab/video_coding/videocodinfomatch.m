%video codind matching with trial.info
function videocodinfomatch(date)

dbstop if error

date_info = [date(1:end-4) date(end-1:end)];% Felipe helped me on this one
date_info=strrep(date_info,'-','.');

info = readtable(fullfile('C:\Users\kirchher\project\tool_learning\data\preprocessed_data\betta\',sprintf('%s',date_info),'\trial_info.csv')) ;

load(fullfile('C:\Users\kirchher\project\tool_learning\output\video_coding\betta\',sprintf('%s',date),'\trials_categories.mat')) ;
trials_categories = struct2table(trials_categories);


index=strcmp(info.status(1:10),'good') & strcmp(trials_categories.directions,'left to right') ;%| strcmp(info.status,'good') & strcmp(trials_categories.directions,'right to left')
trialsofinterest=find(index);