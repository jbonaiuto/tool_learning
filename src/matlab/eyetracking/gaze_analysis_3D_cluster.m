function [ xF,yF,XF,YF ] = gaze_analysis_3D_cluster( file_calibration, file_tasks )

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% D = [-28.2,0,76.9]';
% G = [28.2,0,76.9]';
% GD = [0,0,76.9]';

addpath('plexon-matlab');

e = [-24.0611,-20.4308]';
f = [32.4468,-21.3663]';
d = [-5.5951,-5.3495]';
g = [5.5951,-5.3495]';
gd = [0,-5.3495]'; 
table_x_min = -32.5;
table_x_max = 32.5;
table_y_min = 28.6;
table_y_max = 86.9;
[analog,nevs,tsevs,evnames] = plexon_mat_v3(file_calibration);
x = analog.FP31.frag_1;
y = analog.FP32.frag_1;
n_clusters = 10;
[IDX,C] = kmeans([x,y],n_clusters);
% [T,X,Y]=eventide_gaze_filter_cluster(x,y);
% [T,X,Y]=eventide_gaze_filter_calib([19,20,21],tsevs,x,y,analog.FP31.sampling_freq);
% [T,X,Y]=eventide_gaze_filter([19,20,21],tsevs,x,y,analog.FP31.sampling_freq,3);
n_fix_points = 5;
X = cell(n_fix_points,1);
Y = cell(n_fix_points,1);

for k = 1 : n_fix_points
    
    X{k} = x(IDX == k);
    Y{k} = y(IDX == k);
    
end

n_gaze_points = cell(n_fix_points,1);
XP = cell(n_fix_points,1);
YP = cell(n_fix_points,1);
XF = cell(n_fix_points,1);
YF = cell(n_fix_points,1);

for k = 1 : n_fix_points
    
   n_gaze_points{k} = size(X{k},1);

end

designX = [ones(sum(cell2mat(n_gaze_points),1),1),...
    [repmat(d(1),n_gaze_points{1},1);...
    repmat(g(1),n_gaze_points{2},1);...
    repmat(gd(1),n_gaze_points{3},1)]];
designY = [ones(sum(cell2mat(n_gaze_points),1),1),...
    [repmat(d(2),n_gaze_points{1},1);...
    repmat(g(2),n_gaze_points{2},1);...
    repmat(gd(2),n_gaze_points{3},1)]];
responseX = [X{1};X{2};X{3}];
responseY = [Y{1};Y{2};Y{3}];
[betaX,sigmaX,EX,VX] = mvregress(designX,responseX);
[betaY,sigmaY,EY,VY] = mvregress(designY,responseY);

for k = 1:n_fix_points
    
    XP{k} = (X{k} - betaX(1)) / betaX(2);
    YP{k} = (Y{k} - betaY(1)) / betaY(2);

end

for k = 1 : n_fix_points

   res = eventide2space_gaze(XP{k},YP{k});
   XF{k} = res(1,:)';
   YF{k} = res(3,:)';
   n_gaze_points{k} = size(XP{k},1);

end

% task gaze transformation

[analogt,nevst,tsevst,evnamest] = plexon_mat_v3(file_tasks);
xt = analogt.FP31.frag_1;
yt = analogt.FP32.frag_1;
[Tt,Xt,Yt] = eventide_gaze_filter_task([28,29],tsevst,xt,yt,analogt.FP31.sampling_freq);
n_intervals = size(Xt,1);
xP = cell(n_intervals,1);
yP = cell(n_intervals,1);
xF = cell(n_intervals,1);
yF = cell(n_intervals,1);

for k = 1 : n_intervals
    
    xP{k} = (Xt{k} - betaX(1)) / betaX(2);
    yP{k} = (Yt{k} - betaY(1)) / betaY(2);
    res = eventide2space_gaze(xP{k},yP{k});
    xF{k} = res(1,:)';
    yF{k} = res(3,:)';
    mask = (xF{k} > table_x_min & xF{k} < table_x_max) & (yF{k} > ...
        table_y_min & yF{k} < table_y_max);
    xF{k} = xF{k}(mask);
    yF{k} = yF{k}(mask);

end

return

