% Betta dates of Weeks
%
function dateInweek = dateInweek(data_dir,nb)

load( fullfile(data_dir,'bettadates.mat'));
day_idx=find([dates{:,2}]== nb);

for i = 1:length(day_idx)
    dateInweek{1,i} = dates{day_idx(i),1};
end

