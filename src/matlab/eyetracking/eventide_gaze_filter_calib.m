function [event_times,X,Y] = eventide_gaze_filter_calib(event_channels, event_data,...
    x, y, fs)

flicker_max_dur = .3; %s
n_targets = length(event_channels);
pts_to_use=30;

event_times = cell(n_targets,1);
for i = 1 : n_targets
    event_channel_idx=find(strcmp({event_data.Name},event_channels{i}));
    event_times{i} = double(event_data(event_channel_idx).Timestamps)/fs;
end

X = cell(n_targets,1);
Y = cell(n_targets,1);

for j = 1 : n_targets

    target_evt_times=event_times{j};
    evt_time_diffs=diff(target_evt_times);
    last_flicker_times=find(evt_time_diffs>flicker_max_dur);
    
    t_to_use=length(last_flicker_times)-1;
        
    t=round((target_evt_times(last_flicker_times(t_to_use))-0.050750)*1000)+1;
    t_x=x(t-pts_to_use : t);
    t_y=y(t-pts_to_use : t);

    x_nonoutliers=(abs(t_x-mean(t_x))<=2.5*std(t_x));
    y_nonoutliers=(abs(t_y-mean(t_y))<=2.5*std(t_y));
    nonoutliers=x_nonoutliers & y_nonoutliers;
    X{j} = [X{j}; t_x(nonoutliers)];
    Y{j} = [Y{j}; t_y(nonoutliers)];
end
