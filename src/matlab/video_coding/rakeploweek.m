function [perc1] = rakeplotw(behav) % enter rakeplotw('') in the command line
                                    % this plot the mistakes percentage by
                                    % week during the rake motor learning 

    path = ['/home/gc/Documents/Rake_object_beside/week_number/'];
 
    
colhead = {'Date','Valid trial','Does the task','With cube',...
    'Object_beside','Rake pulled','Rake pushed',...
    'Rake lifted','Rake only grasped','Rake only touched',...
    'Rake toward target','Exp interv.','Miss','Leave cube reachable',...
    'Cube in trap','Place cube','Touch cube','Touch rake head',...
    'Not pulled all the way','Pulled_by_steps'}

percl = contains(colhead,behav)
%path = ['D:\Data\Tooltask\Rake_performance\Cube_in_trap\week_number'];
d = dir([path '*.xlsx']);
%exception=0
for i = 1:length(d)
    % exception=0
    filename = d(i).name;
    num = [];
    [num text raw] = xlsread([path filename]);
    
    maxtrial = length(num);
    overalltrials(i) = maxtrial;
    
    latmovecubetrial = zeros(maxtrial,1);
    latmovecubetrial = zeros(maxtrial,1);
    latmovefoodtrial = zeros(maxtrial,1);
    latmovedonecube = zeros(maxtrial,1);
    latmovedonefood = zeros(maxtrial,1);
    pulldonecube = zeros(maxtrial,1);
    pulldonefood = zeros(maxtrial,1);
    otherdonecube = zeros(maxtrial,1);
    otherdonefood = zeros(maxtrial,1);
    touchcube = zeros(maxtrial,1);
    touchblade = zeros(maxtrial,1);
    leavecube = zeros(maxtrial,1);
    cube = zeros(maxtrial,1);     
    placecube = zeros(maxtrial,1);    
    notpulledalltheway = zeros(maxtrial,1);    
    touchcube = zeros(maxtrial,1);    
    touchrake = zeros(maxtrial,1);

       
    for j = 1:maxtrial
        
        %Valid trials
        logic_valid = cell2mat(raw(2:maxtrial+1,2)) == 1;
        logic_does_the_task = cell2mat(raw(2:maxtrial+1,3)) == 1;
        logic_cube = cell2mat(raw(2:maxtrial+1,4)) == 1;
        logic_obj_beside = cell2mat(raw(2:maxtrial+1,5)) == 1;
        logic_rake_pulled = cell2mat(raw(2:maxtrial+1,6)) == 1;
        logic_food = cell2mat(raw(2:maxtrial+1,4)) == 0;
        
        logic_push = cell2mat(raw(2:maxtrial+1,7)) == 1;  %toward object%
        logic_lift = cell2mat(raw(2:maxtrial+1,8)) == 1;
        logic_grasped = cell2mat(raw(2:maxtrial+1,9)) == 1;
        logic_touched = cell2mat(raw(2:maxtrial+1,10)) == 1;
        logic_latmove = cell2mat(raw(2:maxtrial+1,11)) == 1;  %toward object
        logic_rake_latmove = logic_latmove | logic_push;
        
        logic_exp_interv = cell2mat(raw(2:maxtrial+1,12)) ~= 1;
        
        logic_miss = cell2mat(raw(2:maxtrial+1,13)) ~= 1;
        
        logic_leave_cube_reachable = cell2mat(raw(2:maxtrial+1,14)) == 1;
        logic_cube_in_trap = cell2mat(raw(2:maxtrial+1,15)) == 1;
        logic_place_cube = cell2mat(raw(2:maxtrial+1,16)) == 1;
        logic_touch_cube = cell2mat(raw(2:maxtrial+1,17)) == 1;
        logic_touch_rake = cell2mat(raw(2:maxtrial+1,18)) == 1;
        logic_not_pulled_all_the_way = cell2mat(raw(2:maxtrial+1,19)) == 1;
        logic_pulled_by_steps = cell2mat(raw(2:maxtrial+1,20)) == 1;
        
        %         if logic_valid(j) == 1 & logic_cube(j) == 1 & logic_obj_beside(j) == 1 ...
        %                 & logic_exp_interv(j) == 1 & logic_does_the_task(j) == 1
        %             latmovecubetrial(j) = 1;
        %         end
        %         if logic_valid(j) == 1 & logic_food(j) == 1 & logic_obj_beside(j) == 1 ...
        %                 & logic_exp_interv(j) == 1 & logic_does_the_task(j) == 1
        %             latmovefoodtrial(j) = 1;
        %         end
        %         if logic_valid(j) == 1 & logic_cube(j) == 1 & logic_obj_beside(j) == 1 & logic_rake_latmove(j) == 1 ...
        %                 & logic_exp_interv(j) == 1 & logic_does_the_task(j) == 1
        %             latmovedonecube(j) = 1;
        %         end
        %         if logic_valid(j) == 1 & logic_food(j) == 1 & logic_obj_beside(j) == 1 & logic_rake_latmove(j) == 1 ...
        %                 & logic_exp_interv(j) == 1 & logic_does_the_task(j) == 1
        %             latmovedonefood(j) = 1;
        %         end
        %         if logic_valid(j) == 1 & logic_cube(j) == 1 & logic_obj_beside(j) == 1 & logic_rake_pulled(j) == 1 ...
        %                 & logic_exp_interv(j) == 1 & logic_does_the_task(j) == 1
        %             pulldonecube(j) = 1;
        %         end
        %         if logic_valid(j) == 1 & logic_food(j) == 1 & logic_obj_beside(j) == 1 & logic_rake_pulled(j) == 1 ...
        %                 & logic_exp_interv(j) == 1 & logic_does_the_task(j) == 1
        %             pulldonefood(j) = 1;
        %         end
        %         if logic_valid(j) == 1 & logic_cube(j) == 1 & logic_obj_beside(j) == 1 & ...
        %                 (logic_lift(j) == 1 | logic_grasped(j) == 1 | logic_touched(j) == 1) ...
        %                 & logic_exp_interv(j) == 1 & logic_does_the_task(j) == 1
        %             otherdonecube(j) = 1;
        %         end
        %         if logic_valid(j) == 1 & logic_food(j) == 1 & logic_obj_beside(j) == 1 & ...
        %                 (logic_lift(j) == 1 | logic_grasped(j) == 1 | logic_touched(j) == 1) ...
        %                 & logic_exp_interv(j) == 1 & logic_does_the_task(j) == 1
        %              otherdonefood(j) = 1;
        %         end
        %          if logic_valid(j) == 1 & logic_food(j) == 1 & logic_obj_beside(j) == 1 & ...
        %                  (logic_lift(j) == 1 | logic_grasped(j) == 1 | logic_touched(j) == 1) ...
        %                 & logic_exp_interv(j) == 1 & logic_does_the_task(j) == 1
        %              otherdonefood(j) = 1;
        %         end
        
        
        if logic_does_the_task(j) == 1 & logic_cube(j) == 1
            cube(j) = 1;
        end
        if logic_does_the_task(j) == 1 & logic_cube(j) == 1 & ...%logic_obj_beside(j) == 0 & ...
                logic_place_cube(j) == 1
            placecube(j) = 1;
        end
        if logic_does_the_task(j) == 1 & logic_cube(j) == 1 & ...%logic_obj_beside(j) == 0 & ...
                logic_not_pulled_all_the_way(j) == 1
            notpulledalltheway(j) = 1;
        end
        if logic_does_the_task(j) == 1 & logic_cube(j) == 1 & ...%logic_obj_beside(j) == 0 & ...
                logic_touch_cube(j) == 1
            touchcube(j) = 1;
        end
        if logic_does_the_task(j) == 1 & logic_cube(j) == 1 & ...%logic_obj_beside(j) == 0 & ...
                logic_touch_rake(j) == 1
            touchrake(j) = 1;
        end
        if logic_does_the_task(j) == 1 & logic_cube(j) == 1 & ...%logic_obj_beside(j) == 0 & ...
                logic_leave_cube_reachable(j) == 1
            leavecube(j) = 1;
        end
        
        
        
    end
    
    Valid_cube(i,1) = sum(cube);
    Valid_placecube(i,1) = sum(placecube);
    Valid_not_pulled(i,1) = sum(notpulledalltheway);
    Valid_touchcube(i,1) = sum(touchcube);
    Valid_touchrake(i,1) = sum(touchrake);
    Valid_touch(i,1) = sum(touchrake)+sum(touchcube);
    Valid_leave(i,1) = sum(leavecube);
    %     % Motivation (trials attempted)
    %     Valid_latmovedone_cube(i,1) = sum(latmovedonecube);
    %     Valid_latmovedone_food(i,1) = sum(latmovedonefood);
    %     Valid_latmovedone_all(i,1) = sum(latmovedonecube)+sum(latmovedonefood);
    %
    %     Valid_pulldone_cube(i,1) = sum(pulldonecube);
    %     Valid_pulldone_food(i,1) = sum(pulldonefood);
    %     Valid_pulldone_all(i,1) = sum(pulldonecube)+sum(pulldonefood);
    %
    %     Valid_otherdone_cube(i,1) = sum(otherdonecube);
    %     Valid_otherdone_food(i,1) = sum(otherdonefood);
    %     Valid_otherdone_all(i,1) = sum(otherdonefood)+sum(otherdonefood);
    
    %         Valid_trap_cube(i,1) = sum(trapvalidcube);
    %         Valid_touchblade(i,1) = sum(touchblade);
    %         Valid_touchcube(i,1) = sum(touchcube);
    %         Valid_leavecube(i,1) = sum(leavecube);
    
    date_of_session{i,1} = filename(end-12:end-5);
    
end

percent_place_cube = (Valid_placecube./Valid_cube)*100;
percent_place_cube(isnan(percent_place_cube))=0;
percent_notpulled_cube = (Valid_not_pulled./Valid_cube)*100;
percent_notpulled_cube(isnan(percent_notpulled_cube))=0;
percent_touch_cube = (Valid_touchcube./Valid_cube)*100;
percent_touch_cube(isnan(percent_touch_cube))=0;
percent_touch_rake = (Valid_touchrake./Valid_cube)*100;
percent_touch_rake(isnan(percent_touch_rake))=0;
percent_touch = (Valid_touch./Valid_cube)*100;
percent_touch(isnan(percent_touch))=0;
percent_leave = (Valid_leave./Valid_cube)*100;
percent_leave(isnan(percent_leave))=0;

%end


h=figure(1)
h.Position = [20 50 1000 900]



b = bar([percent_notpulled_cube,percent_leave,percent_touch_rake,percent_touch_cube,percent_place_cube],1);

b(1).FaceColor = 'flat';
b(2).FaceColor = 'flat';
b(3).FaceColor = 'flat';
b(4).FaceColor = 'flat';
b(5).FaceColor = 'flat';
b(1).EdgeColor = 'white';
b(2).EdgeColor = 'white';
b(3).EdgeColor = 'white';
b(4).EdgeColor = 'white';
b(5).EdgeColor = 'white';
for i = 1:length(d)
    b(1).CData(i,:) = [1 .1 0]; 
    b(2).CData(i,:) = [1 .6 0];
    b(3).CData(i,:) = [.9 .9 .2];
    b(4).CData(i,:) = [.1 .9 .5];
    b(5).CData(i,:) = [.1 .2 .9];
end

title('Type of mistakes associated with early rake use');
ylabel('Trial percentage');
xlabel('Week of recording');
xticks(1:length(date_of_session));
xticklabels(strrep(date_of_session,'_',' '));
xtickangle(45);
axis([0 length(d)+1 0 100]);
%legend({'Success Cube';'Attempt Cube';'Attempt Food';'Success Cube'},'Location','northoutside')
legend({'Rake not pulled until the trap';'Leave cube outside trap in reachable space';'Touch rake head at the end of trial';'Touch cube at the end of trial';'Manually place cube in trap'},'Location','northoutside');
%legend({'Mistake (Pulling rake when object is beside)';'Rake movement toward object';'Other Behaviors (lift, grasp or touch)'},'Location','northoutside');

disp(sum(overalltrials));
end

