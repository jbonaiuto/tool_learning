function filtered_xy=filter_gaze_data_velocity(x, y)

vel_thresh=.0015;

x_diff=diff(x);
y_diff=diff(y);
vel=sqrt(x_diff.^2+y_diff.^2);
low_vel_pts=find(vel<vel_thresh);

filtered_xy(:,1)=x(low_vel_pts);
filtered_xy(:,2)=y(low_vel_pts);
