function gaze_calibration(exp_info, subject, date)
% GAZE_CALIBRATION Perform gaze calibration for a day for a given
% subject. Uses the last calibration data collected for that day
%
% Syntax: gaze_calibration(exp_info, subject, date)
%
% Inputs:
%    exp_info - experimental info data structure (created with
%               init_exp_info.m)
%    subject - subject name
%    date - date strings to load data from (mm.dd.YY)
%
% Example:
%     gaze_calibration(exp_info, 'betta', '26.02.19');


% Channels
calib_target_event_chans={'EVT19','EVT20','EVT21'};
n_clusters=10;

% Position of the monkey's eye
eye_pos=[4.1 23 0];
% Projection plane z coord in front of the monkey
projection_plane_z=15;
% Position of the eyetracker
eyetracker_pos=[4.1 29.5 125];
% Position of the eyetracker projection plane
et_projection_plane_center=eyetracker_pos;
et_projection_plane_center(3)=projection_plane_z;

% Coordinates of the table corners
table_corner_1=[-32.25 0 76.9];
table_corner_2=[32.25 0 76.9];
table_corner_3=[32.25 0 18];
table_corner_4=[-32.25 0 18];

% Laser coordinates
monkey_tool_right_pos=table_corner_4+[49.5 0 13.8];
monkey_tool_left_pos=table_corner_4+[15.25 0 14.2];
laser_exp_start_right_pos=table_corner_4+[60.3 0 46];
laser_exp_start_left_pos=table_corner_4+[5.5 0 46];
laser_exp_grasp_center_pos=table_corner_4+[32.6 0 47.2];

% Load last calibration file for that day
calibration_data_path=fullfile(exp_info.base_data_dir, 'recordings/plexon', subject, date);
files=dir(fullfile(calibration_data_path,sprintf('%s_calibration_%s_*.plx',subject, date)));
file_idx=[];
for f_idx=1:length(files)
    [~,fname,ext]=fileparts(files(f_idx).name);
    name_parts=strsplit(fname,'_');
    file_idx(f_idx)=num2str(name_parts{end});
end
[~,sorted_idx]=sort(file_idx);
files=files(sorted_idx);
plex_data=readPLXFileC(fullfile(calibration_data_path, files(end).name),'all');

% Get x and y channel data
x_chan=find(strcmp({plex_data.ContinuousChannels.Name},'FP31'));
y_chan=find(strcmp({plex_data.ContinuousChannels.Name},'FP32'));
x = double(plex_data.ContinuousChannels(x_chan).Values)/25000;
y = double(plex_data.ContinuousChannels(y_chan).Values)/25000;

% Get eye data during laser flashing
fs=plex_data.ADFrequency;
event_data=plex_data.EventChannels;
[T,X,Y]=eventide_gaze_filter_calib(calib_target_event_chans,event_data,x,y,fs);

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
possible_monkey_tool_right_points=find((x<mean_laser_exp_grasp_center(1)-.5*x_dist) & (y>mean_laser_exp_start_right(2)+.25*x_dist));
% K-means cluster
[IDX,C] = kmeans([x(possible_monkey_tool_right_points),y(possible_monkey_tool_right_points)],n_clusters);
% Find size of each cluster
cluster_sizes=[];
for i=1:n_clusters
    cluster_sizes(i)=length(find(IDX==i));
end
% Find max cluster size
[max_cluster_size,max_cluster_idx]=max(cluster_sizes);
% Get x,y data in max cluster
X{4}=x(possible_monkey_tool_right_points(IDX==max_cluster_idx));
Y{4}=y(possible_monkey_tool_right_points(IDX==max_cluster_idx));
% Exclude outliers
x_nonoutliers=(abs(X{4}-mean(X{4}))<=2.5*std(X{4}));
y_nonoutliers=(abs(Y{4}-mean(Y{4}))<=2.5*std(Y{4}));
nonoutliers_x=X{4}(x_nonoutliers & y_nonoutliers);
nonoutliers_y=Y{4}(x_nonoutliers & y_nonoutliers);
% Get 30 data points closest to centroid
dists=sqrt((nonoutliers_x-C(max_cluster_idx,1)).^2+(nonoutliers_y-C(max_cluster_idx,2)).^2);
[sorted_dists,sorted_idx]=sort(dists);
X{4}=nonoutliers_x(sorted_idx(1:31));
Y{4}=nonoutliers_y(sorted_idx(1:31));

%% Find cluster for monkey tool left laser - above (because data is
%% flipped), and to the left of center
% Distance between center and right
x_dist=mean_laser_exp_start_left(1)-mean_laser_exp_grasp_center(1);
% Find eye positions above center to to the left
possible_monkey_tool_left_points=find((x>mean_laser_exp_grasp_center(1)+.5*x_dist) & (y>mean_laser_exp_start_right(2)+.25*x_dist));
% K-means cluster
[IDX,C] = kmeans([x(possible_monkey_tool_left_points),y(possible_monkey_tool_left_points)],n_clusters);
% Find size of each cluster
cluster_sizes=[];
for i=1:n_clusters
    cluster_sizes(i)=length(find(IDX==i));
end
% Find max cluster size
[max_cluster_size,max_cluster_idx]=max(cluster_sizes);
% Get x,y data in max cluster
X{5}=x(possible_monkey_tool_left_points(IDX==max_cluster_idx));
Y{5}=y(possible_monkey_tool_left_points(IDX==max_cluster_idx));
% Exclude outliers
x_nonoutliers=(abs(X{5}-mean(X{5}))<=2.5*std(X{5}));
y_nonoutliers=(abs(Y{5}-mean(Y{5}))<=2.5*std(Y{5}));
nonoutliers_x=X{5}(x_nonoutliers & y_nonoutliers);
nonoutliers_y=Y{5}(x_nonoutliers & y_nonoutliers);
% Get 30 data points closest to centroid
dists=sqrt((nonoutliers_x-C(max_cluster_idx,1)).^2+(nonoutliers_y-C(max_cluster_idx,2)).^2);
[sorted_dists,sorted_idx]=sort(dists);
X{5}=nonoutliers_x(sorted_idx(1:31));
Y{5}=nonoutliers_y(sorted_idx(1:31));

% Figure out number of targets and gaze points per target
n_targets=length(X);
n_gaze_points = {};
for k = 1 : n_targets
   n_gaze_points{k} = length(X{k});
end

% Backward-project (to table coordinates), gaze data
x_table=[];
y_table=[];
for i=1:length(x)
    res=backward_projection([x(i) y(i)]);
    x_table(i)=res(1);
    y_table(i)=res(3);
end

X_table={};
Y_table={};
for i=1:length(X)
    X_x=[];
    Y_y=[];
    for j=1:length(X{i})
        res=backward_projection([X{i}(j) Y{i}(j)]);
        X_x(j)=res(1);
        Y_y(j)=res(3);
    end
    X_table{i}=X_x';
    Y_table{i}=Y_y';
end

% Find forward projections for each laser
[monkey_tool_right_monk_cam, monkey_tool_right_monk_film, monkey_tool_right_et_cam, monkey_tool_right_et_film]=forward_projection(monkey_tool_right_pos);
[monkey_tool_left_monk_cam, monkey_tool_left_monk_film, monkey_tool_left_et_cam, monkey_tool_left_et_film]=forward_projection(monkey_tool_left_pos);
[laser_exp_start_right_monk_cam, laser_exp_start_right_monk_film, laser_exp_start_right_et_cam, laser_exp_start_right_et_film]=forward_projection(laser_exp_start_right_pos);
[laser_exp_start_left_monk_cam, laser_exp_start_left_monk_film, laser_exp_start_left_et_cam, laser_exp_start_left_et_film]=forward_projection(laser_exp_start_left_pos);
[laser_exp_grasp_center_monk_cam, laser_exp_grasp_center_monk_film, laser_exp_grasp_center_et_cam, laser_exp_grasp_center_et_film]=forward_projection(laser_exp_grasp_center_pos);

% Create target matrix for GLM
designX = [repmat(laser_exp_start_right_pos(1),n_gaze_points{1},1);...
    repmat(laser_exp_start_left_pos(1),n_gaze_points{2},1);...
    repmat(laser_exp_grasp_center_pos(1),n_gaze_points{3},1);...
    repmat(monkey_tool_right_pos(1),n_gaze_points{4},1);...
    repmat(monkey_tool_left_pos(1),n_gaze_points{5},1)];
designY = [repmat(laser_exp_start_right_pos(3),n_gaze_points{1},1);...
    repmat(laser_exp_start_left_pos(3),n_gaze_points{2},1);...
    repmat(laser_exp_grasp_center_pos(3),n_gaze_points{3},1);...
    repmat(monkey_tool_right_pos(3),n_gaze_points{4},1);...
    repmat(monkey_tool_left_pos(3),n_gaze_points{5},1)];

% Create data matrix for GLM
responseX = [X_table{1};X_table{2};X_table{3};X_table{4};X_table{5}];
responseY = [Y_table{1};Y_table{2};Y_table{3};Y_table{4};Y_table{5}];

% GLM
[betaX,~]=robustfit(responseX,designX);
%betaX=regress(designX,[ones(length(designX),1) responseX]);
[betaY,~]=robustfit(responseY,designY);
%betaY=regress(designY,[ones(length(designY),1) responseY]);

% Transform data
transformed_gaze=[betaX(1)+betaX(2)*x_table' betaY(1)+betaY(2)*y_table'];
in_bounds=(transformed_gaze(:,1)>=table_corner_1(1)) & (transformed_gaze(:,1)<=table_corner_2(1)) & (transformed_gaze(:,2)>=table_corner_3(3)) & (transformed_gaze(:,2)<=table_corner_1(3));

out_path=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject, date, 'eyetracking');
mkdir(out_path);

fig=figure();
% Plot raw data and data for each target
subplot(2,2,1);
colors=get(gca,'ColorOrder');
plot(x,y,'.k');
hold all
for i=1:length(X)
    plot(X{i},Y{i},'o','Color',colors(i,:));
end
axis equal
title('Raw Data');

% Plot data and data for each target in table coordinates
subplot(2,2,2);
plot(x_table,y_table,'.k');
hold all
for i=1:length(X_table)
    plot(X_table{i},Y_table{i},'o','Color',colors(i,:));
end
axis equal
title('Projected to Table');

% Plot 3D visualization
subplot(2,2,3);
hold on
% Plot table
plot3([table_corner_1(1) table_corner_2(1) table_corner_3(1) table_corner_4(1) table_corner_1(1)],...
    [table_corner_1(2) table_corner_2(2) table_corner_3(2) table_corner_4(2) table_corner_1(2)],...
    [table_corner_1(3) table_corner_2(3) table_corner_3(3) table_corner_4(3) table_corner_1(3)],'Color','k');
% Plot lasers on table
scatter3(monkey_tool_right_pos(1), monkey_tool_right_pos(2), monkey_tool_right_pos(3),10,colors(4,:));
scatter3(monkey_tool_left_pos(1), monkey_tool_left_pos(2), monkey_tool_left_pos(3),10,colors(5,:));
scatter3(laser_exp_start_right_pos(1), laser_exp_start_right_pos(2), laser_exp_start_right_pos(3),10,colors(1,:));
scatter3(laser_exp_start_left_pos(1), laser_exp_start_left_pos(2), laser_exp_start_left_pos(3),10,colors(2,:));
scatter3(laser_exp_grasp_center_pos(1), laser_exp_grasp_center_pos(2), laser_exp_grasp_center_pos(3),10,colors(3,:));
% Plot eye
scatter3(eye_pos(1), eye_pos(2), eye_pos(3),'r');
% Plot eyetracker
scatter3(eyetracker_pos(1), eyetracker_pos(2), eyetracker_pos(3),'b');
% Plot vector from eyetracker to eye
plot3([eyetracker_pos(1) eye_pos(1)], [eyetracker_pos(2) eye_pos(2)],...
    [eyetracker_pos(3) eye_pos(3)],'k--');

% Plot projection plane
plot3([et_projection_plane_center(1)-20 et_projection_plane_center(1)+20 et_projection_plane_center(1)+20 et_projection_plane_center(1)-20 et_projection_plane_center(1)-20],...
    [et_projection_plane_center(2)-20 et_projection_plane_center(2)-20 et_projection_plane_center(2)+20 et_projection_plane_center(2)+20 et_projection_plane_center(2)-20],...
    [et_projection_plane_center(3) et_projection_plane_center(3) et_projection_plane_center(3) et_projection_plane_center(3) et_projection_plane_center(3)],'Color',colors(6,:));

% Plot projected laser coordinates
scatter3(et_projection_plane_center(1)+monkey_tool_right_et_film(1),...
    et_projection_plane_center(2)+monkey_tool_right_et_film(2),...
    et_projection_plane_center(3),10,colors(4,:));
scatter3(et_projection_plane_center(1)+monkey_tool_left_et_film(1),...
    et_projection_plane_center(2)+monkey_tool_left_et_film(2),...
    et_projection_plane_center(3),10,colors(5,:));
scatter3(et_projection_plane_center(1)+laser_exp_start_right_et_film(1),...
    et_projection_plane_center(2)+laser_exp_start_right_et_film(2),...
    et_projection_plane_center(3),10,colors(1,:));
scatter3(et_projection_plane_center(1)+laser_exp_start_left_et_film(1),...
    et_projection_plane_center(2)+laser_exp_start_left_et_film(2),...
    et_projection_plane_center(3),10,colors(2,:));
scatter3(et_projection_plane_center(1)+laser_exp_grasp_center_et_film(1),...
    et_projection_plane_center(2)+laser_exp_grasp_center_et_film(2),...
    et_projection_plane_center(3),10,colors(3,:));
set(gca,'xdir','reverse');
axis equal
set(gca,'CameraPosition',[467.4467  -66.4519  639.7486]);
set(gca,'CameraTarget', [0 24.7500 62.5000]);
set(gca,'CameraUpVector', [0.0767 0.9925 0.0947]);
set(gca,'CameraViewAngle', 3.8267);

% Plot transformed gaze data and laser positions
subplot(2,2,4);
plot(transformed_gaze(in_bounds,1),transformed_gaze(in_bounds,2),'k.');
hold all
XP = {};
YP = {};
for k = 1:n_targets
    XP{k}=betaX(1)+betaX(2)*X_table{k};
    YP{k}=betaY(1)+betaY(2)*Y_table{k};
    plot(XP{k},YP{k},'o','Color',colors(k,:));
end
circle(laser_exp_start_right_pos(1),laser_exp_start_right_pos(3),5,colors(1,:));
circle(laser_exp_start_left_pos(1),laser_exp_start_left_pos(3),5,colors(2,:));
circle(laser_exp_grasp_center_pos(1),laser_exp_grasp_center_pos(3),5,colors(3,:));
circle(monkey_tool_right_pos(1),monkey_tool_right_pos(3),5,colors(4,:));
circle(monkey_tool_left_pos(1),monkey_tool_left_pos(3),5,colors(5,:));
axis equal
title('Calibrated');
saveas(fig,fullfile(out_path,sprintf('%s_%s_calibration.png', subject, date)),'png');
saveas(fig,fullfile(out_path,sprintf('%s_%s_calibration.eps', subject, date)),'epsc');

% Save calibration
calibration=[];
calibration.betaX=betaX;
calibration.betaY=betaY;
save(fullfile(out_path, sprintf('%s_%s_calibration.mat', subject, date)),'calibration');
