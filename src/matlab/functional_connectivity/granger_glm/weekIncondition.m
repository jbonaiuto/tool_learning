function weekIncondition = weekIncondition(condition)

if strcmp(condition{1}, 'fixation' )== true       
weekIncondition = [6	7 8	9 10 11 12 13 14 15 16 17 19 20 21 22 23 24 25 26 27 29 30 31 32 33];
elseif strcmp(condition{1} , 'visual_grasp_left')== true 
weekIncondition = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 47 50 51 53 54];
elseif strcmp(condition{1} , 'visual_pliers_left')== true 
weekIncondition    =[3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 47 53 54];
elseif strcmp(condition{1} , 'visual_rake_pull_left')== true 
weekIncondition =[3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 41 47 53];
elseif strcmp(condition{1} , 'visual_rake_push_left')== true 
weekIncondition =[34	35 36 37 38 39 41];
elseif strcmp(condition{1}, 'visual_stick_left')== true 
weekIncondition   =[33	34 35 36 37 38 39 41];
elseif strcmp(condition{1} , 'motor_grasp_left')== true 
weekIncondition    =[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 19 20 21 22 23 24 25 26 27 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 46 47 50 51 52 53 54 55 56 57];
elseif strcmp(condition{1} , 'motor_rake_left')== true 
weekIncondition   =[8 9 10 11 12 13 14 15 16 19 20 21 22 23 24 25 26 27 29 30 31 33 34 35 36 37 38 39 40 41 42 43 46 47 50 51 52 53 55 56];
elseif strcmp(condition{1} , 'motor_rake_center_catch')== true 
weekIncondition =[11];
elseif strcmp(condition{1} , 'motor_rake_food_left')== true 
weekIncondition =[20	21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 46 47 50 51 52 53 55];
end

end