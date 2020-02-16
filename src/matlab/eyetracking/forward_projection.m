function [monk_cam_coord, monk_film_coord, et_cam_coord, et_film_coord]=forward_projection(world_coord)

eye_pos=[4.1 23 0];
projection_plane_z=15;
eyetracker_pos=[4.1 29.5 125];

% projection_normal=eyetracker_pos-eye_pos;
% projection_normal=projection_normal./sum(projection_normal);
% proj_mat=[projection_plane_z 0 0 0; 0 projection_plane_z 0 0; 0 0 1 0];
% 
% rot_axis=cross([0 0 1],projection_normal);
% rot_angle=pi/2-dot([0 0 1],projection_normal);
% rot_mat=axang2rotm([rot_axis rot_angle]);
% rot_mat(4,:)=0;
% rot_mat(:,4)=0;
% rot_mat(4,4)=1;
% trans_mat=[1 0 0 -eye_pos(1); 0 1 0 -eye_pos(2); 0 0 1 -eye_pos(3); 0 0 0 1];
% ex_mat=trans_mat*rot_mat;
% camera_coord=ex_mat*[world_coord 1]';
% 
% film_coord=proj_mat*camera_coord;
% film_coord=[film_coord(1)/film_coord(3) film_coord(2)/film_coord(3)];


%% First convert world coordinates to monkey's image plane coordinates
% Transform world coords to monkeys eye-centered coords
trans_mat=[1 0 0 -eye_pos(1); 0 1 0 -eye_pos(2); 0 0 1 -eye_pos(3); 0 0 0 1];
rot_mat=eye(4);
ex_mat=trans_mat*rot_mat;
monk_cam_coord=ex_mat*[world_coord 1]';

% Project to image plane in front of monkey's eye
proj_mat=[projection_plane_z 0 0 0; 0 projection_plane_z 0 0; 0 0 1 0];
monk_film_coord=proj_mat*monk_cam_coord;
monk_film_coord=[monk_film_coord(1)/monk_film_coord(3) monk_film_coord(2)/monk_film_coord(3)];


%% Next convert monkey's image plane coordinates to camera image plane coordinates
projection_normal=(eye_pos-eyetracker_pos);
projection_normal=projection_normal./sqrt(sum(projection_normal.^2));
proj_mat=[eyetracker_pos(3)-projection_plane_z 0 0 0; 0 eyetracker_pos(3)-projection_plane_z 0 0; 0 0 1 0];

rot_axis=cross([0 0 1],projection_normal);
rot_angle=dot([0 0 1],projection_normal);
rot_mat=axang2rotm([rot_axis rot_angle]);
rot_mat(4,:)=0;
rot_mat(:,4)=0;
rot_mat(4,4)=1;
trans_mat=[1 0 0 eye_pos(1)-eyetracker_pos(1); 0 1 0 eye_pos(2)-eyetracker_pos(2); 0 0 1 eye_pos(3)-eyetracker_pos(3); 0 0 0 1];
ex_mat=trans_mat*rot_mat;
et_cam_coord=ex_mat*[[monk_film_coord projection_plane_z]+eye_pos 1]';

% Convert to image plane in front of eyetracking camera
et_film_coord=proj_mat*et_cam_coord;
et_film_coord=[et_film_coord(1)/et_film_coord(3) et_film_coord(2)/et_film_coord(3)];

