% Corelation matrix comparison vs trials weigth 
%
% Thomas Quettier
% 02/2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tnb = trialnb(condition)

% trials info

if strcmp(condition , 'fixation')== true
    sheet = 3;
elseif strcmp(condition , 'visual_grasp_left')== true
    sheet = 4;
elseif strcmp(condition , 'visual_pliers_left')== true 
    sheet = 5;
elseif strcmp(condition , 'visual_rake_pull_left')== true 
    sheet = 6;
elseif strcmp(condition , 'visual_rake_push_left')== true 
    sheet = 7;
elseif strcmp(condition, 'visual_stick_left')== true 
    sheet = 8;
elseif strcmp(condition , 'motor_grasp_left')== true 
    sheet = 9;
elseif strcmp(condition , 'motor_rake_left')== true 
    sheet = 10;
elseif strcmp(condition , 'motor_rake_center_catch')== true 
    sheet = 11;
elseif strcmp(condition , 'motor_rake_food_left')== true 
    sheet = 12;
end


filename = '/Users/thomasquettier/Documents/GitHub/tool_learning/SummaryBetta.xlsx';
  xlRange = 'J3:N42';
trials = xlsread(filename,sheet,xlRange);
tnb = trials(:,5);