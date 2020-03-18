% Betta dates of Weeks
%
function week=week(x)

load database_management/weeks.mat
temp = daylist(daylist(:,4)==x,1:3);
week= {};
for i = 1:length(temp(:,1))
 week{i}= sprintf('%02d.%02d.%02d', temp(i,1),temp(i,2),temp(i,3));
end


