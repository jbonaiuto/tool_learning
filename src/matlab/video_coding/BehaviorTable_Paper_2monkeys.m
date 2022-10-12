%BehaviorTable_week_DirectionByCondition_Samovar
addpath('../..');

exp_info=init_exp_info();

subject= 'Betta'; % 'Betta'

if strcmp(subject,'Betta')
    dates={'07.05.19','09.05.19','13.05.19','14.05.19','15.05.19','16.05.19','17.05.19',...
    '20.05.19','21.05.19','22.05.19','23.05.19','13.06.19','14.06.19','19.06.19','24.06.19',...
    '25.06.19','26.06.19','27.06.19','28.06.19','01.07.19','02.07.19','03.07.19','04.07.19',...
    '05.07.19','08.07.19','11.07.19','12.07.19','15.07.19','17.07.19','18.07.19','19.07.19',...
    '22.07.19','23.07.19','24.07.19','25.07.19','31.07.19','01.08.19','02.08.19','05.08.19',...
    '06.08.19','07.08.19','09.08.19','20.08.19','21.08.19','23.08.19','26.08.19','27.08.19',...
    '28.08.19','29.08.19','04.09.19','05.09.19','06.09.19','09.09.19','10.09.19','12.09.19',...
    '13.09.19','16.09.19','18.09.19','23.09.19','25.09.19','26.09.19','27.09.19','30.09.19',...
    '04.10.19','07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19',...
    '17.10.19','18.10.19'};

    coder= 'ND'; %coder of the video

elseif strcmp(subject,'Samovar')
    dates={'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21',...
        '29.06.21','30.06.21','02.07.21','06.07.21','08.07.21','09.07.21','13.07.21','14.07.21',...
        '15.07.21','16.07.21','27.07.21','28.07.21','29.07.21','30.07.21','03.08.21','04.08.21',...
        '05.08.21','06.08.21','10.08.21','11.08.21','12.08.21','13.08.21','17.08.21','18.08.21',...
        '19.08.21','20.08.21','24.08.21','25.08.21','27.08.21','31.08.21','01.09.21','02.09.21',...
        '03.09.21','07.09.21','08.09.21','09.09.21','10.09.21','14.09.21','15.09.21','17.09.21',...
        '21.09.21','22.09.21','23.09.21','24.09.21','29.09.21','30.09.21','01.10.21','05.10.21',...
        '06.10.21','07.10.21','08.10.21','11.10.21','12.10.21','13.10.21','14.10.21','26.10.21',...
        '27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'};
    
    coder= 'SK';
end

output_path_fig=fullfile(exp_info.base_output_dir, 'figures', 'behavior', subject);
 
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
    
    if strcmp(subject,'Betta')
        WeekOfRec{3,d}=w-12; % to have the week of recording not the week of the year
    elseif strcmp(subject,'Samovar')
        WeekOfRec{3,d}=w-21; 
    end

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

if strcmp(subject,'Betta')
    weeks=weeks-12; 
elseif strcmp(subject,'Samovar')
    weeks=weeks-21; 
end
week_idx=unique(weeks);
w_nbr=length(week_idx);

output_path=fullfile('E:\project\video_coding\', subject,'table');

behavior_paper=table('Size',[w_nbr 77],'VariableTypes',{'double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double'});

behavior_paper.Properties.VariableNames={'WOI','validTrials_nbr','Success_nbr','Success_rate',...
        'Hit_A_rate','Hit_L_Right2Left_rate','Hit_L_Left2Right_rate',...
        'Hit_F_Right2Left_rate','Hit_F_Left2Right_rate',...
        'Hit_day_A_rate','Hit_day_L_Right2Left_rate','Hit_day_L_Left2Right_rate',...
        'Hit_day_F_Right2Left_rate','Hit_day_F_Left2Right_rate',...
        'A_rate', 'L_Right2Left_rate', 'L_Left2Right_rate', ...
        'F_Right2Left_rate','F_Left2Right_rate',...
        'Hit_dist_0_nbr','Hit_dist_1_nbr','Hit_dist_2_nbr','Hit_dist_3_nbr',...
        'Hit_dist_0_rate','Hit_dist_1_rate','Hit_dist_2_rate','Hit_dist_3_rate',...
        'Hit_day_dist_0_rate','Hit_day_dist_1_rate','Hit_day_dist_2_rate','Hit_day_dist_3_rate',...
        'dist_0_rate','dist_1_rate','dist_2_rate','dist_3_rate',...
        'stereotyped_nbr','stereotyped_rate',...
        'MultipleAttempts_nbr','MultipleAttempts_rate','Hit_MultipleAttempts_nbr','Hit_MultipleAttempts_rate',...
        'BeyondTrap_nbr','BeyondTrap_rate','Hit_BeyondTrap_nbr','Hit_BeyondTrap_rate',...
        'kick_nbr','kick_rate','Hit_kick_nbr','Hit_kick_rate',...
        'ShaftCorrection_nbr','ShaftCorrection_rate','Hit_ShaftCorrection_nbr','Hit_ShaftCorrection_rate',...
        'v_mvt_nbr','v_mvt_rate','Hit_v_mvt_nbr','Hit_v_mvt_rate',...
        'HandAfter_BackHandle_nbr','HandAfter_RestRake_nbr','HandAfter_PlaceTarget_nbr',...
        'HandAfter_TouchTarget_nbr','HandAfter_StillMove_nbr',...
        'MotorTwitches_nbr','MotorTwitches_rate','Hit_MotorTwitches_nbr','Hit_MotorTwitches_rate',...
        'HandAfter_BackHandle_rate','HandAfter_RestRake_rate','HandAfter_PlaceTarget_rate',...
        'HandAfter_TouchTarget_rate','HandAfter_StillMove_rate',...
        'screen_nbr','screen_rate','Hit_screen_nbr','Hit_screen_rate',...
        'guided_nbr','guided_rate'};

for w=1:w_nbr
    WOI=week_idx(w);
    
    w_validTrials_nbr=0;
    w_Success_nbr=0;

    w_A_nbr=0;
    w_Hit_A_nbr=0;
    w_L_Right2Left_nbr=0;
    w_Hit_L_Right2Left_nbr=0;
    w_L_Left2Right_nbr=0;
    w_Hit_L_Left2Right_nbr=0;
    w_F_Right2Left_nbr=0;
    w_Hit_F_Right2Left_nbr=0;
    w_F_Left2Right_nbr=0;
    w_Hit_F_Left2Right_nbr=0;
    
    w_dist_0_nbr=0;
    w_Hit_dist_0_nbr=0;
    w_dist_1_nbr=0;
    w_Hit_dist_1_nbr=0;
    w_dist_2_nbr=0;
    w_Hit_dist_2_nbr=0;
    w_dist_3_nbr=0;
    w_Hit_dist_3_nbr=0;
    
    w_stereotyped_nbr=0;
    
    w_MultipleAttempts_nbr=0;
    w_Hit_MultipleAttempts_nbr=0;

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

    w_kick_nbr=0;
    w_Hit_kick_nbr=0;

    w_ShaftCorrection_nbr=0;
    w_Hit_ShaftCorrection_nbr=0;
    
    w_v_mvt_nbr=0;
    w_Hit_v_mvt_nbr=0;

    w_screen_nbr=0;
    w_Hit_screen_nbr=0;
    
    w_guided_nbr=0;
    
    for d=1:length(dates)
        if weeks(d)==WOI
            DOI=dates(d);
            date_xls=replace(dates{d},'.','-');
            date_xls=insertAfter(date_xls,6,'20');
            date_backward=[date_xls(end-3:end) date_xls(end-6:end-5) date_xls(end-9:end-8)];
            videocod_file=fullfile(output_path, ['motor_rake_' date_backward '_' date_xls '_' coder '.xlsx']);

            videotable=readtable(videocod_file);

            validTrials=find(videotable.ValidVideo==1);
            validTrials_nbr=length(validTrials);
            
            w_validTrials_nbr=w_validTrials_nbr+validTrials_nbr;

       %% overall success
            Success=find(videotable.Success==1);
            Success_nbr=length(Success);
           
            w_Success_nbr=w_Success_nbr+Success_nbr;
           
%                    % Bootstrap estimation
%                     w_Success_nbr=w_Success_nbr+Success_nbr;
% 
%                     vt_success_Nan=isnan(videotable.Success);
%                     vt_success_NoNan=videotable.Success(~vt_success_Nan);
% 
%                     if week_TrialSuccess==0
%                         week_TrialSuccess=vt_success_NoNan';
%                     else
%                         week_TrialSuccess=cat(2,week_TrialSuccess,vt_success_NoNan');
%                     end
%                     task_TS{1,w}=week_TrialSuccess;
                    
                    
       %% directions 
       %aligned trial - A
            A_idx=find((videotable.RakeStarting==15 & strcmp(videotable.TargetStarting,'b'))|...
                        (videotable.RakeStarting==17 & strcmp(videotable.TargetStarting,'c'))|...
                        (videotable.RakeStarting==19 & strcmp(videotable.TargetStarting,'d')));

            A_nbr=length(A_idx);
            Hit_A_nbr=length(find(videotable.Success(A_idx)==1));

            w_A_nbr=w_A_nbr+A_nbr;
            w_Hit_A_nbr=w_Hit_A_nbr+Hit_A_nbr;

       %lateral trial - L: right to left movement
            L_Right2Left=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==16|videotable.RakeStarting==17|...
                    videotable.RakeStarting==18|videotable.RakeStarting==19|videotable.RakeStarting==20))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==18|videotable.RakeStarting==19|...
                    videotable.RakeStarting==20))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==20|videotable.RakeStarting==21)));

            L_Right2Left_idx=find(L_Right2Left);
            L_Right2Left_nbr=length(L_Right2Left_idx);
            Hit_L_Right2Left_nbr=length(find(videotable.Success(L_Right2Left_idx)==1));

            w_L_Right2Left_nbr=w_L_Right2Left_nbr+L_Right2Left_nbr;
            w_Hit_L_Right2Left_nbr=w_Hit_L_Right2Left_nbr+Hit_L_Right2Left_nbr;

        %lateral trial - L: left to right movement
            L_Left2Right=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                    videotable.RakeStarting==14))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==14|videotable.RakeStarting==15|...
                     videotable.RakeStarting==16))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==14|videotable.RakeStarting==15|...
                    videotable.RakeStarting==16|videotable.RakeStarting==17|videotable.RakeStarting==18)));

            L_Left2Right_idx=find(L_Left2Right);
            L_Left2Right_nbr=length(L_Left2Right_idx);
            Hit_L_Left2Right_nbr=length(find(videotable.Success(L_Left2Right_idx)==1));

            w_L_Left2Right_nbr=w_L_Left2Right_nbr+L_Left2Right_nbr;
            w_Hit_L_Left2Right_nbr=w_Hit_L_Left2Right_nbr+Hit_L_Left2Right_nbr;

        %forward trial - F: forward right to left movement
            F_Right2Left=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==21|...
                    videotable.RakeStarting==22|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7|...
                    videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==21|videotable.RakeStarting==22|...
                    videotable.RakeStarting==7|videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|...
                    videotable.RakeStarting==11))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==22|videotable.RakeStarting==9|...
                    videotable.RakeStarting==10|videotable.RakeStarting==11)));

            F_Right2Left_idx=find(F_Right2Left);
            F_Right2Left_nbr=length(F_Right2Left_idx);
            Hit_F_Right2Left_nbr=length(find(videotable.Success(F_Right2Left_idx)==1));

            w_F_Right2Left_nbr=w_F_Right2Left_nbr+F_Right2Left_nbr;
            w_Hit_F_Right2Left_nbr=w_Hit_F_Right2Left_nbr+Hit_F_Right2Left_nbr;

        %reach trial - R: forward, left to right movement
            F_Left2Right=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==12|videotable.RakeStarting==1|...
                    videotable.RakeStarting==2|videotable.RakeStarting==3))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                    videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|videotable.RakeStarting==4|...
                    videotable.RakeStarting==5))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                    videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|...
                    videotable.RakeStarting==4|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7)));

            F_Left2Right_idx=find(F_Left2Right);
            F_Left2Right_nbr=length(F_Left2Right_idx);
            Hit_F_Left2Right_nbr=length(find(videotable.Success(F_Left2Right_idx)==1));

            w_F_Left2Right_nbr=w_F_Left2Right_nbr+F_Left2Right_nbr;
            w_Hit_F_Left2Right_nbr=w_Hit_F_Left2Right_nbr+Hit_F_Left2Right_nbr;
        
        %% rake-target distance
        %rake-target distance level 0
            dist_0=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==15))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==17))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==19)));

            dist_0_idx=find(dist_0);
            dist_0_nbr=length(dist_0_idx);
            Hit_dist_0_nbr=length(find(videotable.Success(dist_0)==1));

            w_dist_0_nbr=w_dist_0_nbr+dist_0_nbr;
            w_Hit_dist_0_nbr=w_Hit_dist_0_nbr+Hit_dist_0_nbr;

        %distance 1
            dist_1=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==16|videotable.RakeStarting==14))|...
                        (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==18|videotable.RakeStarting==16))|...
                        (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==20|videotable.RakeStarting==18)));

            dist_1_idx=find(dist_1);
            dist_1_nbr=length(dist_1_idx);
            Hit_dist_1_nbr=length(find(videotable.Success(dist_1)==1));

            w_dist_1_nbr=w_dist_1_nbr+dist_1_nbr;
            w_Hit_dist_1_nbr=w_Hit_dist_1_nbr+Hit_dist_1_nbr;

       %distance 2
            dist_2=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==17|videotable.RakeStarting==18|...
                    videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==13|videotable.RakeStarting==2|videotable.RakeStarting==3))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==19|videotable.RakeStarting==7|videotable.RakeStarting==8|...
                    videotable.RakeStarting==15|videotable.RakeStarting==4|videotable.RakeStarting==5))|...    
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==21|videotable.RakeStarting==10|videotable.RakeStarting==9|...
                    videotable.RakeStarting==17|videotable.RakeStarting==6|videotable.RakeStarting==7|videotable.RakeStarting==16)));

            dist_2_idx=find(dist_2);    
            dist_2_nbr=length(dist_2_idx);
            Hit_dist_2_nbr=length(find(videotable.Success(dist_2)==1));

            w_dist_2_nbr=w_dist_2_nbr+dist_2_nbr;
            w_Hit_dist_2_nbr=w_Hit_dist_2_nbr+Hit_dist_2_nbr;

       %distance 3
            dist_3=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==19|videotable.RakeStarting==20|videotable.RakeStarting==21|...
                    videotable.RakeStarting==22|videotable.RakeStarting==7|videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|...
                    videotable.RakeStarting==11|videotable.RakeStarting==12|videotable.RakeStarting==1))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==20|videotable.RakeStarting==21|videotable.RakeStarting==22|...
                    videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11|videotable.RakeStarting==14|videotable.RakeStarting==13|...
                    videotable.RakeStarting==12|videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3))|... 
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==22|videotable.RakeStarting==11|videotable.RakeStarting==15|...
                    videotable.RakeStarting==14|videotable.RakeStarting==13|videotable.RakeStarting==12|videotable.RakeStarting==5|videotable.RakeStarting==4|...
                    videotable.RakeStarting==3|videotable.RakeStarting==2|videotable.RakeStarting==1)));

            dist_3_idx=find(dist_3);
            dist_3_nbr=length(dist_3_idx);
            Hit_dist_3_nbr=length(find(videotable.Success(dist_3)==1));

            w_dist_3_nbr=w_dist_3_nbr+dist_3_nbr;
            w_Hit_dist_3_nbr=w_Hit_dist_3_nbr+Hit_dist_3_nbr;

        %% understanding behavior
            if strcmp(subject,'Betta')
                stereotyped_idx=find(videotable.StereotypedPulling==1);
            elseif strcmp(subject,'Samovar')
                stereotyped_idx=find(videotable.pulledStrongly==2);
            end
            stereotyped_nbr=length(stereotyped_idx);
            w_stereotyped_nbr=w_stereotyped_nbr+stereotyped_nbr;

            MultipleAttempts_idx=find(videotable.MultipleAttempts==1);
            MultipleAttempts_nbr=length(MultipleAttempts_idx);
            Hit_MultipleAttempts_nbr=length(find(videotable.Success(MultipleAttempts_idx)==1));
            w_MultipleAttempts_nbr=w_MultipleAttempts_nbr+MultipleAttempts_nbr;
            w_Hit_MultipleAttempts_nbr=w_Hit_MultipleAttempts_nbr + Hit_MultipleAttempts_nbr;

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

       %% motor control behavior
            MotorTwitches_idx=find(videotable.parasite_mvt==5 | videotable.parasite_mvt==3);
            MotorTwitches_nbr=length(MotorTwitches_idx);
            Hit_MotorTwitches_nbr=length(find(videotable.Success(MotorTwitches_idx)==1));
            w_MotorTwitches_nbr=w_MotorTwitches_nbr + MotorTwitches_nbr;
            w_Hit_MotorTwitches_nbr=w_Hit_MotorTwitches_nbr+Hit_MotorTwitches_nbr;
            
            kick_idx=find(strcmp(videotable.comments,'kick'));
            kick_nbr=length(kick_idx);
            Hit_kick_nbr=length(find(videotable.Success(kick_idx)==1));
            w_kick_nbr=w_kick_nbr + kick_nbr;
            w_Hit_kick_nbr=w_Hit_kick_nbr+Hit_kick_nbr;

            v_mvt_idx=find(strcmp(videotable.comments,'v mvt'));
            v_mvt_nbr=length(v_mvt_idx);
            Hit_v_mvt_nbr=length(find(videotable.Success(v_mvt_idx)==1));
            w_v_mvt_nbr=w_v_mvt_nbr + v_mvt_nbr;
            w_Hit_v_mvt_nbr=w_Hit_v_mvt_nbr+Hit_v_mvt_nbr;

            ShaftCorrection_idx=find(strcmp(videotable.comments,'shaft correction'));
            ShaftCorrection_nbr=length(ShaftCorrection_idx);
            Hit_ShaftCorrection_nbr=length(find(videotable.Success(ShaftCorrection_idx)==1));
            w_ShaftCorrection_nbr=w_ShaftCorrection_nbr + ShaftCorrection_nbr;
            w_Hit_ShaftCorrection_nbr=w_Hit_ShaftCorrection_nbr + Hit_ShaftCorrection_nbr;
            
       %% experimenter behavior
            if strcmp(subject,'Betta')
                w_BeyondTrap_nbr=NaN;
                w_Hit_BeyondTrap_nbr=NaN;
            elseif strcmp(subject,'Samovar')
                BeyondTrap_idx=find(videotable.beyond_trap==1);
                BeyondTrap_nbr=length(BeyondTrap_idx);
                Hit_BeyondTrap_nbr=length(find(videotable.Success(BeyondTrap_idx)==1));
                w_BeyondTrap_nbr=w_BeyondTrap_nbr + BeyondTrap_nbr;
                w_Hit_BeyondTrap_nbr=w_Hit_BeyondTrap_nbr+Hit_BeyondTrap_nbr;
            end

            if strcmp(subject,'Betta')
                screen_idx=find(videotable.Screen==1);
            elseif strcmp(subject,'Samovar')
                screen_idx=find(videotable.exp_hand_Screen==1);
            end
            screen_nbr=length(screen_idx);
            Hit_screen_nbr=length(find(videotable.Success(screen_idx)==1));
            w_screen_nbr=w_screen_nbr + screen_nbr;
            w_Hit_screen_nbr=w_Hit_screen_nbr+Hit_screen_nbr;
            
            if strcmp(subject,'Betta')
                guided_idx=find(videotable.expInterv==1);
                guided_nbr=length(guided_idx);
                w_guided_nbr=w_guided_nbr + guided_nbr;
            elseif strcmp(subject,'Samovar')
                w_guided_nbr=NaN;
            end

        else
            continue
        end
    end            
 %%   
    
    w_Success_rate=(w_Success_nbr/w_validTrials_nbr)*100;
 
    w_A_rate=(w_A_nbr/w_validTrials_nbr)*100; 
    w_Hit_day_A_rate=(w_Hit_A_nbr/w_validTrials_nbr)*100;
        if w_Hit_A_nbr<10
            w_Hit_day_A_rate=NaN;
        else
            w_Hit_A_rate=(w_Hit_A_nbr/w_A_nbr)*100;   
        end
    
    w_L_Right2Left_rate=(w_L_Right2Left_nbr/w_validTrials_nbr)*100;
    w_Hit_day_L_Right2Left_rate=(w_Hit_L_Right2Left_nbr/w_validTrials_nbr)*100;
        if w_L_Right2Left_nbr<10
            w_Hit_L_Right2Left_rate=NaN;
        else
            w_Hit_L_Right2Left_rate=(w_Hit_L_Right2Left_nbr/w_L_Right2Left_nbr)*100;
        end    
    
    w_L_Left2Right_rate=(w_L_Left2Right_nbr/w_validTrials_nbr)*100;
    w_Hit_day_L_Left2Right_rate=(w_Hit_L_Left2Right_nbr/w_validTrials_nbr)*100;
        if w_L_Left2Right_nbr<10
            w_Hit_L_Left2Right_rate=NaN;
        else
            w_Hit_L_Left2Right_rate=(w_Hit_L_Left2Right_nbr/w_L_Left2Right_nbr)*100;
        end
    
    w_R_Right2Left_rate=(w_F_Right2Left_nbr/w_validTrials_nbr)*100; 
    w_Hit_R_Right2Left_rate=(w_Hit_F_Right2Left_nbr/w_F_Right2Left_nbr)*100;
    w_Hit_day_R_Right2Left_rate=(w_Hit_F_Right2Left_nbr/w_validTrials_nbr)*100;
    
    w_R_Left2Right_rate=(w_F_Left2Right_nbr/w_validTrials_nbr)*100;
    w_Hit_day_R_Left2Right_rate=(w_Hit_F_Left2Right_nbr/w_validTrials_nbr)*100;
        if w_F_Left2Right_nbr<10
            w_Hit_R_Left2Right_rate=NaN;
        else
            w_Hit_R_Left2Right_rate=(w_Hit_F_Left2Right_nbr/w_F_Left2Right_nbr)*100;
        end   
     
    w_dist_0_rate=(w_dist_0_nbr/w_validTrials_nbr)*100;
    w_Hit_day_dist_0_rate=(w_Hit_dist_0_nbr/w_validTrials_nbr)*100;
        if w_dist_0_nbr<10
            w_Hit_dist_0_rate=NaN;
        else
            w_Hit_dist_0_rate=(w_Hit_dist_0_nbr/w_dist_0_nbr)*100;
        end    
    
    w_dist_1_rate=(w_dist_1_nbr/w_validTrials_nbr)*100;
    w_Hit_day_dist_1_rate=(w_Hit_dist_1_nbr/w_validTrials_nbr)*100;
        if w_dist_1_nbr<10
            w_Hit_dist_1_rate=NaN;
        else
            w_Hit_dist_1_rate=(w_Hit_dist_1_nbr/w_dist_1_nbr)*100;
        end     
    
    w_dist_2_rate=(w_dist_2_nbr/w_validTrials_nbr)*100;   
    w_Hit_day_dist_2_rate=(w_Hit_dist_2_nbr/w_validTrials_nbr)*100;
        if w_dist_2_nbr<10
            w_Hit_dist_2_rate=NaN;
        else
            w_Hit_dist_2_rate=(w_Hit_dist_2_nbr/w_dist_2_nbr)*100;
        end
    
    w_dist_3_rate=(w_dist_3_nbr/w_validTrials_nbr)*100;
    w_Hit_day_dist_3_rate=(w_Hit_dist_3_nbr/w_validTrials_nbr)*100;
        if w_dist_3_nbr<10
            w_Hit_dist_3_rate=NaN;
        else
            w_Hit_dist_3_rate=(w_Hit_dist_3_nbr/w_dist_3_nbr)*100;
        end
    
    w_stereotyped_rate=(w_stereotyped_nbr/w_validTrials_nbr)*100;    
    
    w_MultipleAttempts_rate=(w_MultipleAttempts_nbr/w_validTrials_nbr)*100;
    w_Hit_MultipleAttempts_rate=(w_Hit_MultipleAttempts_nbr/w_validTrials_nbr)*100;

    w_HandAfter_BackHandle_rate=(w_HandAfter_BackHandle_nbr/w_validTrials_nbr)*100;
    w_HandAfter_RestRake_rate=(w_HandAfter_RestRake_nbr/w_validTrials_nbr)*100;
    w_HandAfter_PlaceTarget_rate=(w_HandAfter_PlaceTarget_nbr/w_validTrials_nbr)*100;
    w_HandAfter_TouchTarget_rate=(w_HandAfter_TouchTarget_nbr/w_validTrials_nbr)*100;
    w_HandAfter_StillMove_rate=(w_HandAfter_StillMove_nbr/w_validTrials_nbr)*100;
    
    w_MotorTwitches_rate=(w_MotorTwitches_nbr/w_validTrials_nbr)*100;
    w_Hit_MotorTwitches_rate=(w_Hit_MotorTwitches_nbr/w_validTrials_nbr)*100;
    
    w_kick_rate=(w_kick_nbr/w_validTrials_nbr)*100;
    w_Hit_kick_rate=(w_Hit_kick_nbr/w_validTrials_nbr)*100;
 
    w_ShaftCorrection_rate=(w_ShaftCorrection_nbr/w_validTrials_nbr)*100;
    w_Hit_ShaftCorrection_rate=(w_Hit_ShaftCorrection_nbr/w_validTrials_nbr)*100;
    
    w_v_mvt_rate=(w_v_mvt_nbr/w_validTrials_nbr)*100;
    w_Hit_v_mvt_rate=(w_Hit_v_mvt_nbr/w_validTrials_nbr)*100;
    
    w_BeyondTrap_rate=(w_BeyondTrap_nbr/w_validTrials_nbr)*100;
    w_Hit_BeyondTrap_rate=(w_Hit_BeyondTrap_nbr/w_validTrials_nbr)*100;
    
    w_screen_rate=(w_screen_nbr/w_validTrials_nbr)*100;
    w_Hit_screen_rate=(w_Hit_screen_nbr/w_validTrials_nbr)*100;
    
    w_guided_rate=(w_guided_nbr/w_validTrials_nbr)*100;
    
 %%     
    behavior_paper(w,:)={WOI,w_validTrials_nbr,w_Success_nbr,w_Success_rate,...
        w_Hit_A_rate,w_Hit_L_Right2Left_rate,w_Hit_L_Left2Right_rate,...
        w_Hit_R_Right2Left_rate,w_Hit_R_Left2Right_rate,...
        w_Hit_day_A_rate,w_Hit_day_L_Right2Left_rate,w_Hit_day_L_Left2Right_rate,...
        w_Hit_day_R_Right2Left_rate,w_Hit_day_R_Left2Right_rate,...
        w_A_rate, w_L_Right2Left_rate, w_L_Left2Right_rate, ...
        w_R_Right2Left_rate,w_R_Left2Right_rate,...
        w_Hit_dist_0_nbr,w_Hit_dist_1_nbr,w_Hit_dist_2_nbr,w_Hit_dist_3_nbr,...
        w_Hit_dist_0_rate,w_Hit_dist_1_rate,w_Hit_dist_2_rate,w_Hit_dist_3_rate,...
        w_Hit_day_dist_0_rate,w_Hit_day_dist_1_rate,w_Hit_day_dist_2_rate,w_Hit_day_dist_3_rate,...
        w_dist_0_rate,w_dist_1_rate,w_dist_2_rate,w_dist_3_rate,...
        w_stereotyped_nbr,w_stereotyped_rate,...
        w_MultipleAttempts_nbr,w_MultipleAttempts_rate,w_Hit_MultipleAttempts_nbr,w_Hit_MultipleAttempts_rate,...
        w_BeyondTrap_nbr, w_BeyondTrap_rate, w_Hit_BeyondTrap_nbr, w_Hit_BeyondTrap_rate,...
        w_kick_nbr,w_kick_rate,w_Hit_kick_nbr,w_Hit_kick_rate,...
        w_ShaftCorrection_nbr,w_ShaftCorrection_rate,w_Hit_ShaftCorrection_nbr,w_Hit_ShaftCorrection_rate,...
        w_v_mvt_nbr,w_v_mvt_rate,w_Hit_v_mvt_nbr,w_Hit_v_mvt_rate,...
        w_HandAfter_BackHandle_nbr,w_HandAfter_RestRake_nbr,w_HandAfter_PlaceTarget_nbr,...
        w_HandAfter_TouchTarget_nbr,w_HandAfter_StillMove_nbr,...
        w_MotorTwitches_nbr,w_MotorTwitches_rate,w_Hit_MotorTwitches_nbr,w_Hit_MotorTwitches_rate,...
        w_HandAfter_BackHandle_rate,w_HandAfter_RestRake_rate,w_HandAfter_PlaceTarget_rate,...
        w_HandAfter_TouchTarget_rate,w_HandAfter_StillMove_rate,...
        w_screen_nbr,w_screen_rate,w_Hit_screen_nbr,w_Hit_screen_rate,...
        w_guided_nbr,w_guided_rate};
end

writetable(behavior_paper,fullfile(output_path_fig,...
     [subject '_' 'BehaviorPaper' '.xls']))