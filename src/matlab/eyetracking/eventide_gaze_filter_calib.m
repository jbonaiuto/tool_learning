function [event_times,X,Y] = eventide_gaze_filter_calib(event_channels,...
    event_data, x, y, t, fs, varargin)
%define default values
defaults = struct('mode','automatic');  
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end


flicker_max_dur = 2; %s
n_targets = length(event_channels);

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
    
    if strcmp(params.mode,'automatic')
        if length(last_flicker_times)>2
            t_to_use=length(last_flicker_times)-1;
            if t_to_use==1
                last_flicker_start_time=target_evt_times(1);
                last_flicker_end_time=target_evt_times(last_flicker_times(1));
            else
                last_flicker_start_time=target_evt_times(last_flicker_times(t_to_use-1)+1);
                last_flicker_end_time=target_evt_times(last_flicker_times(t_to_use));
            end        
        else
            last_flicker_start_time=target_evt_times(1);
            last_flicker_end_time=target_evt_times(last_flicker_times(1));
        end
    else
        if length(last_flicker_times)>1
            flicker_t_x={};
            flicker_t_y={};

            fig=figure();
            plot(x,y,'.','Color',[.5 .5 .5]);
            hold all
            labels={'all'};
            for i=1:length(last_flicker_times)
                if i==1
                    last_flicker_start_time=target_evt_times(1);
                    last_flicker_end_time=target_evt_times(last_flicker_times(1));
                else
                    last_flicker_start_time=target_evt_times(last_flicker_times(i-1)+1);
                    last_flicker_end_time=target_evt_times(last_flicker_times(i));
                end
                flick_start=knnsearch(t', last_flicker_start_time*1000+500);
                flick_stop=knnsearch(t', last_flicker_end_time*1000);

                filtered_coords=filter_gaze_data_velocity(x(flick_start:flick_stop), y(flick_start:flick_stop));
                filtered_coords=filter_gaze_data_outliers(filtered_coords(:,1), filtered_coords(:,2));
                flicker_t_x{i}=filtered_coords(:,1);
                flicker_t_y{i}=filtered_coords(:,2);
                plot(t_x,t_y,'.');
                labels{end+1}=num2str(i);
            end
            legend(labels);
            t_to_use=input('Flicker to use:');
            close(fig);
            X{j} = [X{j}; flicker_t_x{t_to_use}];
            Y{j} = [Y{j}; flicker_t_y{t_to_use}];
        else
            t_to_use=1;
        end

        fig=figure();
        ax=subplot(1,1,1);
        plot(x,y,'.','Color',[.5 .5 .5]);
        hold all

        if t_to_use==1
            last_flicker_start_time=target_evt_times(1);
            last_flicker_end_time=target_evt_times(last_flicker_times(1));
        else
            last_flicker_start_time=target_evt_times(last_flicker_times(t_to_use-1)+1);
            last_flicker_end_time=target_evt_times(last_flicker_times(t_to_use));
        end
    end
    
    flick_start=knnsearch(t', last_flicker_start_time*1000+500);
    flick_stop=knnsearch(t', last_flicker_end_time*1000);
    
    vel_filtered_coords=filter_gaze_data_velocity(x(flick_start:flick_stop), y(flick_start:flick_stop));
    filtered_coords=filter_gaze_data_outliers(vel_filtered_coords(:,1), vel_filtered_coords(:,2));
                    
    if strcmp(params.mode,'manual')
        plot(vel_filtered_coords(:,1),vel_filtered_coords(:,2),'.');
        plot(filtered_coords(:,1),filtered_coords(:,2),'.');
        legend({'raw','target data','filtered target data'});
        accept=input('Accept?');
        figure(fig);
        if accept==0
            zoom on;
            pause() % you can zoom with your mouse and when your image is okay, you press any key
            zoom off; % to escape the zoom mode
            figure(fig);
            [coord(1) coord(2)]=getpts(fig);
            rad=input('Radius:');
            zoom out;

            dist=sqrt((vel_filtered_coords(:,1)-coord(1)).^2+(vel_filtered_coords(:,2)-coord(2)).^2);
            filtered_coords=filter_gaze_data_outliers(vel_filtered_coords(dist<=rad,1), vel_filtered_coords(dist<=rad,2));
        end
        close(fig);
    end
    
    X{j} = [X{j}; filtered_coords(:,1)];
    Y{j} = [Y{j}; filtered_coords(:,2)];    
end
