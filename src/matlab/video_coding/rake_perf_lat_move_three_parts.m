% this plot the lateral movements percentage by
% week during the rake motor learning 

clear all
close all
dbstop if error


data_by_day = 'yes'

if contains(data_by_day,'yes')
    
    path = ['C:\Users\kirchher\project\video_coding\table\rake performance\'];
    %path = ['D:\Data\Tooltask\Rake_performance\Cube_in_trap\'];
    
    d = dir([path '*.xlsx']);
    overalltrials = [];
    for i = 1:length(d)
        
        filename = d(i).name;
        num = [];
        [num text raw] = xlsread([path filename]);
        
        maxtrial = length(num);
        overalltrials(i) = maxtrial;
        
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
        
        for j = 1:maxtrial
            
            %Valid trials
            valid = cell2mat(raw(2:maxtrial+1,2)) == 1;
            does_the_task = cell2mat(raw(2:maxtrial+1,3)) == 1;
            cube = cell2mat(raw(2:maxtrial+1,4)) == 1;
            obj_beside = cell2mat(raw(2:maxtrial+1,5)) == 1;
            rake_pulled = cell2mat(raw(2:maxtrial+1,6)) == 1;
            food = cell2mat(raw(2:maxtrial+1,4)) == 0;
            
            %         rake_move = cell2mat(raw(2:maxtrial+1,11)) == 1;  %toward object
            
            push = cell2mat(raw(2:maxtrial+1,7)) == 1;  %toward object%
            %lift = cell2mat(raw(2:maxtrial+1,8)) == 1;
            grasped = cell2mat(raw(2:maxtrial+1,9)) == 1;
            touched = cell2mat(raw(2:maxtrial+1,10)) == 1;            
            latmove = cell2mat(raw(2:maxtrial+1,11)) == 1;  %toward object                      
            rake_latmove = latmove | push;
            
            exp_interv = cell2mat(raw(2:maxtrial+1,12)) ~= 1;        
            
%             leave_cube_reacheable = cell2mat(raw(2:maxtrial+1,13)) == 1;
%             cube_in_trap = cell2mat(raw(2:maxtrial+1,14)) == 1;
%             touch_cube = cell2mat(raw(2:maxtrial+1,15)) == 1;
%             touch_blade = cell2mat(raw(2:maxtrial+1,16)) == 1;
%             not_pulled_all_the_way = cell2mat(raw(2:maxtrial+1,17)) == 1;
            
            
            if valid(j) == 1 & cube(j) == 1 & obj_beside(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                latmovecubetrial(j) = 1;
            end
            if valid(j) == 1 & food(j) == 1 & obj_beside(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                latmovefoodtrial(j) = 1;
            end
            if valid(j) == 1 & cube(j) == 1 & obj_beside(j) == 1 & rake_latmove(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                latmovedonecube(j) = 1;
            end
            if valid(j) == 1 & food(j) == 1 & obj_beside(j) == 1 & rake_latmove(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                latmovedonefood(j) = 1;
            end
            if valid(j) == 1 & cube(j) == 1 & obj_beside(j) == 1 & rake_pulled(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                pulldonecube(j) = 1;
            end
            if valid(j) == 1 & food(j) == 1 & obj_beside(j) == 1 & rake_pulled(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                pulldonefood(j) = 1;
            end
                        
            if valid(j) == 1 & cube(j) == 1 & obj_beside(j) == 1 & (lift(j) == 1 | grasped(j) == 1 | touched(j) == 1) ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                otherdonecube(j) = 1;
            end
%             if valid(j) == 1 & food(j) == 1 & obj_beside(j) == 1 & (lift(j) == 1 | grasped(j) == 1 | touched(j) == 1) ...
%                     & exp_interv(j) == 1 & does_the_task(j) == 1
%                 
%                 otherdonefood(j) = 1;
%             end
            
            % Cube in trap rule
            
%             
%             if valid(j) == 1 & cube(j) == 1 & exp_interv(j) == 1 & does_the_task(j) == 1 & rake_pulled(j) == 1
%             trapvalidcube(j) = 1;
%             end
%             
%             if valid(j) == 1 & cube(j) == 1 & exp_interv(j) == 1 & does_the_task(j) == 1 & rake_pulled(j) == 1 & touch_blade(j) == 1
%                 touchblade(j) = 1;
%             end
%             if valid(j) == 1 & cube(j) == 1 & exp_interv(j) == 1 & does_the_task(j) == 1 & rake_pulled(j) == 1 & leave_cube_reacheable(j) == 1
%                 leavecube(j) = 1;
%             end    
%             if valid(j) == 1 & cube(j) == 1 & exp_interv(j) == 1 & does_the_task(j) == 1 & rake_pulled(j) == 1 & touch_cube(j) == 1
%                 touchcube(j) = 1;
%                 
%             end
            
            
            
            
            
            
        end
        
        Valid_latmovetrial_cube(i,1) = sum(latmovecubetrial);
        Valid_latmovetrial_food(i,1) = sum(latmovefoodtrial);
        Valid_latmovetrial_all(i,1) = sum(latmovecubetrial)+sum(latmovefoodtrial);
        
        % Motivation (trials attempted)
        Valid_latmovedone_cube(i,1) = sum(latmovedonecube);
        Valid_latmovedone_food(i,1) = sum(latmovedonefood);
        Valid_latmovedone_all(i,1) = sum(latmovedonecube)+sum(latmovedonefood);
        
        Valid_pulldone_cube(i,1) = sum(pulldonecube);
        Valid_pulldone_food(i,1) = sum(pulldonefood);
        Valid_pulldone_all(i,1) = sum(pulldonecube)+sum(pulldonefood);
        
        Valid_otherdone_cube(i,1) = sum(otherdonecube);
        Valid_otherdone_food(i,1) = sum(otherdonefood);
        Valid_otherdone_all(i,1) = sum(otherdonefood)+sum(otherdonefood);
        
%         Valid_trap_cube(i,1) = sum(trapvalidcube);
%         Valid_touchblade(i,1) = sum(touchblade);
%         Valid_touchcube(i,1) = sum(touchcube);
%         Valid_leavecube(i,1) = sum(leavecube);
        
        date_of_session{i,1} = filename(end-14:end-5);
        
    end
    
    percent_latmove_cube = (Valid_latmovedone_cube./Valid_latmovetrial_cube)*100;
    percent_latmove_cube(isnan(percent_latmove_cube))=0;
    percent_latmove_food = (Valid_latmovedone_food./Valid_latmovetrial_food)*100;
    percent_latmove_food(isnan(percent_latmove_food))=0;
    percent_latmove_all = (Valid_latmovedone_all./Valid_latmovetrial_all)*100;
    percent_latmove_all(isnan(percent_latmove_all))=0;
    
    percent_pull_cube = (Valid_pulldone_cube./Valid_latmovetrial_cube)*100;
    percent_pull_cube(isnan(percent_pull_cube))=0;
    percent_pull_food = (Valid_pulldone_food./Valid_latmovetrial_food)*100;
    percent_pull_food(isnan(percent_pull_food))=0;
    percent_pull_all = (Valid_pulldone_all./Valid_latmovetrial_all)*100;
    percent_pull_all(isnan(percent_pull_all))=0;
    
    percent_other_cube = (Valid_otherdone_cube./Valid_latmovetrial_cube)*100;
    percent_other_cube(isnan(percent_pull_cube))=0;
    percent_other_food = (Valid_otherdone_food./Valid_latmovetrial_food)*100;
    percent_other_food(isnan(percent_pull_food))=0;
    percent_other_all = (Valid_otherdone_all./Valid_latmovetrial_all)*100;
    percent_other_all(isnan(percent_pull_all))=0;
    
%     percent_touchcube = (Valid_touchcube./Valid_trap_cube)*100;
%     percent_touchcube(isnan(percent_touchcube))=0;
%     percent_touchblade = (Valid_touchblade./Valid_trap_cube)*100;
%     percent_touchblade(isnan(percent_touchblade))=0;
%     percent_leavecube = (Valid_leavecube./Valid_trap_cube)*100;
%     percent_leavecube(isnan(percent_leavecube))=0;
    
    
    maxdat = 100;
    
    
    xp = (1:length(percent_pull_all))';
    yp = percent_pull_all;
    
    fitpull = fit(xp,yp,'smoothingspline');
    xl = (1:length(percent_latmove_all))';
    yl = percent_latmove_all;
    fitlat = fit(xl,yl,'smoothingspline');
    
    xo = (1:length(percent_other_all))';
    yo = percent_other_all;
    fitoth = fit(xo,yo,'smoothingspline');
    
    xo = (1:length(percent_other_all))';
    yo = percent_other_all;
    fitoth = fit(xo,yo,'smoothingspline');
    
%     xtc = (1:length(percent_touchcube))';
%     ytc = percent_touchcube;
%     fittc = fit(xtc,ytc,'smoothingspline');
%     
%     xtb = (1:length(percent_touchblade))';
%     ytb = percent_touchblade;
%     fittb = fit(xtb,ytb,'smoothingspline');
%     
%     xlc = (1:length(percent_leavecube))';
%     ylc = percent_leavecube;
%     fitlc = fit(xlc,ylc,'smoothingspline');
    
           
    h=figure(3)
    h.Position = [20 50 1000 900]
    
    %figure(3)
    subplot(3,1,1)
    plot(fitpull,xp,yp)
    legend({'Raw Data';'Fitted Data'},'Location','best')
    ylabel('Trial percentage');
    xlabel('Day of recording');
    
    xticks(1:length(date_of_session));
    xticklabels(date_of_session);
    xtickangle(45);
    title('Pulling mistake')
    grid on
    subplot(3,1,2)
    plot(fitlat,xl,yl)
    legend({'Raw Data';'Fitted Data'},'Location','best')
    ylabel('Trial percentage');
    xlabel('Day of recording');
    
    xticks(1:length(date_of_session));
    xticklabels(date_of_session);
    xtickangle(45);
    title('Movement toward object')
    grid on
    subplot(3,1,3)
    plot(fitoth,xo,yo)
    legend({'Raw Data';'Fitted Data'},'Location','best')
    ylabel('Trial percentage');
    xlabel('Day of recording');
    
    xticks(1:length(date_of_session));
    xticklabels(date_of_session);
    xtickangle(45);
    sgtitle('Rake movement by recording days');
    
    title('Other Behaviors')
    grid on
    
    
    h=figure(1)
    h.Position = [20 50 1000 900]
    
    
    
    b = bar([percent_pull_all,percent_latmove_all,percent_other_all],1);
    
    b(1).FaceColor = 'flat';
    b(2).FaceColor = 'flat';
    b(3).FaceColor = 'flat';
    b(1).EdgeColor = 'white';
    b(2).EdgeColor = 'white';
    b(3).EdgeColor = 'white';
    for i = 1:length(d)
        b(2).CData(i,:) = [.1 .1 .9];
        b(1).CData(i,:) = [1 .1 .1];
        b(3).CData(i,:) = [.1 .9 .2];
        
    end
    
    title('Rake movement by recording days');
    ylabel('Trial percentage');
    xlabel('Day of recording');
    xticks(1:length(date_of_session));
    xticklabels(date_of_session);
    xtickangle(45);
    axis([0 length(d)+1 0 100]);
    %legend({'Success Cube';'Attempt Cube';'Attempt Food';'Success Cube'},'Location','northoutside')
    legend({'Mistake (Pulling rake when object is beside)';'Rake movement toward object';'Other Behaviors (lift, grasp or touch)'},'Location','northoutside');
 disp(sum(overalltrials));
 
else
      
     
    path = ['D:\Data\Tooltask\Rake_performance\Rake_object_beside\'];
    d = dir([path '*.xlsx']);
    overalltrials = [];
    week(datetime('29-03-2019','InputFormat','dd-MM-yyyy'));
    
    for w = 10:30
        rawtmp = {'Date','Valid trial','Does the task','With cube','Object_beside','Rake pulled','Rake pushed','Rake lifted',...
            'Rake only grasped','Rake only touched','Rake toward target','Exp interv.'}
        ;
        for i = 1:length(d)
            
            filename = d(i).name;
            num = [];
            [num text raw] = xlsread([path filename]);
            
            if week(datetime(filename(end-14:end-5),'InputFormat','dd-MM-yyyy')) == w;
                
                rawtmp = [rawtmp;raw(2:end,1:12)];
                
                a(i) = w-12;
                if w-12 < 10
                    xlswrite([path 'week_number\Rake_object_beside_week_0' num2str(w-12) '.xlsx'], rawtmp);
                else
                    xlswrite([path 'week_number\Rake_object_beside_week_' num2str(w-12) '.xlsx'], rawtmp);
                end
            end
        end
    end
    
    
    
    
    
    
    
    
    path = ['D:\Data\Tooltask\Rake_performance\Rake_object_beside\week_number\'];
    
    
    d = dir([path '*.xlsx']);
    overalltrials = [];
    for i = 1:length(d)
        
        filename = d(i).name;
        num = [];
        [num text raw] = xlsread([path filename]);
        
        maxtrial = length(num);
        overalltrials(i) = maxtrial;
        
        latmovecubetrial = zeros(maxtrial,1);
        latmovefoodtrial = zeros(maxtrial,1);
        latmovedonecube = zeros(maxtrial,1);
        latmovedonefood = zeros(maxtrial,1);
        pulldonecube = zeros(maxtrial,1);
        pulldonefood = zeros(maxtrial,1);
        otherdonecube = zeros(maxtrial,1);
        otherdonefood = zeros(maxtrial,1);
        
        for j = 1:maxtrial
            
            %Valid trials
            valid = cell2mat(raw(2:maxtrial+1,2)) == 1;
            does_the_task = cell2mat(raw(2:maxtrial+1,3)) == 1;
            cube = cell2mat(raw(2:maxtrial+1,4)) == 1;
            obj_beside = cell2mat(raw(2:maxtrial+1,5)) == 1;
            rake_pulled = cell2mat(raw(2:maxtrial+1,6)) == 1;
            food = cell2mat(raw(2:maxtrial+1,4)) == 0;
            
            %         rake_move = cell2mat(raw(2:maxtrial+1,11)) == 1;  %toward object
            
            push = cell2mat(raw(2:maxtrial+1,7)) == 1;  %toward object%
            lift = cell2mat(raw(2:maxtrial+1,8)) == 1;
            grasped = cell2mat(raw(2:maxtrial+1,9)) == 1;
            touched = cell2mat(raw(2:maxtrial+1,10)) == 1;
            
            latmove = cell2mat(raw(2:maxtrial+1,11)) == 1;  %toward object
            %rake_latmove = latmove
            
            rake_latmove = latmove | push;
            
            exp_interv = cell2mat(raw(2:maxtrial+1,12)) ~= 1;
            
            
            if valid(j) == 1 & cube(j) == 1 & obj_beside(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                latmovecubetrial(j) = 1;
            end
            if valid(j) == 1 & food(j) == 1 & obj_beside(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                latmovefoodtrial(j) = 1;
            end
            if valid(j) == 1 & cube(j) == 1 & obj_beside(j) == 1 & rake_latmove(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                latmovedonecube(j) = 1;
            end
            if valid(j) == 1 & food(j) == 1 & obj_beside(j) == 1 & rake_latmove(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                latmovedonefood(j) = 1;
            end
            if valid(j) == 1 & cube(j) == 1 & obj_beside(j) == 1 & rake_pulled(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                pulldonecube(j) = 1;
            end
            if valid(j) == 1 & food(j) == 1 & obj_beside(j) == 1 & rake_pulled(j) == 1 ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                pulldonefood(j) = 1;
            end
            
            
            if valid(j) == 1 & cube(j) == 1 & obj_beside(j) == 1 & (lift(j) == 1 | grasped(j) == 1 | touched(j) == 1) ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                otherdonecube(j) = 1;
            end
            if valid(j) == 1 & food(j) == 1 & obj_beside(j) == 1 & (lift(j) == 1 | grasped(j) == 1 | touched(j) == 1) ...
                    & exp_interv(j) == 1 & does_the_task(j) == 1
                
                otherdonefood(j) = 1;
            end
            
            
        end
        
        Valid_latmovetrial_cube(i,1) = sum(latmovecubetrial);
        Valid_latmovetrial_food(i,1) = sum(latmovefoodtrial);
        Valid_latmovetrial_all(i,1) = sum(latmovecubetrial)+sum(latmovefoodtrial);
        
        % Motivation (trials attempted)
        Valid_latmovedone_cube(i,1) = sum(latmovedonecube);
        Valid_latmovedone_food(i,1) = sum(latmovedonefood);
        Valid_latmovedone_all(i,1) = sum(latmovedonecube)+sum(latmovedonefood);
        
        Valid_pulldone_cube(i,1) = sum(pulldonecube);
        Valid_pulldone_food(i,1) = sum(pulldonefood);
        Valid_pulldone_all(i,1) = sum(pulldonecube)+sum(pulldonefood);
        
        Valid_otherdone_cube(i,1) = sum(otherdonecube);
        Valid_otherdone_food(i,1) = sum(otherdonefood);
        Valid_otherdone_all(i,1) = sum(otherdonefood)+sum(otherdonefood);
        
        date_of_session{i,1} = strrep(filename(end-11:end-5),'_',' ');
        
    end
    
    percent_latmove_cube = (Valid_latmovedone_cube./Valid_latmovetrial_cube)*100;
    percent_latmove_cube(isnan(percent_latmove_cube))=0;
    percent_latmove_food = (Valid_latmovedone_food./Valid_latmovetrial_food)*100;
    percent_latmove_food(isnan(percent_latmove_food))=0;
    percent_latmove_all = (Valid_latmovedone_all./Valid_latmovetrial_all)*100;
    percent_latmove_all(isnan(percent_latmove_all))=0;
    
    percent_pull_cube = (Valid_pulldone_cube./Valid_latmovetrial_cube)*100;
    percent_pull_cube(isnan(percent_pull_cube))=0;
    percent_pull_food = (Valid_pulldone_food./Valid_latmovetrial_food)*100;
    percent_pull_food(isnan(percent_pull_food))=0;
    percent_pull_all = (Valid_pulldone_all./Valid_latmovetrial_all)*100;
    percent_pull_all(isnan(percent_pull_all))=0;
    
    percent_other_cube = (Valid_otherdone_cube./Valid_latmovetrial_cube)*100;
    percent_other_cube(isnan(percent_pull_cube))=0;
    percent_other_food = (Valid_otherdone_food./Valid_latmovetrial_food)*100;
    percent_other_food(isnan(percent_pull_food))=0;
    percent_other_all = (Valid_otherdone_all./Valid_latmovetrial_all)*100;
    percent_other_all(isnan(percent_pull_all))=0;
    
    %maxdat = max(max([percent_good_cube percent_good_food percent_attempted_cube percent_attempted_food]));
    maxdat = 100;
    
    
    xp = (1:length(percent_pull_all))';
    yp = percent_pull_all;
    
    fitpull = fit(xp,yp,'smoothingspline');
    xl = (1:length(percent_latmove_all))';
    yl = percent_latmove_all;
    fitlat = fit(xl,yl,'smoothingspline');
    
    xo = (1:length(percent_other_all))';
    yo = percent_other_all;
    fitoth = fit(xo,yo,'smoothingspline');
    
    h=figure(3);
    h.Position = [20 50 1000 900];
    
    %figure(3)
    subplot(3,1,1)
    plot(fitpull,xp,yp)
    legend({'Raw Data';'Fitted Data'},'Location','best')
    ylabel('Trial percentage');
    xlabel('Week of recording');
    xticks(1:length(date_of_session));
    xticklabels(date_of_session);
    xtickangle(45);
    axis([1 i -1 101])
    title('Pulling mistake')
    grid on
    subplot(3,1,2)
    plot(fitlat,xl,yl)
    legend({'Raw Data';'Fitted Data'},'Location','best')
    ylabel('Trial percentage');
    
    xlabel('Week of recording');
    xticks(1:length(date_of_session));
    xticklabels(date_of_session);
    xtickangle(45);
    axis([1 i -1 101])
    title('Movement toward object')
    grid on
    subplot(3,1,3)
    plot(fitoth,xo,yo)
    legend({'Raw Data';'Fitted Data'},'Location','best')
    ylabel('Trial percentage');
    
    xlabel('Week of recording');
    xticks(1:length(date_of_session));
    xticklabels(date_of_session);
    xtickangle(45);
    axis([1 i -1 101]);
    sgtitle('Rake movement by recording weeks of stage 2');
    title('Other Behaviors')
    grid on
    
    
    h=figure(1);
    h.Position = [20 50 1000 900];
    %figure(1)
    
    %b = bar([percent_latmove_cube,percent_latmove_food],1);
    %b = bar([percent_pull_all,percent_latmove_all],1);
    b = bar([percent_pull_all,percent_latmove_all,percent_other_all],1);
    
    b(1).FaceColor = 'flat';
    b(2).FaceColor = 'flat';
    b(3).FaceColor = 'flat';
    b(1).EdgeColor = 'white';
    b(2).EdgeColor = 'white';
    b(3).EdgeColor = 'white';
    for i = 1:length(d)
        b(2).CData(i,:) = [.1 .1 .9];
        b(1).CData(i,:) = [1 .1 .1];
        b(3).CData(i,:) = [.1 .9 .2];
        
    end
    
    
    %title('Rake movement by recording weeks of stage 2');
    title('Change in type of rake movements');
    ylabel('Trial percentage');
    xlabel('Week of recording');
    xticks(1:length(date_of_session));
    xticklabels(date_of_session);
    xtickangle(45);
    axis([0 length(d)+1 0 100]);
    %legend({'Success Cube';'Attempt Cube';'Attempt Food';'Success Cube'},'Location','northoutside')
    legend({'Pulling the rake without aiming at the cube';'Aiming at the cube';'Other behaviors with rake (not moving it, lifting it)'},'Location','northoutside');

    disp(sum(overalltrials));
end
% %
