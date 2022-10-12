%plot behavior by condition-direction-types of movement for Samovar

colors=cbrewer2('qual','Dark2',7);
MoreColors=cbrewer2('qual','Set2',6);

%% plot the overall success rate 
f=figure;
hold

Success=behavior_paper.Success_rate;
plot([1:w_nbr],Success,'k-','LineWidth',2);

%xlabel('week')
%ylabel('%')
xlim([0 w_nbr])
ylim([0 100])
xticks([1:w_nbr])
xticklabels(week_idx);

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllSuccess_paper' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllSuccess_paper' '.eps']),'epsc');


%% plot the OVERALL success  by direction
f=figure;
hold

Aligned_perf=behavior_paper.Hit_A_rate;
L_Right2Left_perf= behavior_paper.Hit_L_Right2Left_rate ;
L_Left2Right_perf= behavior_paper.Hit_L_Left2Right_rate ;
F_Right2Left_perf= behavior_paper.Hit_F_Right2Left_rate ;
F_Left2Right_perf= behavior_paper.Hit_F_Left2Right_rate ;
    
plot([1:w_nbr],Aligned_perf,'Color',[0 0.5 1],'LineWidth',2);
plot([1:w_nbr],L_Right2Left_perf,'Color',colors(1,:),'LineWidth',2);
plot([1:w_nbr],L_Left2Right_perf,'Color',colors(2,:),'LineWidth',2);
plot([1:w_nbr],F_Right2Left_perf,'Color',colors(3,:),'LineWidth',2);
plot([1:w_nbr],F_Left2Right_perf,'Color',colors(4,:),'LineWidth',2);

%xlabel('week')
%ylabel('%')
xlim([0 w_nbr])
ylim([0 100])
xticks([1:w_nbr])
%yticks([0 20 40 60 80 100])
xticklabels(week_idx);
legend('aligned','lateral left','lateral right','forward left','forward right');

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllDirection' '_' 'performance' '_' 'paper' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllDirection' '_' 'performance' '_' 'paper' '.eps']),'epsc');
 

%% plot overall directions proportion
f=figure;
hold 

Aligned_rate=behavior_paper.A_rate;
L_Right2Left_rate= behavior_paper.L_Right2Left_rate ;
L_Left2Right_rate= behavior_paper.L_Left2Right_rate ;
F_Right2Left_rate= behavior_paper.F_Right2Left_rate ;
F_Left2Right_rate= behavior_paper.F_Left2Right_rate ;

plot([1:w_nbr],Aligned_rate,'Color',[0 0.5 1],'LineWidth',2);
plot([1:w_nbr],L_Right2Left_rate,'Color',colors(1,:),'LineWidth',2);
plot([1:w_nbr],L_Left2Right_rate,'Color',colors(2,:),'LineWidth',2);
plot([1:w_nbr],F_Right2Left_rate,'Color',colors(3,:),'LineWidth',2);
plot([1:w_nbr],F_Left2Right_rate,'Color',colors(4,:),'LineWidth',2);
    
% xlabel('week')
% ylabel('%')
xlim([0 w_nbr])
ylim([0 100])
xticks([1:w_nbr])
xticklabels(week_idx);
legend('aligned','lateral left','lateral right','forward left','forward right');

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllDirection' '_' 'proportion' '_' 'paper' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllDirection' '_' 'proportion' '_' 'paper' '.eps']),'epsc'); 

%% plot the OVERALL success  by rake-target distance levels
f=figure;
hold

dist0_perf= behavior_paper.Hit_dist_0_rate ;
dist1_perf= behavior_paper.Hit_dist_1_rate ;
dist2_perf= behavior_paper.Hit_dist_2_rate ;
dist3_perf= behavior_paper.Hit_dist_3_rate ;

plot([1:w_nbr],dist0_perf,'Color',[0 0.5 1],'LineWidth',2);
plot([1:w_nbr],dist1_perf,'Color',colors(5,:),'LineWidth',2);
plot([1:w_nbr],dist2_perf,'Color',colors(6,:),'LineWidth',2);
plot([1:w_nbr],dist3_perf,'Color',colors(7,:),'LineWidth',2);

%xlabel('week')
%ylabel('%')
ylim([0 100])
xlim([0 w_nbr])
xticks([1:w_nbr])
%yticks([0 20 40 60 80 100])
xticklabels(week_idx);
legend('dist 0','dist 1','dist 2','dist 3');

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllDistances' '_' 'performance' '_' 'paper' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllDistances' '_' 'performance' '_' 'paper' '.eps']),'epsc');

%% plot rake-target distance levels proportion
f=figure;
hold

dist0_rate= behavior_paper.dist_0_rate ;
dist1_rate= behavior_paper.dist_1_rate ;
dist2_rate= behavior_paper.dist_2_rate ;
dist3_rate= behavior_paper.dist_3_rate ;

plot([1:w_nbr],dist0_rate,'Color',[0 0.5 1],'LineWidth',2);
plot([1:w_nbr],dist1_rate,'Color',colors(5,:),'LineWidth',2);
plot([1:w_nbr],dist2_rate,'Color',colors(6,:),'LineWidth',2);
plot([1:w_nbr],dist3_rate,'Color',colors(7,:),'LineWidth',2);

%xlabel('week')
%ylabel('%')
xlim([0 w_nbr])
ylim([0 100])
xticks([1:w_nbr])
xticklabels(week_idx);
legend('dist 0','dist 1','dist 2','dist 3');

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllDistances' '_' 'proportion' '_' 'paper' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAllDistances' '_' 'proportion' '_' 'paper' '.eps']),'epsc'); 
 
%% streotyped pulling + multiple attempt 
f=figure;
hold    

stereotyped=behavior_paper.stereotyped_rate;
MultipleAttempts=behavior_paper.MultipleAttempts_rate;
MultipleAttempts_success=behavior_paper.Hit_MultipleAttempts_rate;

plot([1:w_nbr], stereotyped,'LineStyle','-','Color',[0.5 0.5 0.5],'LineWidth',2);
plot([1:w_nbr], MultipleAttempts,'LineStyle','-','Color','k','LineWidth',2);
plot([1:w_nbr], MultipleAttempts_success,'LineStyle','--','Color','k','LineWidth',2);

%xlabel('week')
%ylabel('%')
xlim([0 w_nbr])
ylim([0 50])
xticks([1:w_nbr])
%yticks([0 10 20 30 40 50])
xticklabels(week_idx);
legend('stereotypical pull','multiple attempts','multiple attempts success');

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAll' '_' 'UnderstandingBehavior_paper' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAll' '_' 'UnderstandingBehavior_paper' '.eps']),'epsc');

%% compound reaching, trembling, hitting
f=figure;
hold  

cpd_reach=behavior_paper.v_mvt_rate;
cpd_reach_success=behavior_paper.Hit_v_mvt_rate;

MotorTwitches=behavior_paper.MotorTwitches_rate;
MotorTwitches_success=behavior_paper.Hit_MotorTwitches_rate;

hitting=behavior_paper.kick_rate;
hitting_success=behavior_paper.Hit_kick_rate;

plot([1:w_nbr], cpd_reach,'LineStyle','-','Color','k','LineWidth',2);
plot([1:w_nbr], cpd_reach_success,'LineStyle','--','Color','k','LineWidth',2);
plot([1:w_nbr], MotorTwitches,'LineStyle','-','Color',[0.5 0.5 0.5],'LineWidth',2);
plot([1:w_nbr], MotorTwitches_success,'LineStyle','--','Color',[0.5 0.5 0.5],'LineWidth',2);
plot([1:w_nbr], hitting,'LineStyle','-','Color',[0.75 0.75 0.75],'LineWidth',2);
plot([1:w_nbr], hitting_success,'LineStyle','--','Color',[0.75 0.75 0.75],'LineWidth',2);

%xlabel('week')
%ylabel('%')
xlim([0 w_nbr])
ylim([0 50])
xticks([1:w_nbr])
%yticks([0 10 20 30 40 50])
xticklabels(week_idx);
legend('compound reaching','compound reaching success','trembling','trembling success','hitting','hitting success');

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAll' '_' 'MotorControlBehavior_paper' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'OverAll' '_' 'MotorControlBehavior_paper' '.eps']),'epsc');
 
%% plot the number of slide(beyond trap) + hold (screen) + guided trials
if strcmp(subject,'Betta')
    f=figure;
    hold

    BeyondTrap=behavior_paper.BeyondTrap_rate;
    BeyondTrap_success=behavior_paper.Hit_BeyondTrap_rate;

    screen=behavior_paper.screen_rate;
    screen_success=behavior_paper.Hit_screen_rate;
    
    guided=behavior_paper.guided_rate;

    plot([1:w_nbr], screen,'LineStyle','-','Color',[0.5 0.5 0.5],'LineWidth',2);
    plot([1:w_nbr], screen_success,'LineStyle','--','Color',[0.5 0.5 0.5],'LineWidth',1.5);
    plot([1:w_nbr], guided,'LineStyle','--','Color','k','LineWidth',2);

    %xlabel('weeks')
    %ylabel('%')
    xlim([0 w_nbr])
    ylim([0 100])
    xticks([1:w_nbr])
    %yticks([0 20 40 60 80 100])
    xticklabels(week_idx);
    legend('hold','success','guided');

    saveas(f,fullfile(output_path_fig,...
             [subject '_' 'OverAll' '_' 'ExperimenterBehavior_paper' '.png']));
    saveas(f,fullfile(output_path_fig,...
             [subject '_' 'OverAll' '_' 'ExperimenterBehavior_paper' '.eps']),'epsc');
         
elseif strcmp(subject,'Samovar') 
    f=figure;
    hold

    BeyondTrap=behavior_paper.BeyondTrap_rate;
    BeyondTrap_success=behavior_paper.Hit_BeyondTrap_rate;

    screen=behavior_paper.screen_rate;
    screen_success=behavior_paper.Hit_screen_rate;

    plot([1:w_nbr], BeyondTrap,'LineStyle','-','Color','k','LineWidth',2);
    plot([1:w_nbr], BeyondTrap_success,'LineStyle','--','Color','k','LineWidth',1.5);
    plot([1:w_nbr], screen,'LineStyle','-','Color',[0.5 0.5 0.5],'LineWidth',2);
    plot([1:w_nbr], screen_success,'LineStyle','--','Color',[0.5 0.5 0.5],'LineWidth',1.5);

    %xlabel('weeks')
    %ylabel('%')
    xlim([0 w_nbr])
    ylim([0 100])
    xticks([1:w_nbr])
    %yticks([0 20 40 60 80 100])
    xticklabels(week_idx);
    legend('slide','success','hold','success');

    saveas(f,fullfile(output_path_fig,...
             [subject '_' 'OverAll' '_' 'ExperimenterBehavior_paper' '.png']));
    saveas(f,fullfile(output_path_fig,...
             [subject '_' 'OverAll' '_' 'ExperimenterBehavior_paper' '.eps']),'epsc');
end

%% plot the number of shaft correction
f=figure;
hold

ShaftCorrection=behavior_paper.ShaftCorrection_rate;
ShaftCorrection_success=behavior_paper.Hit_ShaftCorrection_rate;

plot([1:w_nbr], ShaftCorrection,'LineStyle','-','Color','k','LineWidth',2);
plot([1:w_nbr], ShaftCorrection_success,'LineStyle','--','Color','k','LineWidth',1.5);

% xlabel('week')
% ylabel('%')
xlim([0 w_nbr])
ylim([0 50])
xticks([1:w_nbr])
xticklabels(week_idx);
legend('ShaftCorrection',' ShaftCorrection with success');

saveas(f,fullfile(output_path_fig,...
         [subject '_' 'OverAll' '_' 'ShaftCorrection' '.png']));
saveas(f,fullfile(output_path_fig,...
         [subject '_' 'OverAll' '_' 'ShaftCorrection' '.eps']),'epsc');

%% plot hand after trial proportion     
f=figure;    
hold

BackHandle=behavior_paper.HandAfter_BackHandle_rate;
RestRake=behavior_paper.HandAfter_RestRake_rate;
PlaceTarget=behavior_paper.HandAfter_PlaceTarget_rate;
TouchTarget=behavior_paper.HandAfter_TouchTarget_rate;
StillMove=behavior_paper.HandAfter_StillMove_rate;

plot(BackHandle,'LineStyle','-','Color',MoreColors(1,:),'LineWidth',2);
plot(RestRake,'LineStyle','-','Color',MoreColors(2,:),'LineWidth',2);
plot(PlaceTarget,'LineStyle','-','Color',MoreColors(3,:),'LineWidth',2);
plot(TouchTarget,'LineStyle','-','Color',MoreColors(4,:),'LineWidth',2);
plot(StillMove,'LineStyle','-','Color',MoreColors(5,:),'LineWidth',2);
    
%xlabel('week')
%ylabel('%')
xlim([0 w_nbr])
ylim([0 100])
xticks([1:w_nbr])
%yticks([0 20 40 60 80 100])
xticklabels(week_idx);
legend('back to handle','rest on rake','place target manually',...
    'touch target','hand still moving','Location','northwest');

saveas(f,fullfile(output_path_fig,...
          [subject '_' 'OverAll' '_' 'HandAfterTrial_paper' '.png']));
saveas(f,fullfile(output_path_fig,...
         [subject '_' 'OverAll' '_' 'HandAfterTrial_paper' '.eps']),'epsc');
