function gaze_calibration(exp_info, subject, date,...
    plexon_data_path, varargin)
% GAZE_CALIBRATION Perform gaze calibration for a day for a given
% subject. Uses the last calibration data collected for that day
%
% Syntax: gaze_calibration(exp_info, subject, date, 'mode', 'manual')
%
% Inputs:
%    exp_info - experimental info data structure (created with
%               init_exp_info.m)
%    subject - subject name
%    date - date strings to load data from (mm.dd.YY)
%
% Optional inputs:
%    mode - 'manual' or 'automatic' (automatic by default)
%
% Example:
%     gaze_calibration(exp_info, 'betta', '26.02.19',...
%         '/data/tool_learning/recordings/plexon/betta/26.02.19');

%define default values
defaults = struct('mode','automatic');  
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

addpath('..');

% Channels
calib_target_event_chans={'EVT19','EVT20','EVT21'};
n_clusters=10;

% Projection plane z coord in front of the monkey
projection_plane_f=15;
% Position of the eyetracker projection plane
et_projection_plane_center=exp_info.eyetracker_pos;
et_projection_plane_center(3)=projection_plane_f+exp_info.eye_pos(3);

% Load last calibration file for that day
calibration_data_path=fullfile(plexon_data_path);
files=dir(fullfile(calibration_data_path,sprintf('%s_calibration_%s_*.plx',subject, date)));
file_idx=[];
for f_idx=1:length(files)
    [~,fname,ext]=fileparts(files(f_idx).name);
    name_parts=strsplit(fname,'_');
    file_idx(f_idx)=num2str(name_parts{end});
end
[~,sorted_idx]=sort(file_idx);
files=files(sorted_idx);
if length(files)>0
    plex_data=readPLXFileC(fullfile(calibration_data_path, files(end).name),'all');

    % Get x and y channel data
    x_chan=find(strcmp({plex_data.ContinuousChannels.Name},'FP31'));
    y_chan=find(strcmp({plex_data.ContinuousChannels.Name},'FP32'));
    x = double(plex_data.ContinuousChannels(x_chan).Values)/25000;
    y = double(plex_data.ContinuousChannels(y_chan).Values)/25000;
    start_channel_idx=find(strcmp({plex_data.EventChannels.Name},'Start'));
    fs=plex_data.ADFrequency;
    start_times = double(plex_data.EventChannels(start_channel_idx).Timestamps)/fs;
    t=[];
    for i=1:length(plex_data.ContinuousChannels(x_chan).Fragments)
        frag_length=plex_data.ContinuousChannels(x_chan).Fragments(i);
        frag_start=start_times(i);
        t(end+1:end+frag_length)=linspace(frag_start+1/1000.0, frag_start+double(frag_length)/1000.0, round(frag_length))'.*1000;
    end

    % Get low velocity time points
    x_diff=diff(x);
    y_diff=diff(y);
    vel=sqrt(x_diff.^2+y_diff.^2);
    low_vel_pts=[0; (vel<0.0015)];
    
    % Get eye data during laser flashing
    event_data=plex_data.EventChannels;
    [T,X,Y]=eventide_gaze_filter_calib(calib_target_event_chans,...
        event_data,x,y,t,fs,'mode',params.mode);
    
    % We only have events for 3 lasers, so need to figure out the other 2
    % Find the x,y coordinates of the ones we know
    mean_laser_exp_start_right=[mean(X{1}) mean(Y{1})];
    mean_laser_exp_start_left=[mean(X{2}) mean(Y{2})];
    mean_laser_exp_grasp_center=[mean(X{3}) mean(Y{3})];
    
    %% Find cluster for monkey tool right laser - above (because data is
    %% flipped), and to the right of center
    % Distance between center and right
    x_dist=mean_laser_exp_grasp_center(1)-mean_laser_exp_start_right(1);
    % Find eye positions above center to to the right
    possible_monkey_tool_right_points=find(low_vel_pts & (x<mean_laser_exp_grasp_center(1)-.5*x_dist) & (y>mean_laser_exp_start_right(2)+.25*x_dist));    
    if length(possible_monkey_tool_right_points)<n_clusters || strcmp(params.mode,'manual')
        fig=figure();
        plot(x,y,'.k');
        hold all
        plot(x(possible_monkey_tool_right_points),y(possible_monkey_tool_right_points),'.b');
        axis equal
        zoom on;
        pause() % you can zoom with your mouse and when your image is okay, you press any key
        zoom off; % to escape the zoom mode
        figure(fig);
        rect = getrect(fig);
        close(fig);    
        possible_monkey_tool_right_points=find(low_vel_pts & (x>=rect(1)) & (x<=rect(1)+rect(3)) & (y>=rect(2)) & (y<rect(2)+rect(4)));    
    end
    
    % K-means cluster
    cluster_coords=cluster_within_region(x(possible_monkey_tool_right_points),...
        y(possible_monkey_tool_right_points), n_clusters);
    X{4}=cluster_coords(:,1);
    Y{4}=cluster_coords(:,2);

    %% Find cluster for monkey tool left laser - above (because data is
    %% flipped), and to the left of center
    % Distance between center and right
    x_dist=mean_laser_exp_start_left(1)-mean_laser_exp_grasp_center(1);
    % Find eye positions above center to to the left
    possible_monkey_tool_left_points=find(low_vel_pts & (x>mean_laser_exp_grasp_center(1)+.5*x_dist) & (y>mean_laser_exp_start_right(2)+.25*x_dist));
    if length(possible_monkey_tool_left_points)<n_clusters || strcmp(params.mode,'manual')
        fig=figure();
        plot(x,y,'.k');
        hold all
        plot(x(possible_monkey_tool_left_points),y(possible_monkey_tool_left_points),'.b');
        axis equal
        zoom on;
        pause() % you can zoom with your mouse and when your image is okay, you press any key
        zoom off; % to escape the zoom mode
        figure(fig);
        rect = getrect(fig);
        close(fig);
        possible_monkey_tool_left_points=find(low_vel_pts & (x>=rect(1)) & (x<=rect(1)+rect(3)) & (y>=rect(2)) & (y<rect(2)+rect(4)));    
    end
    
    % K-means cluster
    cluster_coords=cluster_within_region(x(possible_monkey_tool_left_points),...
        y(possible_monkey_tool_left_points), n_clusters);
    X{5}=cluster_coords(:,1);
    Y{5}=cluster_coords(:,2);
    
    % Figure out number of targets and gaze points per target
    n_gaze_points=Inf;
    n_targets=length(X);
    for i=1:n_targets
        if length(X{i})<n_gaze_points
            n_gaze_points=length(X{i});
        end
    end
    for i=1:n_targets
        X{i}=X{i}(1:n_gaze_points);
        Y{i}=Y{i}(1:n_gaze_points);
    end

    % Backward-project (to table coordinates), gaze data
    res=backward_projection([x y]);        
    x_table=res(1,:);
    y_table=res(3,:);

    X_table={};
    Y_table={};
    for i=1:length(X)
        res=backward_projection([X{i} Y{i}]);            
        X_table{i}=res(1,:)';
        Y_table{i}=res(3,:)';
    end

    % Find forward projections for each laser
    [monkey_tool_right_monk_cam, monkey_tool_right_monk_film, monkey_tool_right_et_cam, monkey_tool_right_et_film]=forward_projection(exp_info, exp_info.monkey_tool_right_laser_pos);
    [monkey_tool_left_monk_cam, monkey_tool_left_monk_film, monkey_tool_left_et_cam, monkey_tool_left_et_film]=forward_projection(exp_info, exp_info.monkey_tool_left_laser_pos);
    [laser_exp_start_right_monk_cam, laser_exp_start_right_monk_film, laser_exp_start_right_et_cam, laser_exp_start_right_et_film]=forward_projection(exp_info, exp_info.laser_exp_start_right_laser_pos);
    [laser_exp_start_left_monk_cam, laser_exp_start_left_monk_film, laser_exp_start_left_et_cam, laser_exp_start_left_et_film]=forward_projection(exp_info, exp_info.laser_exp_start_left_laser_pos);
    [laser_exp_grasp_center_monk_cam, laser_exp_grasp_center_monk_film, laser_exp_grasp_center_et_cam, laser_exp_grasp_center_et_film]=forward_projection(exp_info, exp_info.laser_exp_grasp_center_laser_pos);

    % Create target matrix for GLM
    designX = [repmat(exp_info.laser_exp_start_right_laser_pos(1),n_gaze_points,1);...
        repmat(exp_info.laser_exp_start_left_laser_pos(1),n_gaze_points,1);...
        repmat(exp_info.laser_exp_grasp_center_laser_pos(1),n_gaze_points,1);...
        repmat(exp_info.monkey_tool_right_laser_pos(1),n_gaze_points,1);...
        repmat(exp_info.monkey_tool_left_laser_pos(1),n_gaze_points,1)];
    designY = [repmat(exp_info.laser_exp_start_right_laser_pos(3),n_gaze_points,1);...
        repmat(exp_info.laser_exp_start_left_laser_pos(3),n_gaze_points,1);...
        repmat(exp_info.laser_exp_grasp_center_laser_pos(3),n_gaze_points,1);...
        repmat(exp_info.monkey_tool_right_laser_pos(3),n_gaze_points,1);...
        repmat(exp_info.monkey_tool_left_laser_pos(3),n_gaze_points,1)];

    % Create data matrix for GLM
    responseX = [X_table{1};X_table{2};X_table{3};X_table{4};X_table{5}];
    responseY = [Y_table{1};Y_table{2};Y_table{3};Y_table{4};Y_table{5}];

    % GLM
    [betaX,~]=robustfit([responseX.*responseY responseX responseY] ,designX);
    [betaY,~]=robustfit([responseX.*responseY responseX responseY],designY);

    calibration=[];
    calibration.betaX=betaX;
    calibration.betaY=betaY;

    % Transform data
    transformed_gaze=transform_gaze(calibration, [x_table' y_table']);
    in_bounds=(transformed_gaze(:,1)>=exp_info.table_corner_1(1)) & (transformed_gaze(:,1)<=exp_info.table_corner_2(1)) & (transformed_gaze(:,2)>=exp_info.table_corner_3(3)) & (transformed_gaze(:,2)<=exp_info.table_corner_1(3));

    XP = {};
    YP = {};
    for k = 1:n_targets
        transformed_target_gaze=transform_gaze(calibration, [X_table{k} Y_table{k}]);
        XP{k}=transformed_target_gaze(:,1);
        YP{k}=transformed_target_gaze(:,2);
    end

    out_path=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, date, 'eyetracking');
    mkdir(out_path);

    fig=figure();
    % Plot raw data and data for each target
    subplot(2,2,1);
    colors=get(gca,'ColorOrder');
    plot(x,y,'.k');
    hold all
    plot(x(possible_monkey_tool_right_points),y(possible_monkey_tool_right_points),'.b');
    plot(x(possible_monkey_tool_left_points),y(possible_monkey_tool_left_points),'.r');
    for i=1:length(X)
        plot(X{i},Y{i},'o','Color',colors(i,:));
    end
    xlim([-.5 .5])
    ylim([-.5 .5])
    title('Raw Data');

    % Plot data and data for each target in table coordinates
    subplot(2,2,2);
    plot(x_table,y_table,'.k');
    hold all
    plot(x_table(possible_monkey_tool_right_points),y_table(possible_monkey_tool_right_points),'.b');
    plot(x_table(possible_monkey_tool_left_points),y_table(possible_monkey_tool_left_points),'.r');
    for i=1:length(X_table)
        plot(X_table{i},Y_table{i},'o','Color',colors(i,:));
    end
    xlim([3.5 5.5]);
    ylim([28.5 30])
    title('Projected to Table');

    % Plot 3D visualization
    subplot(2,2,3);
    hold on
    % Plot table
    plot3([exp_info.table_corner_1(1) exp_info.table_corner_2(1) exp_info.table_corner_3(1) exp_info.table_corner_4(1) exp_info.table_corner_1(1)],...
        [exp_info.table_corner_1(2) exp_info.table_corner_2(2) exp_info.table_corner_3(2) exp_info.table_corner_4(2) exp_info.table_corner_1(2)],...
        [exp_info.table_corner_1(3) exp_info.table_corner_2(3) exp_info.table_corner_3(3) exp_info.table_corner_4(3) exp_info.table_corner_1(3)],'Color','k');
    % Plot lasers on table
    scatter3(exp_info.monkey_tool_right_laser_pos(1), exp_info.monkey_tool_right_laser_pos(2), exp_info.monkey_tool_right_laser_pos(3),20,colors(4,:));
    scatter3(exp_info.monkey_tool_left_laser_pos(1), exp_info.monkey_tool_left_laser_pos(2), exp_info.monkey_tool_left_laser_pos(3),20,colors(5,:));
    scatter3(exp_info.laser_exp_start_right_laser_pos(1), exp_info.laser_exp_start_right_laser_pos(2), exp_info.laser_exp_start_right_laser_pos(3),20,colors(1,:));
    scatter3(exp_info.laser_exp_start_left_laser_pos(1), exp_info.laser_exp_start_left_laser_pos(2), exp_info.laser_exp_start_left_laser_pos(3),20,colors(2,:));
    scatter3(exp_info.laser_exp_grasp_center_laser_pos(1), exp_info.laser_exp_grasp_center_laser_pos(2), exp_info.laser_exp_grasp_center_laser_pos(3),20,colors(3,:));
    % Plot eye
    scatter3(exp_info.eye_pos(1), exp_info.eye_pos(2), exp_info.eye_pos(3),'r');
    % Plot eyetracker
    scatter3(exp_info.eyetracker_pos(1), exp_info.eyetracker_pos(2), exp_info.eyetracker_pos(3),'b');
    % Plot vector from eyetracker to eye
    plot3([exp_info.eyetracker_pos(1) exp_info.eye_pos(1)], [exp_info.eyetracker_pos(2) exp_info.eye_pos(2)],...
        [exp_info.eyetracker_pos(3) exp_info.eye_pos(3)],'k--');

    % Plot projection plane
    plot3([et_projection_plane_center(1)-20 et_projection_plane_center(1)+20 et_projection_plane_center(1)+20 et_projection_plane_center(1)-20 et_projection_plane_center(1)-20],...
        [et_projection_plane_center(2)-20 et_projection_plane_center(2)-20 et_projection_plane_center(2)+20 et_projection_plane_center(2)+20 et_projection_plane_center(2)-20],...
        [et_projection_plane_center(3) et_projection_plane_center(3) et_projection_plane_center(3) et_projection_plane_center(3) et_projection_plane_center(3)],'Color',colors(6,:));

    % Plot projected laser coordinates
    scatter3(et_projection_plane_center(1)+monkey_tool_right_et_film(1),...
        et_projection_plane_center(2)+monkey_tool_right_et_film(2),...
        et_projection_plane_center(3),20,colors(4,:));
    scatter3(et_projection_plane_center(1)+monkey_tool_left_et_film(1),...
        et_projection_plane_center(2)+monkey_tool_left_et_film(2),...
        et_projection_plane_center(3),20,colors(5,:));
    scatter3(et_projection_plane_center(1)+laser_exp_start_right_et_film(1),...
        et_projection_plane_center(2)+laser_exp_start_right_et_film(2),...
        et_projection_plane_center(3),20,colors(1,:));
    scatter3(et_projection_plane_center(1)+laser_exp_start_left_et_film(1),...
        et_projection_plane_center(2)+laser_exp_start_left_et_film(2),...
        et_projection_plane_center(3),20,colors(2,:));
    scatter3(et_projection_plane_center(1)+laser_exp_grasp_center_et_film(1),...
        et_projection_plane_center(2)+laser_exp_grasp_center_et_film(2),...
        et_projection_plane_center(3),20,colors(3,:));
    set(gca,'xdir','reverse');
    axis equal
    set(gca,'CameraPosition',[467.4467  -66.4519  639.7486]);
    set(gca,'CameraTarget', [0 24.7500 62.5000]);
    set(gca,'CameraUpVector', [0.0767 0.9925 0.0947]);
    set(gca,'CameraViewAngle', 3.8267);

    % Plot transformed gaze data and laser positions
    ax=subplot(2,2,4);
    plot(transformed_gaze(in_bounds,1),transformed_gaze(in_bounds,2),'.','Color',[.5 .5 .5]);
    hold all
    for k = 1:n_targets
        plot(XP{k},YP{k},'o','Color',colors(k,:));
    end
    plot_table(exp_info, ax);
    title('Calibrated');
    saveas(fig,fullfile(out_path,sprintf('%s_%s_calibration.png', subject, date)),'png');
    saveas(fig,fullfile(out_path,sprintf('%s_%s_calibration.eps', subject, date)),'epsc');

    % Save calibration
    save(fullfile(out_path, sprintf('%s_%s_calibration.mat', subject, date)),'calibration');
end