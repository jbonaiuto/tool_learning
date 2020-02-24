function [trial_T,trial_X,trial_Y]=eventide_gaze_filter_task(start_chan, stop_chan, event_data,...
    x, y, fs, matched_start_stop)


start_channel_idx=find(strcmp({event_data.Name},start_chan));
stop_channel_idx=find(strcmp({event_data.Name},stop_chan));

start_times = double(event_data(start_channel_idx).Timestamps)/fs;
stop_times = double(event_data(stop_channel_idx).Timestamps)/fs;

matched_start_times=[];
matched_stop_times=[];
for i=1:length(start_times)
    idx=find(matched_start_stop.matched_start_idx==(i-1));
    stop_idx=matched_start_stop.matched_stop_idx(idx);
    if ~isnan(stop_idx)
        matched_start_times(end+1)=start_times(i);
        matched_stop_times(end+1)=stop_times(stop_idx+1);
    end
end

n_trials= length(matched_start_times);

trial_T = cell(n_trials,1);
trial_X = cell(n_trials,1);
trial_Y = cell(n_trials,1);

for j = 1 : n_trials

    start_time=matched_start_times(j);
    stop_time=matched_stop_times(j);
    
    start_pt=round((start_time-0.050750)*1000)+1;
    stop_pt=round((stop_time-0.050750)*1000)+1;
    
    %t_t=(start_time:1/1000:stop_time)-start_time+0.050750;
    t_t=linspace(0.050750, 0.050750+(stop_time-start_time), stop_pt-start_pt+1)'.*1000;
    if stop_pt<length(x)
        t_x=x(start_pt:stop_pt);
        t_y=y(start_pt:stop_pt);
        trial_X{j} = t_x;
        trial_Y{j} = t_y;
        trial_T{j} = t_t;
    else
        trial_X{j} = [];
        trial_Y{j} = [];
        trial_T{j} = [];
    end
end
