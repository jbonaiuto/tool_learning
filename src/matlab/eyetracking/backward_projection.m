function table_coord=backward_projection(eyetracker_film_coord)

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
% 
% M=[1 0 0; 0 0 0; 0 1 0; 0 0 1];
% table_coord=inv(proj_mat*ex_mat*M)*[film_coord 1]';
% table_coord=table_coord(1:2)/table_coord(3);

%% First convert from eyetracker film coordinate to monkey camera
%% coordinate
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

M=[1 0 0; 0 1 0; 0 0 projection_plane_z; 0 0 1];
monkey_camera_coord=M*inv(proj_mat*ex_mat*M)*[eyetracker_film_coord 1]';
monkey_camera_coord=[monkey_camera_coord(1:3)/monkey_camera_coord(4)];


%% Then convert from monkey image plane coordinate to table coordinate
%proj_mat=[projection_plane_z 0 0 0; 0 projection_plane_z 0 0; 0 0 1 0];
proj_mat=[1 0 0 0; 0 1 0 0; 0 0 1 0];
trans_mat=[1 0 0 -eye_pos(1); 0 1 0 -eye_pos(2); 0 0 1 -eye_pos(3); 0 0 0 1];
rot_mat=eye(4);
ex_mat=trans_mat*rot_mat;
M=[1 0 0; 0 0 0; 0 1 0; 0 0 1];
table_coord=M*inv(proj_mat*ex_mat*M)*monkey_camera_coord;
table_coord=table_coord(1:3)/table_coord(4);
