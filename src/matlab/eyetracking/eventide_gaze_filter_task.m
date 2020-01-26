function [T,X,Y]=eventide_gaze_filter_task(event_channels,tsevs,x,y,sf)

n=max(size(event_channels));
T=cell(n,1);

for i=1:n

    T{i}=int32(tsevs{event_channels(i)}*sf);

end

m=size(T{1},1);
X=cell(n,1);
Y=cell(n,1);

for i=1:m
    
    X{i}=x(T{1}(i):T{2}(i));
    Y{i}=y(T{1}(i):T{2}(i));

end

return
