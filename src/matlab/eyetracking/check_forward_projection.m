function check_forward_projection()

eye_pos=[4.1 23 0];
projection_plane_z=15;
projection_plane_center=eye_pos+[0 0 projection_plane_z];

eyetracker_pos=[4.1 29.5 125];
projection_normal=normalize(eyetracker_pos-eye_pos);

table_corner_1=[-32.25 0 76.9];
table_corner_2=[32.25 0 76.9];
table_corner_3=[32.25 0 18];
table_corner_4=[-32.25 0 18];

monkey_tool_right_pos=table_corner_4+[49.5 0 13.8];
monkey_tool_left_pos=table_corner_4+[15.25 0 14.2];
laser_exp_start_right_pos=table_corner_4+[60.3 0 46];
laser_exp_start_left_pos=table_corner_4+[5.5 0 46];
laser_exp_grasp_center_pos=table_corner_4+[32.6 0 47.2];

table_normal=cross((table_corner_2-table_corner_1),(table_corner_3-table_corner_2));
table_normal=table_normal./sum(table_normal);
d=dot(-table_normal,table_corner_2);

[monkey_tool_right_cam, monkey_tool_right_film]=forward_projection(monkey_tool_right_pos);
[monkey_tool_left_cam, monkey_tool_left_film]=forward_projection(monkey_tool_left_pos);
[laser_exp_start_right_cam, laser_exp_start_right_film]=forward_projection(laser_exp_start_right_pos);
[laser_exp_start_left_cam, laser_exp_start_left_film]=forward_projection(laser_exp_start_left_pos);
[laser_exp_grasp_center_cam, laser_exp_grasp_center_film]=forward_projection(laser_exp_grasp_center_pos);

figure();
hold on
plot3([table_corner_1(1) table_corner_2(1) table_corner_3(1) table_corner_4(1) table_corner_1(1)],...
    [table_corner_1(2) table_corner_2(2) table_corner_3(2) table_corner_4(2) table_corner_1(2)],...
    [table_corner_1(3) table_corner_2(3) table_corner_3(3) table_corner_4(3) table_corner_1(3)]);
scatter3(monkey_tool_right_pos(1), monkey_tool_right_pos(2), monkey_tool_right_pos(3));
scatter3(monkey_tool_left_pos(1), monkey_tool_left_pos(2), monkey_tool_left_pos(3));
scatter3(laser_exp_start_right_pos(1), laser_exp_start_right_pos(2), laser_exp_start_right_pos(3));
scatter3(laser_exp_start_left_pos(1), laser_exp_start_left_pos(2), laser_exp_start_left_pos(3));
scatter3(laser_exp_grasp_center_pos(1), laser_exp_grasp_center_pos(2), laser_exp_grasp_center_pos(3));
scatter3(eye_pos(1), eye_pos(2), eye_pos(3));
scatter3(eyetracker_pos(1), eyetracker_pos(2), eyetracker_pos(3));
plot3([eyetracker_pos(1) eye_pos(1)], [eyetracker_pos(2) eye_pos(2)],...
    [eyetracker_pos(3) eye_pos(3)]);

w=null(projection_normal);
[P,Q]=meshgrid(-20:20);
projX=projection_plane_center(1)+w(1,1)*P+w(1,2)*Q;
projY=projection_plane_center(2)+w(2,1)*P+w(2,2)*Q;
projZ=projection_plane_center(3)+w(3,1)*P+w(3,2)*Q;
plot3([projX(1,1) projX(1,end) projX(end,end) projX(end,1) projX(1,1)],...
    [projY(1,1) projY(1,end) projY(end,end) projY(end,1) projY(1,1)],...
    [projZ(1,1) projZ(1,end) projZ(end,end) projZ(end,1) projZ(1,1)]);

scatter3(projection_plane_center(1)+w(1,1)*monkey_tool_right_film(2)+w(1,2)*monkey_tool_right_film(1),...
    projection_plane_center(2)+w(2,1)*monkey_tool_right_film(2)+w(2,2)*monkey_tool_right_film(1),...
    projection_plane_center(3)+w(3,1)*monkey_tool_right_film(2)+w(3,2)*monkey_tool_right_film(1));
scatter3(projection_plane_center(1)+w(1,1)*monkey_tool_left_film(2)+w(1,2)*monkey_tool_left_film(1),...
    projection_plane_center(2)+w(2,1)*monkey_tool_left_film(2)+w(2,2)*monkey_tool_left_film(1),...
    projection_plane_center(3)+w(3,1)*monkey_tool_left_film(2)+w(3,2)*monkey_tool_left_film(1));
scatter3(projection_plane_center(1)+w(1,1)*laser_exp_start_right_film(2)+w(1,2)*laser_exp_start_right_film(1),...
    projection_plane_center(2)+w(2,1)*laser_exp_start_right_film(2)+w(2,2)*laser_exp_start_right_film(1),...
    projection_plane_center(3)+w(3,1)*laser_exp_start_right_film(2)+w(3,2)*laser_exp_start_right_film(1));
scatter3(projection_plane_center(1)+w(1,1)*laser_exp_start_left_film(2)+w(1,2)*laser_exp_start_left_film(1),...
    projection_plane_center(2)+w(2,1)*laser_exp_start_left_film(2)+w(2,2)*laser_exp_start_left_film(1),...
    projection_plane_center(3)+w(3,1)*laser_exp_start_left_film(2)+w(3,2)*laser_exp_start_left_film(1));
scatter3(projection_plane_center(1)+w(1,1)*laser_exp_grasp_center_film(2)+w(1,2)*laser_exp_grasp_center_film(1),...
    projection_plane_center(2)+w(2,1)*laser_exp_grasp_center_film(2)+w(2,2)*laser_exp_grasp_center_film(1),...
    projection_plane_center(3)+w(3,1)*laser_exp_grasp_center_film(2)+w(3,2)*laser_exp_grasp_center_film(1));
set(gca,'xdir','reverse');
axis equal

figure();
subplot(2,1,1);
hold all
plot([monkey_tool_right_pos(1)],[monkey_tool_right_pos(3)],'o');
plot([monkey_tool_left_pos(1)],[monkey_tool_left_pos(3)],'o');
plot([laser_exp_start_right_pos(1)],[laser_exp_start_right_pos(3)],'o');
plot([laser_exp_start_left_pos(1)],[laser_exp_start_left_pos(3)],'o');
plot([laser_exp_grasp_center_pos(1)],[laser_exp_grasp_center_pos(3)],'o');
axis equal;
subplot(2,1,2);
hold all
plot([monkey_tool_right_film(1)],[monkey_tool_right_film(2)],'o');
plot([monkey_tool_left_film(1)],[monkey_tool_left_film(2)],'o');
plot([laser_exp_start_right_film(1)],[laser_exp_start_right_film(2)],'o');
plot([laser_exp_start_left_film(1)],[laser_exp_start_left_film(2)],'o');
plot([laser_exp_grasp_center_film(1)],[laser_exp_grasp_center_film(2)],'o');
axis equal;