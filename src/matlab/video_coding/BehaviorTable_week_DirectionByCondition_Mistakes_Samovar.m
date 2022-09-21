%BehaviorTable_DirectionByCondition_MistakesSamovar

subject= 'Samovar'; % betta use the left hand, Samovar the right hand so it changes the direction of the movement
coder= 'SK'; % ND = Noémie Dessaint, SK = Sébastien Kirchherr, GC = Gino Coudé

dates={'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21','29.06.21','30.06.21','02.07.21','06.07.21','08.07.21','09.07.21','13.07.21','14.07.21',...
    '15.07.21','16.07.21','27.07.21','28.07.21','29.07.21','30.07.21','03.08.21','04.08.21','05.08.21','06.08.21','10.08.21','11.08.21','12.08.21','13.08.21','17.08.21',...
    '18.08.21','19.08.21','20.08.21','24.08.21','25.08.21','27.08.21','31.08.21','01.09.21','02.09.21','03.09.21','07.09.21','08.09.21','09.09.21','10.09.21','14.09.21',...
    '15.09.21','17.09.21','21.09.21','22.09.21','23.09.21','24.09.21','29.09.21','30.09.21','01.10.21','05.10.21','06.10.21','07.10.21','08.10.21','11.10.21','12.10.21',...
    '13.10.21','14.10.21','26.10.21','27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'};


days_nbr=length(dates);

%hit=success, but shorter

WeekOfRec={};
weeks=[];
for d=1:length(dates)
    day=dates{d};
    WeekOfRec{1,d}=day;
    WeekOfRec{2,d}=d;

    day=insertAfter(day,6,'20');
    yyyy=str2num(day(end-3:end));
    mm=str2num(day(end-6:end-5));
    dd=str2num(day(end-9:end-8));

    day=datetime(yyyy,mm,dd);

    w=week(day);
    % -21 to have the week of recording not the week of the year
    WeekOfRec{3,d}=w-21;


    if d==1
        WeekOfRec{4,d}=1;
    elseif d>1 && WeekOfRec{3,d-1}~=WeekOfRec{3,d}

        week_diff=WeekOfRec{3,d}-WeekOfRec{3,d-1};
        WeekOfRec{4,d}=WeekOfRec{4,d-1}+week_diff;
    elseif d>1 && WeekOfRec{3,d-1}==WeekOfRec{3,d}
        WeekOfRec{4,d}=WeekOfRec{4,d-1};
    end

    weeks(end+1)=w;

end

weeks=weeks-21; %to transform the weeks of the year into week of tool training recording
week_idx=unique(weeks);
w_nbr=length(week_idx);

output_path=fullfile('E:\project\video_coding\', subject,'table');

week_Behavior_Mistakes=table('Size',[w_nbr 92],'VariableTypes',{'double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double'});

week_Behavior_Mistakes.Properties.VariableNames={'date','validTrials_nbr','Success_nbr','Success_rate',...
    'stereotyped_nbr','MultipleAttempts_nbr','Hit_MultipleAttempts_nbr','Hit_MultipleAttempts_rate','Overshoot_nbr','Hit_Overshoot_nbr','Hit_Overshoot_rate',...
    'BeyondTrap_nbr','BeyondTrap_rate','Hit_BeyondTrap_nbr','Hit_BeyondTrap_rate','Sliding_nbr','Sliding_rate','Hit_Sliding_nbr','Hit_Sliding_rate',...
    'PulledStrongly_nbr','PulledStrongly_rate','Hit_PulledStrongly_nbr','Hit_PulledStrongly_rate','kick_nbr','kick_rate','Hit_kick_nbr','Hit_kick_rate',...
    'whiplash_nbr','whiplash_rate','Hit_whiplash_nbr','Hit_whiplash_rate','ShaftCorrection_nbr','ShaftCorrection_rate','Hit_ShaftCorrection_nbr','Hit_ShaftCorrection_rate',...
    'v_mvt_nbr','v_mvt_rate','Hit_v_mvt_nbr','Hit_v_mvt_rate','volte_nbr','volte_rate','Hit_volte_nbr','Hit_volte_rate',...
    'HandAfter_BackHandle_nbr','HandAfter_RestRake_nbr','HandAfter_PlaceTarget_nbr','HandAfter_TouchTarget_nbr','HandAfter_StillMove_nbr',...
    'stereotyped_rate','MultipleAttempts_rate','Overshoot_rate','MotorTwitches_nbr','MotorTwitches_rate','Hit_MotorTwitches_nbr','Hit_MotorTwitches_rate',...
    'HandAfter_BackHandle_rate','HandAfter_RestRake_rate','HandAfter_PlaceTarget_rate','HandAfter_TouchTarget_rate','HandAfter_StillMove_rate',...
    'screen_nbr','screen_rate','Hit_screen_nbr','Hit_screen_rate',...
    'conditionLeft_nbr','conditionCenter_nbr','conditionRight_nbr',...
    'stereotyped_l_nbr','stereotyped_c_nbr','stereotyped_r_nbr',...
    'MultipleAttempts_l_nbr','MultipleAttempts_c_nbr','MultipleAttempts_r_nbr',...
    'Overshoot_l_nbr','Overshoot_c_nbr','Overshoot_r_nbr',...
    'HandAfter_BackHandle_l_nbr','HandAfter_BackHandle_c_nbr','HandAfter_BackHandle_r_nbr',...
    'HandAfter_RestRake_l_nbr', 'HandAfter_RestRake_c_nbr', 'HandAfter_RestRake_r_nbr',...
    'HandAfter_PlaceTarget_l_nbr', 'HandAfter_PlaceTarget_c_nbr', 'HandAfter_PlaceTarget_r_nbr',...
    'HandAfter_TouchTarget_l_nbr','HandAfter_TouchTarget_c_nbr','HandAfter_TouchTarget_r_nbr',...
    'HandAfter_StillMove_l_nbr','HandAfter_StillMove_c_nbr','HandAfter_StillMove_r_nbr',...
    'PerfectTrials_nbr'};

      %'Sliding_l_nbr','Sliding_c_nbr','Sliding_r_nbr',...

for w=1:w_nbr
    WOI=week_idx(w);
    
    w_validTrials_nbr=0;
    w_Success_nbr=0;
    w_stereotyped_nbr=0;
    w_MultipleAttempts_nbr=0;
    w_Hit_MultipleAttempts_nbr=0;
    w_Overshoot_nbr=0;
    w_Hit_Overshoot_nbr=0;
    w_HandAfter_BackHandle_nbr=0;
    w_HandAfter_RestRake_nbr=0;
    w_HandAfter_PlaceTarget_nbr=0;
    w_HandAfter_TouchTarget_nbr=0;
    w_HandAfter_StillMove_nbr=0;
    w_MotorTwitches_nbr=0;
    w_Hit_MotorTwitches_nbr=0;
    w_BeyondTrap_nbr=0;
    w_Hit_BeyondTrap_nbr=0;
    w_Sliding_nbr=0;
    w_Hit_Sliding_nbr=0;
    w_PulledStrongly_nbr=0;
    w_Hit_PulledStrongly_nbr=0;
    w_kick_nbr=0;
    w_Hit_kick_nbr=0;
    w_whiplash_nbr=0;
    w_Hit_whiplash_nbr=0;
    w_ShaftCorrection_nbr=0;
    w_Hit_ShaftCorrection_nbr=0;
    w_v_mvt_nbr=0;
    w_Hit_v_mvt_nbr=0;
    w_volte_nbr=0;
    w_Hit_volte_nbr=0;
    w_screen_nbr=0;
    w_Hit_screen_nbr=0;
    
    for d=1:length(dates)
        if weeks(d)==WOI

            date_xls=replace(dates{d},'.','-');
            date_xls=insertAfter(date_xls,6,'20');
            date_backward=[date_xls(end-3:end) date_xls(end-6:end-5) date_xls(end-9:end-8)];
            videocod_file=fullfile(output_path, ['motor_rake_' date_backward '_' date_xls '_' coder '.xlsx']);

            videotable=readtable(videocod_file);

            validTrials=find(videotable.ValidVideo==1);
            validTrials_nbr=length(validTrials);
            
            w_validTrials_nbr=w_validTrials_nbr+validTrials_nbr;

            Success=find(videotable.Success==1);
            Success_nbr=length(Success);
           
            w_Success_nbr=w_Success_nbr+Success_nbr;
            

          %overall condition
                stereotyped_idx=find(videotable.pulledStrongly==2);
                stereotyped_nbr=length(stereotyped_idx);
                w_stereotyped_nbr=w_stereotyped_nbr+stereotyped_nbr;

                MultipleAttempts_idx=find(videotable.MultipleAttempts==1);
                MultipleAttempts_nbr=length(MultipleAttempts_idx);
                Hit_MultipleAttempts_nbr=length(find(videotable.Success(MultipleAttempts_idx)==1));
                w_MultipleAttempts_nbr=w_MultipleAttempts_nbr+MultipleAttempts_nbr;
                w_Hit_MultipleAttempts_nbr=w_Hit_MultipleAttempts_nbr + Hit_MultipleAttempts_nbr;

                Overshoot_idx=find(videotable.Overshoot==1);
                Overshoot_nbr=length(Overshoot_idx);
                Hit_Overshoot_nbr=length(find(videotable.Success(Overshoot_idx)==1));
                w_Overshoot_nbr=w_Overshoot_nbr+Overshoot_nbr;
                w_Hit_Overshoot_nbr=w_Hit_Overshoot_nbr + Hit_Overshoot_nbr;

                HandAfter_BackHandle_idx=find(videotable.hand_after_trial==1);
                HandAfter_BackHandle_nbr=length(HandAfter_BackHandle_idx);
                w_HandAfter_BackHandle_nbr=w_HandAfter_BackHandle_nbr+HandAfter_BackHandle_nbr;
                
                HandAfter_RestRake_idx=find(videotable.hand_after_trial==2);
                HandAfter_RestRake_nbr=length(HandAfter_RestRake_idx);
                w_HandAfter_RestRake_nbr=w_HandAfter_RestRake_nbr+HandAfter_RestRake_nbr;

                HandAfter_PlaceTarget_idx=find(videotable.hand_after_trial==4);
                HandAfter_PlaceTarget_nbr=length(HandAfter_PlaceTarget_idx);
                w_HandAfter_PlaceTarget_nbr=w_HandAfter_PlaceTarget_nbr+HandAfter_PlaceTarget_nbr;

                HandAfter_TouchTarget_idx=find(videotable.hand_after_trial==3);
                HandAfter_TouchTarget_nbr=length(HandAfter_TouchTarget_idx);
                w_HandAfter_TouchTarget_nbr=w_HandAfter_TouchTarget_nbr+HandAfter_TouchTarget_nbr;

                HandAfter_StillMove_idx=find(videotable.hand_after_trial==0);
                HandAfter_StillMove_nbr=length(HandAfter_StillMove_idx);
                w_HandAfter_StillMove_nbr=w_HandAfter_StillMove_nbr+HandAfter_StillMove_nbr;
                
                MotorTwitches_idx=find(videotable.parasite_mvt==5 | videotable.parasite_mvt==3);
                MotorTwitches_nbr=length(MotorTwitches_idx);
                Hit_MotorTwitches_nbr=length(find(videotable.Success(MotorTwitches_idx)==1));
                w_MotorTwitches_nbr=w_MotorTwitches_nbr + MotorTwitches_nbr;
                w_Hit_MotorTwitches_nbr=w_Hit_MotorTwitches_nbr+Hit_MotorTwitches_nbr;
                
                BeyondTrap_idx=find(videotable.beyond_trap==1);
                BeyondTrap_nbr=length(BeyondTrap_idx);
                Hit_BeyondTrap_nbr=length(find(videotable.Success(BeyondTrap_idx)==1));
                w_BeyondTrap_nbr=w_BeyondTrap_nbr + BeyondTrap_nbr;
                w_Hit_BeyondTrap_nbr=w_Hit_BeyondTrap_nbr+Hit_BeyondTrap_nbr;
                
                Sliding_idx=find(videotable.sliding==1);
                Sliding_nbr=length(Sliding_idx);
                Hit_Sliding_nbr=length(find(videotable.Success(Sliding_idx)==1));
                w_Sliding_nbr=w_Sliding_nbr + Sliding_nbr;
                w_Hit_Sliding_nbr=w_Hit_Sliding_nbr+Hit_Sliding_nbr;
                
                PulledStrongly_idx=find(videotable.pulledStrongly==1);
                PulledStrongly_nbr=length(PulledStrongly_idx);
                Hit_PulledStrongly_nbr=length(find(videotable.Success(PulledStrongly_idx)==1));
                w_PulledStrongly_nbr=w_PulledStrongly_nbr + PulledStrongly_nbr;
                w_Hit_PulledStrongly_nbr=w_Hit_PulledStrongly_nbr+Hit_PulledStrongly_nbr;
                
                kick_idx=find(strcmp(videotable.comments,'kick'));
                kick_nbr=length(kick_idx);
                Hit_kick_nbr=length(find(videotable.Success(kick_idx)==1));
                w_kick_nbr=w_kick_nbr + kick_nbr;
                w_Hit_kick_nbr=w_Hit_kick_nbr+Hit_kick_nbr;
                
                whiplash_idx=find(strcmp(videotable.comments,'whiplash'));
                whiplash_nbr=length(whiplash_idx);
                Hit_whiplash_nbr=length(find(videotable.Success(whiplash_idx)==1));
                w_whiplash_nbr=w_whiplash_nbr + whiplash_nbr;
                w_Hit_whiplash_nbr=w_Hit_whiplash_nbr+Hit_whiplash_nbr;
                
                ShaftCorrection_idx=find(strcmp(videotable.comments,'shaft correction'));
                ShaftCorrection_nbr=length(ShaftCorrection_idx);
                Hit_ShaftCorrection_nbr=length(find(videotable.Success(ShaftCorrection_idx)==1));
                w_ShaftCorrection_nbr=w_ShaftCorrection_nbr + ShaftCorrection_nbr;
                w_Hit_ShaftCorrection_nbr=w_Hit_ShaftCorrection_nbr + Hit_ShaftCorrection_nbr;
                
                volte_idx=find(strcmp(videotable.comments,'volte'));
                volte_nbr=length(volte_idx);
                Hit_volte_nbr=length(find(videotable.Success(volte_idx)==1));
                w_volte_nbr=w_volte_nbr + volte_nbr;
                w_Hit_volte_nbr=w_Hit_volte_nbr+Hit_volte_nbr;
                
                v_mvt_idx=find(strcmp(videotable.comments,'v mvt'));
                v_mvt_nbr=length(v_mvt_idx);
                Hit_v_mvt_nbr=length(find(videotable.Success(v_mvt_idx)==1));
                w_v_mvt_nbr=w_v_mvt_nbr + v_mvt_nbr;
                w_Hit_v_mvt_nbr=w_Hit_v_mvt_nbr+Hit_v_mvt_nbr;
                
                screen_idx=find(videotable.exp_hand_Screen==1);
                screen_nbr=length(screen_idx);
                Hit_screen_nbr=length(find(videotable.Success(screen_idx)==1));
                w_screen_nbr=w_screen_nbr + screen_nbr;
                w_Hit_screen_nbr=w_Hit_screen_nbr+Hit_screen_nbr;


          %left condition - l
                conditionLeft_idx=find(strcmp(videotable.TargetStarting,'b'));
                conditionLeft_nbr=length(conditionLeft_idx);

                stereotyped_l_idx=find(videotable.pulledStrongly(conditionLeft_idx)==2);
                stereotyped_l_nbr=length(stereotyped_l_idx);

                MultipleAttempts_l_idx=find(videotable.MultipleAttempts(conditionLeft_idx)==1);
                MultipleAttempts_l_nbr=length(MultipleAttempts_l_idx);
% 
%                 Sliding_l_idx=find(videotable.sliding(conditionLeft_idx)==1);
%                 Sliding_l_nbr=length(Sliding_l_idx);

                Overshoot_l_idx=find(videotable.Overshoot(conditionLeft_idx)==1);
                Overshoot_l_nbr=length(Overshoot_l_idx);

                HandAfter_BackHandle_l_idx=find(videotable.hand_after_trial(conditionLeft_idx)==1);
                HandAfter_BackHandle_l_nbr=length(HandAfter_BackHandle_l_idx);

                HandAfter_RestRake_l_idx=find(videotable.hand_after_trial(conditionLeft_idx)==2);
                HandAfter_RestRake_l_nbr=length(HandAfter_RestRake_l_idx);

                HandAfter_PlaceTarget_l_idx=find(videotable.hand_after_trial(conditionLeft_idx)==4);
                HandAfter_PlaceTarget_l_nbr=length(HandAfter_PlaceTarget_l_idx);

                HandAfter_TouchTarget_l_idx=find(videotable.hand_after_trial(conditionLeft_idx)==3);
                HandAfter_TouchTarget_l_nbr=length(HandAfter_TouchTarget_l_idx);

                HandAfter_StillMove_l_idx=find(videotable.hand_after_trial(conditionLeft_idx)==0);
                HandAfter_StillMove_l_nbr=length(HandAfter_StillMove_l_idx);

          %center condition - c
                conditionCenter_idx=find(strcmp(videotable.TargetStarting,'c'));
                conditionCenter_nbr=length(conditionCenter_idx);

                stereotyped_c_idx=find(videotable.pulledStrongly(conditionCenter_idx)==2);
                stereotyped_c_nbr=length(stereotyped_c_idx);

                MultipleAttempts_c_idx=find(videotable.MultipleAttempts(conditionCenter_idx)==1);
                MultipleAttempts_c_nbr=length(MultipleAttempts_c_idx);

        %         Sliding_c_idx=find(videotable.sliding(conditionCenter_idx)==1);
        %         Sliding_c_nbr=length(Sliding_c_idx);

                Overshoot_c_idx=find(videotable.Overshoot(conditionCenter_idx)==1);
                Overshoot_c_nbr=length(Overshoot_c_idx);

                HandAfter_BackHandle_c_idx=find(videotable.hand_after_trial(conditionCenter_idx)==1);
                HandAfter_BackHandle_c_nbr=length(HandAfter_BackHandle_c_idx);

                HandAfter_RestRake_c_idx=find(videotable.hand_after_trial(conditionCenter_idx)==2);
                HandAfter_RestRake_c_nbr=length(HandAfter_RestRake_c_idx);

                HandAfter_PlaceTarget_c_idx=find(videotable.hand_after_trial(conditionCenter_idx)==4);
                HandAfter_PlaceTarget_c_nbr=length(HandAfter_PlaceTarget_c_idx);

                HandAfter_TouchTarget_c_idx=find(videotable.hand_after_trial(conditionCenter_idx)==3);
                HandAfter_TouchTarget_c_nbr=length(HandAfter_TouchTarget_c_idx);

                HandAfter_StillMove_c_idx=find(videotable.hand_after_trial(conditionCenter_idx)==0);
                HandAfter_StillMove_c_nbr=length(HandAfter_StillMove_c_idx);

          %right condition - r
                conditionRight_idx=find(strcmp(videotable.TargetStarting,'d'));
                conditionRight_nbr=length(conditionRight_idx);

                stereotyped_r_idx=find(videotable.pulledStrongly(conditionRight_idx)==2);
                stereotyped_r_nbr=length(stereotyped_r_idx);

                MultipleAttempts_r_idx=find(videotable.MultipleAttempts(conditionRight_idx)==1);
                MultipleAttempts_r_nbr=length(MultipleAttempts_r_idx);

        %         Sliding_r_idx=find(videotable.sliding(conditionRight_idx)==1);
        %         Sliding_r_nbr=length(Sliding_r_idx);

                Overshoot_r_idx=find(videotable.Overshoot(conditionRight_idx)==1);
                Overshoot_r_nbr=length(Overshoot_r_idx);    

                HandAfter_BackHandle_r_idx=find(videotable.hand_after_trial(conditionRight_idx)==1);
                HandAfter_BackHandle_r_nbr=length(HandAfter_BackHandle_r_idx);

                HandAfter_RestRake_r_idx=find(videotable.hand_after_trial(conditionRight_idx)==2);
                HandAfter_RestRake_r_nbr=length(HandAfter_RestRake_r_idx);

                HandAfter_PlaceTarget_r_idx=find(videotable.hand_after_trial(conditionRight_idx)==4);
                HandAfter_PlaceTarget_r_nbr=length(HandAfter_PlaceTarget_r_idx);

                HandAfter_TouchTarget_r_idx=find(videotable.hand_after_trial(conditionRight_idx)==3);
                HandAfter_TouchTarget_r_nbr=length(HandAfter_TouchTarget_r_idx);

                HandAfter_StillMove_r_idx=find(videotable.hand_after_trial(conditionRight_idx)==0);
                HandAfter_StillMove_r_nbr=length(HandAfter_StillMove_r_idx);

          % quantify nbr of successful trials without any mishaps

                PerfectTrials=videotable.Success==1 & videotable.Overshoot==0 & videotable.MultipleAttempts==0 & ...
                     videotable.pulledStrongly==0 & videotable.beyond_trap==0; % & videotable.parasiteMvt==0  videotable.parasite_mvt==2 

                PerfectTrials_idx=find(PerfectTrials);
                PerfectTrials_nbr=length(PerfectTrials_idx);
                
        else
            continue
        end
    end            
    
    w_Success_rate=(w_Success_nbr/w_validTrials_nbr)*100;
    w_stereotyped_rate=(w_stereotyped_nbr/w_validTrials_nbr)*100;
    w_MultipleAttempts_rate=(w_MultipleAttempts_nbr/w_validTrials_nbr)*100;
    w_Hit_MultipleAttempts_rate=(w_Hit_MultipleAttempts_nbr/w_validTrials_nbr)*100;
    w_Overshoot_rate=(w_Overshoot_nbr/w_validTrials_nbr)*100;
    w_Hit_Overshoot_rate=(w_Hit_Overshoot_nbr/w_validTrials_nbr)*100;
    w_HandAfter_BackHandle_rate=(w_HandAfter_BackHandle_nbr/w_validTrials_nbr)*100;
    w_HandAfter_RestRake_rate=(w_HandAfter_RestRake_nbr/w_validTrials_nbr)*100;
    w_HandAfter_PlaceTarget_rate=(w_HandAfter_PlaceTarget_nbr/w_validTrials_nbr)*100;
    w_HandAfter_TouchTarget_rate=(w_HandAfter_TouchTarget_nbr/w_validTrials_nbr)*100;
    w_HandAfter_StillMove_rate=(w_HandAfter_StillMove_nbr/w_validTrials_nbr)*100;
    w_MotorTwitches_rate=(w_MotorTwitches_nbr/w_validTrials_nbr)*100;
    w_Hit_MotorTwitches_rate=(w_Hit_MotorTwitches_nbr/w_validTrials_nbr)*100;
    w_BeyondTrap_rate=(w_BeyondTrap_nbr/w_validTrials_nbr)*100;
    w_Hit_BeyondTrap_rate=(w_Hit_BeyondTrap_nbr/w_validTrials_nbr)*100;
    w_Sliding_rate=(w_Sliding_nbr/w_validTrials_nbr)*100;
    w_Hit_Sliding_rate=(w_Hit_Sliding_nbr/w_validTrials_nbr)*100;
    w_PulledStrongly_rate=(w_PulledStrongly_nbr/w_validTrials_nbr)*100;
    w_Hit_PulledStrongly_rate=(w_Hit_PulledStrongly_nbr/w_validTrials_nbr)*100;
    w_kick_rate=(w_kick_nbr/w_validTrials_nbr)*100;
    w_Hit_kick_rate=(w_Hit_kick_nbr/w_validTrials_nbr)*100;
    w_volte_rate=(w_volte_nbr/w_validTrials_nbr)*100;
    w_Hit_volte_rate=(w_Hit_volte_nbr/w_validTrials_nbr)*100;
    w_whiplash_rate=(w_whiplash_nbr/w_validTrials_nbr)*100;
    w_Hit_whiplash_rate=(w_Hit_whiplash_nbr/w_validTrials_nbr)*100;
    w_ShaftCorrection_rate=(w_ShaftCorrection_nbr/w_validTrials_nbr)*100;
    w_Hit_ShaftCorrection_rate=(w_Hit_ShaftCorrection_nbr/w_validTrials_nbr)*100;
    w_v_mvt_rate=(w_v_mvt_nbr/w_validTrials_nbr)*100;
    w_Hit_v_mvt_rate=(w_Hit_v_mvt_nbr/w_validTrials_nbr)*100;
    w_screen_rate=(w_screen_nbr/w_validTrials_nbr)*100;
    w_Hit_screen_rate=(w_Hit_screen_nbr/w_validTrials_nbr)*100;
    
    week_Behavior_Mistakes(w,:)={WOI,w_validTrials_nbr, w_Success_nbr, w_Success_rate,...
        w_stereotyped_nbr,w_MultipleAttempts_nbr,w_Hit_MultipleAttempts_nbr,w_Hit_MultipleAttempts_rate,w_Overshoot_nbr,w_Hit_Overshoot_nbr,w_Hit_Overshoot_rate,...
        w_BeyondTrap_nbr, w_BeyondTrap_rate, w_Hit_BeyondTrap_nbr, w_Hit_BeyondTrap_rate,w_Sliding_nbr,w_Sliding_rate,w_Hit_Sliding_nbr,w_Hit_Sliding_rate,...
        w_PulledStrongly_nbr,w_PulledStrongly_rate,w_Hit_PulledStrongly_nbr,w_Hit_PulledStrongly_rate,w_kick_nbr,w_kick_rate,w_Hit_kick_nbr,w_Hit_kick_rate,...
        w_whiplash_nbr,w_whiplash_rate,w_Hit_whiplash_nbr,w_Hit_whiplash_rate,w_ShaftCorrection_nbr,w_ShaftCorrection_rate,w_Hit_ShaftCorrection_nbr,w_Hit_ShaftCorrection_rate,...
        w_v_mvt_nbr,w_v_mvt_rate,w_Hit_v_mvt_nbr,w_Hit_v_mvt_rate,w_volte_nbr,w_volte_rate,w_Hit_volte_nbr,w_Hit_volte_rate,...
        w_HandAfter_BackHandle_nbr,w_HandAfter_RestRake_nbr,w_HandAfter_PlaceTarget_nbr,w_HandAfter_TouchTarget_nbr,w_HandAfter_StillMove_nbr,...
        w_stereotyped_rate,w_MultipleAttempts_rate,w_Overshoot_rate,w_MotorTwitches_nbr,w_MotorTwitches_rate,w_Hit_MotorTwitches_nbr,w_Hit_MotorTwitches_rate,...
        w_HandAfter_BackHandle_rate,w_HandAfter_RestRake_rate,w_HandAfter_PlaceTarget_rate,w_HandAfter_TouchTarget_rate,w_HandAfter_StillMove_rate,...
        w_screen_nbr,w_screen_rate,w_Hit_screen_nbr,w_Hit_screen_rate,...
        conditionLeft_nbr, conditionCenter_nbr, conditionRight_nbr,...
        stereotyped_l_nbr, stereotyped_c_nbr, stereotyped_r_nbr,...
        MultipleAttempts_l_nbr, MultipleAttempts_c_nbr, MultipleAttempts_r_nbr,...
        Overshoot_l_nbr, Overshoot_c_nbr, Overshoot_r_nbr,...
        HandAfter_BackHandle_l_nbr,HandAfter_BackHandle_c_nbr,HandAfter_BackHandle_r_nbr,...
        HandAfter_RestRake_l_nbr, HandAfter_RestRake_c_nbr, HandAfter_RestRake_r_nbr,...
        HandAfter_PlaceTarget_l_nbr, HandAfter_PlaceTarget_c_nbr, HandAfter_PlaceTarget_r_nbr,...
        HandAfter_TouchTarget_l_nbr,HandAfter_TouchTarget_c_nbr,HandAfter_TouchTarget_r_nbr,...
        HandAfter_StillMove_l_nbr,HandAfter_StillMove_c_nbr,HandAfter_StillMove_r_nbr,...
        PerfectTrials_nbr};

end


%save table in output directory