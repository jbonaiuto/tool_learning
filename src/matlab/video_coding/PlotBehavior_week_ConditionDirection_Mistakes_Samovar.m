%plot behavior by week by condition-direction-types and mistakes of movement for Samovar

%insert the table layout with rake and target starting zone with highlight
%for each cond-direction movement

DatesLabels={'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21','08.07.21','09.07.21','13.07.21','14.07.21',...
    '15.07.21','16.07.21','27.07.21','28.07.21','29.07.21','30.07.21','03.08.21','04.08.21','10.08.21','11.08.21','12.08.21','13.08.21','17.08.21','18.08.21',...
    '19.08.21','20.08.21','24.08.21','25.08.21','27.08.21','31.08.21','01.09.21','02.09.21','03.09.21','07.09.21','09.09.21','10.09.21','14.09.21','15.09.21',...
    '17.09.21','21.09.21','22.09.21','23.09.21','24.09.21','29.09.21','30.09.21','01.10.21','05.10.21','06.10.21','07.10.21','08.10.21','11.10.21','12.10.21',...
    '13.10.21','14.10.21','26.10.21','27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'};

stage2=13.5;
stage3=36.5;

%plot overall condition 

        
        %plot the rate of different hand movements after the trial
            figure
            hold   

            HandAfterTrial=[week_Behavior_Mistakes.HandAfter_BackHandle_rate week_Behavior_Mistakes.HandAfter_RestRake_rate week_Behavior_Mistakes.HandAfter_PlaceTarget_rate ...
                week_Behavior_Mistakes.HandAfter_TouchTarget_rate week_Behavior_Mistakes.HandAfter_StillMove_rate];

            bar(HandAfterTrial,'stacked')

            xlabel('weeks')
            xticks([1:w_nbr])
            ylabel('#')
            ylabel('%')
            %ylim([0 100])
            xticklabels(week_idx);
            xtickangle(45)
            legend('back on the handle','rest on the rake','place target','touch target','hand Still Moving','FontSize',12)
            title([subject ' ' 'different hand movements after trial']);

               % stereotypical trial
                figure
                hold

                stereotyped=week_Behavior_Mistakes.stereotyped_rate;


                plot([1:w_nbr], stereotyped,'LineStyle','-','Color','k','LineWidth',2);


                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                title([subject ' ' 'stereotyped trials']);

         %plot the number of Multiple Attempt trials
                figure
                hold

                MultipleAttempts=week_Behavior_Mistakes.MultipleAttempts_rate;
                MultipleAttempts_success=week_Behavior_Mistakes.Hit_MultipleAttempts_rate;

                plot([1:w_nbr], MultipleAttempts,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr],MultipleAttempts_success,'LineStyle','--','Color','k','LineWidth',1.5);


                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('multiple attempts','multiple attempts with success');
                title([subject ' ' ' multiple attempts']);

         %plot the number of overshoot trials 
                figure
                hold

                Overshoot=week_Behavior_Mistakes.Overshoot_rate;
                Overshoot_success=week_Behavior_Mistakes.Hit_Overshoot_rate;

                plot([1:w_nbr], Overshoot,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], Overshoot_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('Overshoot','Overshoot with success');
                title([subject ' ' ' overshoot']);
                
        %plot the number of motor twitchs
                figure
                hold

                MotorTwitches=week_Behavior_Mistakes.MotorTwitches_rate;
                MotorTwitches_success=week_Behavior_Mistakes.Hit_MotorTwitches_rate;
                
                plot([1:w_nbr], MotorTwitches,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], MotorTwitches_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('motor twitches','motor twitches with success');
                title([subject ' ' 'motor twitches']);
                
         %plot the number of beyond trap 
                figure
                hold

                BeyondTrap=week_Behavior_Mistakes.BeyondTrap_rate;
                BeyondTrap_success=week_Behavior_Mistakes.Hit_BeyondTrap_rate;
                
                plot([1:w_nbr], BeyondTrap,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], BeyondTrap_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                %ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('beyond trap','beyond trap with success');
                title([subject ' ' 'Beyond trap']);
                
         %plot the number of sliding
                figure
                hold

                Sliding=week_Behavior_Mistakes.Sliding_rate;
                Sliding_success=week_Behavior_Mistakes.Hit_Sliding_rate;
                
                plot([1:w_nbr], Sliding,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], Sliding_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('Sliding','Sliding with success');
                title([subject ' ' 'Sliding']);
                
         %plot the number of pulled strongly
                figure
                hold

                PulledStrongly=week_Behavior_Mistakes.PulledStrongly_rate;
                PulledStrongly_success=week_Behavior_Mistakes.Hit_PulledStrongly_rate;
                
                plot([1:w_nbr], PulledStrongly,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], PulledStrongly_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('pulled strongly','pulled strongly with success');
                title([subject ' ' 'PulledStrongly']);  
                
          %plot the number of kick
                figure
                hold

                kick=week_Behavior_Mistakes.kick_rate;
                kick_success=week_Behavior_Mistakes.Hit_kick_rate;
                
                plot([1:w_nbr], kick,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], kick_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('kick',' kick with success');
                title([subject ' ' 'kick']);
                
          %plot the number of whiplash
                figure
                hold

                whiplash=week_Behavior_Mistakes.whiplash_rate;
                whiplash_success=week_Behavior_Mistakes.Hit_whiplash_rate;
                
                plot([1:w_nbr], whiplash,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], whiplash_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('whiplash',' whiplash with success');
                title([subject ' ' 'whiplash']);
                
         %plot the number of shaft correction
                figure
                hold

                ShaftCorrection=week_Behavior_Mistakes.ShaftCorrection_rate;
                ShaftCorrection_success=week_Behavior_Mistakes.Hit_ShaftCorrection_rate;
                
                plot([1:w_nbr], ShaftCorrection,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], ShaftCorrection_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('ShaftCorrection',' ShaftCorrection with success');
                title([subject ' ' 'ShaftCorrection']);
                
          %plot the number of volte
                figure
                hold

                volte=week_Behavior_Mistakes.volte_rate;
                volte_success=week_Behavior_Mistakes.Hit_volte_rate;
                
                plot([1:w_nbr], volte,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], volte_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('volte','volte with success');
                title([subject ' ' 'volte']);
                
          %plot the number of v_mvt
                figure
                hold

                v_mvt=week_Behavior_Mistakes.v_mvt_rate;
                v_mvt_success=week_Behavior_Mistakes.Hit_v_mvt_rate;
                
                plot([1:w_nbr], v_mvt,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], v_mvt_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('v_mvt','v_mvt with success');
                title([subject ' ' 'v_mvt']);
                
          %plot the number of screen
                figure
                hold

                screen=week_Behavior_Mistakes.screen_rate;
                screen_success=week_Behavior_Mistakes.Hit_screen_rate;
                
                plot([1:w_nbr], screen,'LineStyle','-','Color','k','LineWidth',2);
                plot([1:w_nbr], screen_success,'LineStyle','--','Color','k','LineWidth',1.5);

                xlabel('weeks')
                xticks([1:w_nbr])
                ylabel('%')
                %ylim([0 50])
                xticklabels(week_idx);
                xtickangle(45)
                legend('screen','screen with success');
                title([subject ' ' 'screen']);

                
%plot the number of stereotyped trials by condition
        figure
        hold

        stereotypedLeft=Behavior_Mistakes.stereotyped_l_nbr;
        stereotypedCenter=Behavior_Mistakes.stereotyped_c_nbr;
        stereotypedRight=Behavior_Mistakes.stereotyped_r_nbr;
        
        

        plot([1:days_nbr], stereotypedLeft,'LineStyle','-','Color',[0 0.4470 0.7410],'LineWidth',2);
        plot([1:days_nbr], stereotypedCenter,'LineStyle','-','Color',[0.4940 0.1840 0.5560],'LineWidth',2);
        plot([1:days_nbr],stereotypedRight,'LineStyle','-','Color',[0.3010 0.7450 0.9330],'LineWidth',2);
        
        xlabel('days')
        xticks([1:days_nbr])
        ylabel('#')
        ylim([0 50])
        xticklabels(DatesLabels);
        xtickangle(45)

        xline(stage2,':',{'stage 2'});
        xline(stage3,':',{'stage 3'});

        legend('stereotypedLeft','stereotypedCenter','stereotypedRight','FontSize',10)
    
        title([subject ' ' 'stereotyped trials by condition']);
    
 %plot the number of Multiple Attempt trials by condition
        figure
        hold

        MultipleAttemptsLeft=Behavior_Mistakes.MultipleAttempts_l_nbr;
        MultipleAttemptsCenter=Behavior_Mistakes.MultipleAttempts_c_nbr;
        MultipleAttemptsRight=Behavior_Mistakes.MultipleAttempts_r_nbr;

%         plot([1:days_nbr], MultipleAttemptsLeft,'LineStyle','-','Color',[0.6350 0.0780 0.1840],'LineWidth',2);
%         plot([1:days_nbr], MultipleAttemptsCenter,'LineStyle','-','Color',[0.8500 0.3250 0.0980],'LineWidth',2);
%         plot([1:days_nbr], MultipleAttemptsRight,'LineStyle','-','Color',[0.9290 0.6940 0.1250],'LineWidth',2);
        
        MultipleAttempts=[MultipleAttemptsLeft MultipleAttemptsCenter MultipleAttemptsRight];
        
        bar(MultipleAttempts)

        xlabel('days')
        xticks([1:days_nbr])
        ylabel('#')
        ylim([0 50])
        xticklabels(DatesLabels);
        xtickangle(45)

        xline(stage2,':',{'stage 2'});
        xline(stage3,':',{'stage 3'});

        legend('MultipleAttemptsLeft','MultipleAttemptsCenter','MultipleAttemptsRight','FontSize',10)
    
        title([subject ' ' ' multiple attempt by condition']);
        
        
 %plot the number of overshoot trials by condition
        figure
        hold
        
        OvershootLeft=Behavior_Mistakes.Overshoot_l_nbr;
        OvershootCenter=Behavior_Mistakes.Overshoot_c_nbr;
        OvershootRight=Behavior_Mistakes.Overshoot_r_nbr;

%         plot([1:days_nbr], OvershootLeft,'LineStyle','-','Color',[0 1 0],'LineWidth',2);
%         plot([1:days_nbr], OvershootCenter,'LineStyle','-','Color',[0.4660 0.6740 0.1880],'LineWidth',2);
%         plot([1:days_nbr], OvershootRight,'LineStyle','-','Color',[0.5 0.7 0.1250],'LineWidth',2);

        Overshoot=[OvershootLeft OvershootCenter OvershootRight];
        
        bar(Overshoot)

        xlabel('days')
        xticks([1:days_nbr])
        ylabel('#')
        ylim([0 50])
       xticklabels(DatesLabels);
        xtickangle(45)

        xline(stage2,':',{'stage 2'});
        xline(stage3,':',{'stage 3'});

        legend('OvershootLeft','OvershootCenter','OvershootRight','FontSize',10)
    
         title([subject ' ' ' overshoot by condition']);
    
%plot the number of different hand movements after the trial - LEFT condition
    figure
    hold
    
    Behavior_Mistakes.HandAfter_BackHandle_l_nbr
    Behavior_Mistakes.HandAfter_RestRake_l_nbr
    Behavior_Mistakes.HandAfter_PlaceTarget_l_nbr
    Behavior_Mistakes.HandAfter_TouchTarget_l_nbr
    Behavior_Mistakes.HandAfter_StillMove_l_nbr
    
        HandAfterTrial_Left=[Behavior_Mistakes.HandAfter_BackHandle_l_nbr Behavior_Mistakes.HandAfter_RestRake_l_nbr Behavior_Mistakes.HandAfter_PlaceTarget_l_nbr ...
            Behavior_Mistakes.HandAfter_TouchTarget_l_nbr  Behavior_Mistakes.HandAfter_StillMove_l_nbr];
        
        bar(HandAfterTrial_Left,'stacked')
              
%           HandAfterTrial_Left(1).FaceColor=[1 0 0];
%           HandAfterTrial_Left(2).FaceColor=[0 1 0];
%           HandAfterTrial_Left(3).FaceColor=[0 0 1];
%           HandAfterTrial_Left(4).FaceColor=[1 0 1];
%           HandAfterTrial_Left(5).FaceColor=[0 0 0];
        
     xlabel('days')
    xticks([1:days_nbr])
    ylabel('#')
    ylim([0 100])
   xticklabels(DatesLabels);
    xtickangle(45)

    xline(stage2,':',{'stage 2'});
    xline(stage3,':',{'stage 3'});

    legend('BackHandle','RestRake','PlaceTarget','TouchTarget','StillMove','FontSize',12)
    
    title([subject ' ' ' LEFT different hand movement after trial']);
    
%plot the number of different hand movements after the trial - CENTER condition
    figure
    hold
    
    Behavior_Mistakes.HandAfter_BackHandle_c_nbr
    Behavior_Mistakes.HandAfter_RestRake_c_nbr
    Behavior_Mistakes.HandAfter_PlaceTarget_c_nbr
    Behavior_Mistakes.HandAfter_TouchTarget_c_nbr
    Behavior_Mistakes.HandAfter_StillMove_c_nbr
    
        HandAfterTrial_Center=[Behavior_Mistakes.HandAfter_BackHandle_c_nbr Behavior_Mistakes.HandAfter_RestRake_c_nbr Behavior_Mistakes.HandAfter_PlaceTarget_c_nbr ...
            Behavior_Mistakes.HandAfter_TouchTarget_c_nbr Behavior_Mistakes.HandAfter_StillMove_c_nbr];
    
        bar(HandAfterTrial_Center,'stacked')


    xlabel('days')
    xticks([1:days_nbr])
    ylabel('#')
    ylim([0 100])
    xticklabels(DatesLabels);
    xtickangle(45)

    xline(stage2,':',{'stage 2'});
    xline(stage3,':',{'stage 3'});

    legend('BackHandle','RestRake','PlaceTarget','TouchTarget','StillMove','FontSize',12)
    
    title([subject ' ' ' CENTER different hand movement after trial']);


 %plot the number of different hand movements after the trial - RIGHT condition
    figure
    hold   
 
    Behavior_Mistakes.HandAfter_BackHandle_r_nbr
    Behavior_Mistakes.HandAfter_RestRake_r_nbr
    Behavior_Mistakes.HandAfter_PlaceTarget_r_nbr
    Behavior_Mistakes.HandAfter_TouchTarget_r_nbr
    Behavior_Mistakes.HandAfter_StillMove_r_nbr
    
        HandAfterTrial_Right=[Behavior_Mistakes.HandAfter_BackHandle_r_nbr Behavior_Mistakes.HandAfter_RestRake_r_nbr Behavior_Mistakes.HandAfter_PlaceTarget_r_nbr ...
            Behavior_Mistakes.HandAfter_TouchTarget_r_nbr Behavior_Mistakes.HandAfter_StillMove_r_nbr];
    
        bar(HandAfterTrial_Right,'stacked')
    
    xlabel('days')
    xticks([1:days_nbr])
    ylabel('#')
    ylim([0 100])
    xticklabels(DatesLabels);
    xtickangle(45)

    xline(stage2,':',{'stage 2'});
    xline(stage3,':',{'stage 3'});

    legend('BackHandle','RestRake','PlaceTarget','TouchTarget','StillMove','FontSize',12)
    
    title([subject ' ' ' RIGHT different hand movement after trial']);
    
  
  
  %plot the number of successful trial, the cube trial and the perfect trial
    figure
    hold   
 
    Success=Behavior_Mistakes.Success_nbr;
    PerfectTrials=Behavior_Mistakes.PerfectTrials_nbr;
    
        SuccPerfect=[Success PerfectTrials];
    
        bar(SuccPerfect)
    
    xlabel('days')
    xticks([1:days_nbr])
    ylabel('#')
    ylim([0 100])
    xticklabels(DatesLabels);
    xtickangle(45)

    xline(stage2,':',{'stage 2'});
    xline(stage3,':',{'stage 3'});

    legend('Success trial','Perfect trials','FontSize',12)
    
    title([subject ' ' ' nbr of trial overall, perfect']);
    
