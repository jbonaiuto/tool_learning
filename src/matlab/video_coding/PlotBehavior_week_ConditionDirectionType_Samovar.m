%plot behavior by condition-direction-types of movement for Samovar

%insert the table layout with rake and target starting zone with highlight
%for each cond-direction movement

DatesLabels={'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21','08.07.21','09.07.21','13.07.21','14.07.21',...
    '15.07.21','16.07.21','27.07.21','28.07.21','29.07.21','30.07.21','03.08.21','04.08.21','10.08.21','11.08.21','12.08.21','13.08.21','17.08.21','18.08.21',...
    '19.08.21','20.08.21','24.08.21','25.08.21','27.08.21','31.08.21','01.09.21','02.09.21','03.09.21','07.09.21','09.09.21','10.09.21','14.09.21','15.09.21',...
    '17.09.21','21.09.21','22.09.21','23.09.21','24.09.21','29.09.21','30.09.21','01.10.21','05.10.21','06.10.21','07.10.21','08.10.21','11.10.21','12.10.21',...
    '13.10.21','14.10.21','26.10.21','27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'};

% stage2=8.5;
% stage3=14.5;

%plot the overall success rate + the number of trial by direction
            figure
            hold

            Success=Behavior_week_DirCond.Success_rate;

            Aligned=Behavior_week_DirCond.Hit_day_l_A_rate + Behavior_week_DirCond.Hit_day_c_A_rate + Behavior_week_DirCond.Hit_day_r_A_rate ;
            L_Right2Left=Behavior_week_DirCond.Hit_day_l_L_Right2Left_rate + Behavior_week_DirCond.Hit_day_c_L_Right2Left_rate + Behavior_week_DirCond.Hit_day_r_L_Right2Left_rate ;
            L_Left2Right=Behavior_week_DirCond.Hit_day_l_L_Left2Right_rate + Behavior_week_DirCond.Hit_day_c_L_Left2Right_rate + Behavior_week_DirCond.Hit_day_r_L_Left2Right_rate ;
            R_Right2Left=Behavior_week_DirCond.Hit_day_l_R_Right2Left_rate + Behavior_week_DirCond.Hit_day_c_R_Right2Left_rate + Behavior_week_DirCond.Hit_day_r_R_Right2Left_rate ;
            R_Left2Right=Behavior_week_DirCond.Hit_day_l_R_Left2Right_rate + Behavior_week_DirCond.Hit_day_c_R_Left2Right_rate + Behavior_week_DirCond.Hit_day_r_R_Left2Right_rate ;


            y=[Aligned L_Right2Left, L_Left2Right, R_Right2Left, R_Left2Right];
            dir=bar(y,'stacked');
            dir(1).FaceColor=[0.4660 0.6740 0.1880];
             dir(2).FaceColor=[0.8500 0.3250 0.0980];
              dir(3).FaceColor=[0.9290 0.6940 0.1250];
               dir(4).FaceColor=[0 0.4470 0.7410];
                dir(5).FaceColor=[0.3010 0.7450 0.9330];

              Aligned_nbr=Behavior_week_DirCond.l_A_nbr + Behavior_week_DirCond.c_A_nbr + Behavior_week_DirCond.r_A_nbr ;
            L_Right2Left_nbr=Behavior_week_DirCond.l_L_Right2Left_nbr + Behavior_week_DirCond.c_L_Right2Left_nbr + Behavior_week_DirCond.r_L_Right2Left_nbr ;
            L_Left2Right_nbr=Behavior_week_DirCond.l_L_Left2Right_nbr + Behavior_week_DirCond.c_L_Left2Right_nbr + Behavior_week_DirCond.r_L_Left2Right_nbr ;
            R_Right2Left_nbr=Behavior_week_DirCond.l_R_Right2Left_nbr + Behavior_week_DirCond.c_R_Right2Left_nbr + Behavior_week_DirCond.r_R_Right2Left_nbr ;
            R_Left2Right_nbr=Behavior_week_DirCond.l_R_Left2Right_nbr + Behavior_week_DirCond.c_R_Left2Right_nbr + Behavior_week_DirCond.r_R_Left2Right_nbr ;   

        %      trial_nbr=[Aligned_nbr L_Right2Left_nbr L_Left2Right_nbr R_Right2Left_nbr R_Left2Right_nbr] ;
        %   
        %         for i=1:5
        %             if i==1 
        %                 text(dir(i).XData,dir(i).YEndPoints/2,num2str(trial_nbr(:,i)), ...
        %                 'HorizontAlalign','center','fontsize',6,'color','k')
        %             else
        %                 text(dir(i).XData(find(dir(i).YData)),dir(i-1).YEndPoints(find(dir(i).YData))+...
        %                     (dir(i).YEndPoints(find(dir(i).YData))-dir(i-1).YEndPoints(find(dir(i).YData)))/2,...
        %                     num2str(trial_nbr((find(dir(i).YData)),i)), 'HorizontAlalign','center','fontsize',6,'color','k')
        %             end
        %         end

            xlabel('weeks')
            xticks([1:w_nbr])
            ylabel('success(%)')
            ylim([0 100])
            xticklabels(week_idx);
            xtickangle(45)
            legend('Aligned','L Right2Left','L Left2Right','R Right2Left','R Left2Right','Location','southwestoutside','FontSize',10)
            title([subject ' ' 'OVERALL success and movement direction trial']);
    
    %plot the overall success rate + the number of trial by difficulties   
            figure
            hold

            Success=Behavior_week_DirCond.Success_rate;

            diff0=Behavior_week_DirCond.Hit_day_diff_0_rate;
            diff1=Behavior_week_DirCond.Hit_day_diff_1_rate;
            diff2=Behavior_week_DirCond.Hit_day_diff_2_rate;
            diff3=Behavior_week_DirCond.Hit_day_diff_3_rate;

            y=[diff0 diff1, diff2, diff3];
            diff=bar(y,'stacked');
            diff(1).FaceColor=[0.4660 0.6740 0.1880];
             diff(2).FaceColor=[0.8500 0.3250 0.0980];
              diff(3).FaceColor=[0.9290 0.6940 0.1250];
               diff(4).FaceColor=[0 0.4470 0.7410];

            xlabel('weeks')
            xticks([1:w_nbr])
            ylabel('success(%)')
            ylim([0 100])
            xticklabels(week_idx);
            xtickangle(45)
            legend('difficulty 0','difficulty 1','difficulty 2','difficulty 3','not guided trial','Location','southwestoutside','FontSize',10)
            title([subject ' ' 'OVERALL success by difficulties']);
    
%plot the OVERALL condition success  by direction
    figure
    hold
    
    Aligned=Behavior_week_DirCond.Hit_A_rate;
    L_Right2Left= Behavior_week_DirCond.Hit_L_Right2Left_rate ;
    L_Left2Right= Behavior_week_DirCond.Hit_L_Left2Right_rate ;
    R_Right2Left= Behavior_week_DirCond.Hit_R_Right2Left_rate ;
    R_Left2Right= Behavior_week_DirCond.Hit_R_Left2Right_rate ;
    
    subplot(5,1,1)
        plot([1:w_nbr],Aligned,'Color',[0.4660 0.6740 0.1880],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'Aligned']);

    subplot(5,1,2)
        plot([1:w_nbr],L_Right2Left,'Color',[0.8500 0.3250 0.0980],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'L Right2Left']);
    
    subplot(5,1,3)
        plot([1:w_nbr],L_Left2Right,'Color',[0.9290 0.6940 0.1250],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'L Left2Right']);
        
    subplot(5,1,4)
        plot([1:w_nbr],R_Right2Left,'Color',[0 0.4470 0.7410],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'R Right2Left']);
        
    subplot(5,1,5)
        plot([1:w_nbr],R_Left2Right,'Color',[0.3010 0.7450 0.9330],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'R Left2Right']); 
        
%plot the OVERALL condition success  by difficulties
    figure
    hold
  
    difficulty0= Behavior_week_DirCond.Hit_diff_0_rate ;
    difficulty1= Behavior_week_DirCond.Hit_diff_1_rate ;
    difficulty2= Behavior_week_DirCond.Hit_diff_2_rate ;
    difficulty3= Behavior_week_DirCond.Hit_diff_3_rate ;
  
    subplot(4,1,1)
        plot([1:w_nbr],difficulty0,'Color',[0.4660 0.6740 0.1880],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'difficulty 0']);

    subplot(4,1,2)
        plot([1:w_nbr],difficulty1,'Color',[0.8500 0.3250 0.0980],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'difficulty 1']);
    
    subplot(4,1,3)
        plot([1:w_nbr],difficulty2,'Color',[0.9290 0.6940 0.1250],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'difficulty 2']);
        
    subplot(4,1,4)
        plot([1:w_nbr],difficulty3,'Color',[0 0.4470 0.7410],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'difficulty 3']);
        
%plot the LEFT condition success  by direction
    figure
    hold
    
    l_Aligned=Behavior_week_DirCond.Hit_l_A_rate;
    l_L_Right2Left= Behavior_week_DirCond.Hit_l_L_Right2Left_rate ;
    l_L_Left2Right= Behavior_week_DirCond.Hit_l_L_Left2Right_rate ;
    l_R_Right2Left= Behavior_week_DirCond.Hit_l_R_Right2Left_rate ;
    l_R_Left2Right= Behavior_week_DirCond.Hit_l_R_Left2Right_rate ;
    
    subplot(5,1,1)
        plot([1:w_nbr],l_Aligned,'Color',[0.4660 0.6740 0.1880],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'l Aligned']);

    subplot(5,1,2)
        plot([1:w_nbr],l_L_Right2Left,'Color',[0.8500 0.3250 0.0980],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'l L Right2Left']);
    
    subplot(5,1,3)
        plot([1:w_nbr],l_L_Left2Right,'Color',[0.9290 0.6940 0.1250],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'l L Left2Right']);
        
    subplot(5,1,4)
        plot([1:w_nbr],l_R_Right2Left,'Color',[0 0.4470 0.7410],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'l R Right2Left']);
        
    subplot(5,1,5)
        plot([1:w_nbr],l_R_Left2Right,'Color',[0.3010 0.7450 0.9330],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'l R Left2Right']);    

%plot the CENTER condition success  by direction
    figure
    hold
    
    c_Aligned= Behavior_week_DirCond.Hit_c_A_rate ;
    c_L_Right2Left= Behavior_week_DirCond.Hit_c_L_Right2Left_rate ;
    c_L_Left2Right= Behavior_week_DirCond.Hit_c_L_Left2Right_rate ;
    c_R_Right2Left= Behavior_week_DirCond.Hit_c_R_Right2Left_rate ;
    c_R_Left2Right= Behavior_week_DirCond.Hit_c_R_Left2Right_rate ;

    subplot(5,1,1)
        plot([1:w_nbr],c_Aligned,'Color',[0.4660 0.6740 0.1880],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'c Aligned']);

    subplot(5,1,2)
        plot([1:w_nbr],c_L_Right2Left,'Color',[0.8500 0.3250 0.0980],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'c L Right2Left']);
    
    subplot(5,1,3)
        plot([1:w_nbr],c_L_Left2Right,'Color',[0.9290 0.6940 0.1250],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'c L Left2Right']);
        
    subplot(5,1,4)
        plot([1:w_nbr],c_R_Right2Left,'Color',[0 0.4470 0.7410],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'c R Right2Left']);
        
    subplot(5,1,5)
        plot([1:w_nbr],c_R_Left2Right,'Color',[0.3010 0.7450 0.9330],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'c R Left2Right']); 

%plot the RIGHT condition success  by direction
    figure
    hold
     
    r_Aligned= Behavior_week_DirCond.Hit_r_A_rate ;
    r_L_Right2Left= Behavior_week_DirCond.Hit_r_L_Right2Left_rate ;
    r_L_Left2Right= Behavior_week_DirCond.Hit_r_L_Left2Right_rate ;
    r_R_Right2Left= Behavior_week_DirCond.Hit_r_R_Right2Left_rate ;
    r_R_Left2Right= Behavior_week_DirCond.Hit_r_R_Left2Right_rate ;
    
    subplot(5,1,1)
        plot([1:w_nbr],r_Aligned,'Color',[0.4660 0.6740 0.1880],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'r Aligned']);

    subplot(5,1,2)
        plot([1:w_nbr],r_L_Right2Left,'Color',[0.8500 0.3250 0.0980],'LineWidth',2);
       xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'r L Right2Left']);
    
    subplot(5,1,3)
        plot([1:w_nbr],r_L_Left2Right,'Color',[0.9290 0.6940 0.1250],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'r L Left2Right']);
        
    subplot(5,1,4)
        plot([1:w_nbr],r_R_Right2Left,'Color',[0 0.4470 0.7410],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'r R Right2Left']);
        
    subplot(5,1,5)
        plot([1:w_nbr],r_R_Left2Right,'Color',[0.3010 0.7450 0.9330],'LineWidth',2);
        xlabel('weeks')
        xticks([1:w_nbr])
        ylabel('success(%)')
        ylim([0 100])
        xlim([0 w_nbr])
        xticklabels(week_idx);
        xtickangle(45)
%         xline(stage2,':',{'stage 2'});
%         xline(stage3,':',{'stage 3'});
        title([subject ' ' 'r R Left2Right']); 
        
        
        
    
    
%plot LEFT condition success rate and part of each direction + the number of trial by direction
    figure
    hold
    d%ates=Behavior_week_DirCond.date;
    
    %Hit_Left=Behavior_DirCond.Hit_day_Left_rate;
    Hit_Left=Behavior_week_DirCond.Hit_Left_rate;
    
    %plot([1:days_nbr],Hit_Left,'k','LineWidth',2);
    
    
%     Aligned=Behavior_DirCond.Hit_day_l_A_rate ;
%     L_Right2Left=Behavior_DirCond.Hit_day_l_L_Right2Left_rate ;
%     L_Left2Right=Behavior_DirCond.Hit_day_l_L_Left2Right_rate ;
%     R_Right2Left=Behavior_DirCond.Hit_day_l_R_Right2Left_rate ;
%     R_Left2Right=Behavior_DirCond.Hit_day_l_R_Left2Right_rate ;
    
    Aligned=Behavior_week_DirCond.Hit_cond_l_A_rate ;
    L_Right2Left=Behavior_week_DirCond.Hit_cond_l_L_Right2Left_rate ;
    L_Left2Right=Behavior_week_DirCond.Hit_cond_l_L_Left2Right_rate ;
    R_Right2Left=Behavior_week_DirCond.Hit_cond_l_R_Right2Left_rate ;
    R_Left2Right=Behavior_week_DirCond.Hit_cond_l_R_Left2Right_rate ;
    
    
    y=[Aligned L_Right2Left, L_Left2Right, R_Right2Left, R_Left2Right];
    dir=bar(y,'stacked');
    dir(1).FaceColor=[0.4660 0.6740 0.1880];
     dir(2).FaceColor=[0.8500 0.3250 0.0980];
      dir(3).FaceColor=[0.9290 0.6940 0.1250];
       dir(4).FaceColor=[0 0.4470 0.7410];
        dir(5).FaceColor=[0.3010 0.7450 0.9330];
        
     trial_nbr=[Behavior_week_DirCond.l_A_nbr Behavior_week_DirCond.l_L_Right2Left_nbr ...
         Behavior_week_DirCond.l_L_Left2Right_nbr Behavior_week_DirCond.l_R_Right2Left_nbr Behavior_week_DirCond.l_R_Left2Right_nbr] ;
  
        for i=1:5
            if i==1 
                text(dir(i).XData,dir(i).YEndPoints/2,num2str(trial_nbr(:,i)), ...
                'HorizontAlalign','center','fontsize',6,'color','k')
            else
                text(dir(i).XData(find(dir(i).YData)),dir(i-1).YEndPoints(find(dir(i).YData))+...
                    (dir(i).YEndPoints(find(dir(i).YData))-dir(i-1).YEndPoints(find(dir(i).YData)))/2,...
                    num2str(trial_nbr((find(dir(i).YData)),i)), 'HorizontAlalign','center','fontsize',6,'color','k')
            end
        end
        
    xlabel('weeks')
    xticks([1:w_nbr])
    ylabel('success(%)')
    %ylim([0 50])
    ylim([0 100])
    xticklabels(week_idx);
    xtickangle(45)

%     xline(stage2,':',{'stage 2'});
%     xline(stage3,':',{'stage 3'});
    
     legend('Aligned','L Right2Left','L Left2Right','R Right2Left','R Left2Right','Location','southwestoutside','FontSize',10)
     title([subject ' ' 'LEFT condition success rate and movement direction part in day success']);
    
 %plot CENTER condition success rate and part of each direction + the number of trial by direction
    figure
    hold
    %dates=Behavior_week_DirCond.date;
    
    %Hit_Center=Behavior_DirCond.Hit_day_Center_rate;
    Hit_Center=Behavior_week_DirCond.Hit_Center_rate;
    
    %plot([1:days_nbr],Hit_Center,'k','LineWidth',2);
    
    
%     Aligned=Behavior_DirCond.Hit_day_c_A_rate ;
%     L_Right2Left=Behavior_DirCond.Hit_day_c_L_Right2Left_rate ;
%     L_Left2Right=Behavior_DirCond.Hit_day_c_L_Left2Right_rate ;
%     R_Right2Left=Behavior_DirCond.Hit_day_c_R_Right2Left_rate ;
%     R_Left2Right=Behavior_DirCond.Hit_day_c_R_Left2Right_rate ;
    
    Aligned=Behavior_week_DirCond.Hit_cond_c_A_rate ;
    L_Right2Left=Behavior_week_DirCond.Hit_cond_c_L_Right2Left_rate ;
    L_Left2Right=Behavior_week_DirCond.Hit_cond_c_L_Left2Right_rate ;
    R_Right2Left=Behavior_week_DirCond.Hit_cond_c_R_Right2Left_rate ;
    R_Left2Right=Behavior_week_DirCond.Hit_cond_c_R_Left2Right_rate ;
    
    y=[Aligned L_Right2Left, L_Left2Right, R_Right2Left, R_Left2Right];
    dir=bar(y,'stacked');
    dir(1).FaceColor=[0.4660 0.6740 0.1880];
     dir(2).FaceColor=[0.8500 0.3250 0.0980];
      dir(3).FaceColor=[0.9290 0.6940 0.1250];
       dir(4).FaceColor=[0 0.4470 0.7410];
        dir(5).FaceColor=[0.3010 0.7450 0.9330];
        
     trial_nbr=[Behavior_week_DirCond.c_A_nbr Behavior_week_DirCond.c_L_Right2Left_nbr ...
         Behavior_week_DirCond.c_L_Left2Right_nbr Behavior_week_DirCond.c_R_Right2Left_nbr Behavior_week_DirCond.c_R_Left2Right_nbr] ;
  
        for i=1:5
            if i==1 
                text(dir(i).XData,dir(i).YEndPoints/2,num2str(trial_nbr(:,i)), ...
                'HorizontAlalign','center','fontsize',6,'color','k')
            else
                text(dir(i).XData(find(dir(i).YData)),dir(i-1).YEndPoints(find(dir(i).YData))+...
                    (dir(i).YEndPoints(find(dir(i).YData))-dir(i-1).YEndPoints(find(dir(i).YData)))/2,...
                    num2str(trial_nbr((find(dir(i).YData)),i)), 'HorizontAlalign','center','fontsize',6,'color','k')
            end
        end   
 

    
    xlabel('weeks')
    xticks([1:w_nbr])
    ylabel('success(%)')
    ylim([0 100])
    
    xticklabels(week_idx);
    xtickangle(45)

%     xline(stage2,':',{'stage 2'});
%     xline(stage3,':',{'stage 3'});
    
    legend('Aligned','L Right2Left','L Left2Right','R Right2Left','R Left2Right','Location','southwestoutside','FontSize',10)
    title([subject ' ' 'CENTER condition success rate and movement direction part in day success']);
    
 %plot RIGHT condition success rate and part of each direction + the number of trial by direction
    figure
    hold
    %dates=Behavior_week_DirCond.date;
    
    %Hit_Right=Behavior_DirCond.Hit_day_Right_rate;
    Hit_Right=Behavior_week_DirCond.Hit_Right_rate;
    
    %plot([1:days_nbr],Hit_Right,'k','LineWidth',2);
    
    
%     Aligned=Behavior_DirCond.Hit_day_r_A_rate ;
%     L_Right2Left=Behavior_DirCond.Hit_day_r_L_Right2Left_rate ;
%     L_Left2Right=Behavior_DirCond.Hit_day_r_L_Left2Right_rate ;
%     R_Right2Left=Behavior_DirCond.Hit_day_r_R_Right2Left_rate ;
%     R_Left2Right=Behavior_DirCond.Hit_day_r_R_Left2Right_rate ;
    
    Aligned=Behavior_week_DirCond.Hit_cond_r_A_rate ;
    L_Right2Left=Behavior_week_DirCond.Hit_cond_r_L_Right2Left_rate ;
    L_Left2Right=Behavior_week_DirCond.Hit_cond_r_L_Left2Right_rate ;
    R_Right2Left=Behavior_week_DirCond.Hit_cond_r_R_Right2Left_rate ;
    R_Left2Right=Behavior_week_DirCond.Hit_cond_r_R_Left2Right_rate ;
    
    y=[Aligned L_Right2Left, L_Left2Right, R_Right2Left, R_Left2Right];
    dir=bar(y,'stacked');
    dir(1).FaceColor=[0.4660 0.6740 0.1880];
     dir(2).FaceColor=[0.8500 0.3250 0.0980];
      dir(3).FaceColor=[0.9290 0.6940 0.1250];
       dir(4).FaceColor=[0 0.4470 0.7410];
        dir(5).FaceColor=[0.3010 0.7450 0.9330];
        
     trial_nbr=[Behavior_week_DirCond.r_A_nbr Behavior_week_DirCond.r_L_Right2Left_nbr ...
         Behavior_week_DirCond.r_L_Left2Right_nbr Behavior_week_DirCond.r_R_Right2Left_nbr Behavior_week_DirCond.r_R_Left2Right_nbr] ;
  
        for i=1:5
            if i==1 
                text(dir(i).XData,dir(i).YEndPoints/2,num2str(trial_nbr(:,i)), ...
                'HorizontAlalign','center','fontsize',6,'color','k')
            else
                text(dir(i).XData(find(dir(i).YData)),dir(i-1).YEndPoints(find(dir(i).YData))+...
                    (dir(i).YEndPoints(find(dir(i).YData))-dir(i-1).YEndPoints(find(dir(i).YData)))/2,...
                    num2str(trial_nbr((find(dir(i).YData)),i)), 'HorizontAlalign','center','fontsize',6,'color','k')
            end
        end   
 

    xlabel('weeks')
    xticks([1:w_nbr])
    ylabel('success(%)')
    %ylim([0 50])
    ylim([0 100])
    xticklabels(week_idx);
    xtickangle(45)

%     xline(stage2,':',{'stage 2'});
%     xline(stage3,':',{'stage 3'});
    
    
    legend('Aligned','L Right2Left','L Left2Right','R Right2Left','R Left2Right','Location','southwestoutside','FontSize',10)
    title([subject ' ' 'RIGHT condition success rate and movement direction part in day success']);
    

    
