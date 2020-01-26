% I know: (a,b);C,D,E,F,G,H,dCO
function [B] = eventide2space_gaze(a,b)

n = size(a,1);
A = zeros(3,n);
W = zeros(3,n);
B = zeros(3,n);
dCO = 15;
C = [0,23,0]';
D = [-28.2,0,76.9]';
E = [-28.2,0,18.8]';
F = [36.3,0,18]';
H = [0,29.5,125]';
% G = [28.2,0,76.9]';
% GD = [0,0,76.9]';
% d = [-5.5951,-5.3495]';
% e = [-24.0611,-20.4308]';
% f = [32.4468,-21.3663]';
% g = [5.5951,-5.3495]';
% gd = [0,-5.3495]'; 
alpha = H - C;
alpha = alpha / sqrt(dot(alpha,alpha));
delta = zeros(3,1);
delta(2) = 1 / sqrt(1 + (alpha(2) / alpha(3))^2);
delta(3) = - delta(2) * alpha(2) / alpha(3);
epsilon = zeros(3,1);
epsilon(1) = 1 / sqrt(1 + (alpha(1) / alpha(3))^2);
epsilon(3) = - epsilon(1) * alpha(1) / alpha(3);
O = C+dCO*alpha;

for k = 1 : n

    A(:,k) = a(k) * epsilon + b(k) * delta + O;
    W(:,k) = ([A(:,k) - C,E - D,E - F]) \ (E - C);
    B(:,k) = C + W(1,k) * (A(:,k)-C);

end

return
