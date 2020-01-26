function [T,X,Y] = eventide_gaze_filter_calib(event_channels,tsevs,x,y,sf)

step = 1 * sf;
n = max(size(event_channels));
T = cell(n,1);

for i = 1 : n

    T{i} = int32(tsevs{event_channels(i)} * sf);

end

p = size(T,1);
m = size(T{1},1);
X = cell(p,1);
Y = cell(p,1);

for j = 1 : p

    for i = 1 : m - 1
    
        if (T{j}(i + 1) - T{j}(i)) < step

            X{j} = [X{j}; x(T{j}(i) : T{j}(i + 1))];
            Y{j} = [Y{j}; y(T{j}(i) : T{j}(i + 1))];
        
        end
        
    end

end

return
