%BehaviorTable_week_DirectionByCondition_Samovar
addpath('../../..');
addpath('../../../spike_data_processing');

exp_info=init_exp_info();

subject= 'Samovar'; % betta use the left hand, Samovar the right hand so it changes the direction of the movement
coder= 'SK'; % ND = Noémie Dessaint, SK = Sébastien Kirchherr, GC = Gino Coudé

dates={'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21',...
    '29.06.21','30.06.21','02.07.21','06.07.21','08.07.21','09.07.21','13.07.21','14.07.21',...
    '15.07.21','16.07.21','27.07.21','28.07.21','29.07.21','30.07.21','03.08.21','04.08.21',...
    '05.08.21','06.08.21','10.08.21','11.08.21','12.08.21','13.08.21','17.08.21','18.08.21',...
    '19.08.21','20.08.21','24.08.21','25.08.21','27.08.21','31.08.21','01.09.21','02.09.21',...
    '03.09.21','07.09.21','08.09.21','09.09.21','10.09.21','14.09.21','15.09.21','17.09.21',...
    '21.09.21','22.09.21','23.09.21','24.09.21','29.09.21','30.09.21','01.10.21','05.10.21',...
    '06.10.21','07.10.21','08.10.21','11.10.21','12.10.21','13.10.21','14.10.21','26.10.21',...
    '27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'};

% %dates used to work on MU data
% dates={'11.06.21','15.06.21','16.06.21','17.06.21','22.06.21','23.06.21','09.07.21','13.07.21',...
%'14.07.21','15.07.21','16.07.21','27.07.21','28.07.21','29.07.21','30.07.21','03.08.21','04.08.21',...
%'10.08.21','11.08.21','13.08.21','17.08.21','18.08.21','19.08.21','20.08.21','24.08.21','25.08.21',...
%'27.08.21','31.08.21','01.09.21','02.09.21','03.09.21','07.09.21','09.09.21','10.09.21','14.09.21',...
%'17.09.21','11.10.21','13.10.21','14.10.21','26.10.21','27.10.21','28.10.21','29.10.21','02.11.21',...
%'03.11.21'};

days_nbr=length(dates);

output_path_fig=fullfile(exp_info.base_output_dir, 'figures', 'behavior', subject);
 
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

Behavior_week_DirCond=table('Size',[w_nbr 104],'VariableTypes',{'double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double'});
    
Behavior_week_DirCond.Properties.VariableNames={'week of rec','validTrials_nbr','Success_nbr','Success_rate',...
     'Hit_A_rate','Hit_L_Right2Left_rate','Hit_L_Left2Right_rate','Hit_R_Right2Left_rate','Hit_R_Left2Right_rate',...
     'Hit_day_A_rate','Hit_day_L_Right2Left_rate','Hit_day_L_Left2Right_rate','Hit_day_R_Right2Left_rate','Hit_day_R_Left2Right_rate',...
     'Hit_diff_0_nbr','Hit_diff_1_nbr','Hit_diff_2_nbr','Hit_diff_3_nbr',...
     'Hit_diff_0_rate','Hit_diff_1_rate','Hit_diff_2_rate','Hit_diff_3_rate',...
     'Hit_day_diff_0_rate','Hit_day_diff_1_rate','Hit_day_diff_2_rate','Hit_day_diff_3_rate',...
     'conditionLeft_nbr','conditionCenter_nbr','conditionRight_nbr',...
     'Hit_Left_nbr','Hit_Left_rate','Hit_day_Left_rate',...
     'Hit_Center_nbr','Hit_Center_rate','Hit_day_Center_rate',...
     'Hit_Right_nbr','Hit_Right_rate','Hit_day_Right_rate',...
     'l_A_nbr','Hit_l_A_rate','Hit_day_l_A_rate', 'Hit_cond_l_A_rate',...
     'c_A_nbr','Hit_c_A_rate','Hit_day_c_A_rate', 'Hit_cond_c_A_rate',...
     'r_A_nbr','Hit_r_A_rate','Hit_day_r_A_rate', 'Hit_cond_r_A_rate',...
     'l_R_Right2Left_nbr', 'Hit_l_R_Right2Left_rate', 'Hit_day_l_R_Right2Left_rate', 'Hit_cond_l_R_Right2Left_rate',...
     'c_R_Right2Left_nbr', 'Hit_c_R_Right2Left_rate', 'Hit_day_c_R_Right2Left_rate', 'Hit_cond_c_R_Right2Left_rate',...
     'r_R_Right2Left_nbr', 'Hit_r_R_Right2Left_rate', 'Hit_day_r_R_Right2Left_rate', 'Hit_cond_r_R_Right2Left_rate',...
     'l_R_Left2Right_nbr', 'Hit_l_R_Left2Right_rate', 'Hit_day_l_R_Left2Right_rate', 'Hit_cond_l_R_Left2Right_rate',...
     'c_R_Left2Right_nbr', 'Hit_c_R_Left2Right_rate', 'Hit_day_c_R_Left2Right_rate', 'Hit_cond_c_R_Left2Right_rate',...
     'r_R_Left2Right_nbr', 'Hit_r_R_Left2Right_rate', 'Hit_day_r_R_Left2Right_rate', 'Hit_cond_r_R_Left2Right_rate',...
     'l_L_Right2Left_nbr', 'Hit_l_L_Right2Left_rate', 'Hit_day_l_L_Right2Left_rate', 'Hit_cond_l_L_Right2Left_rate',...
     'c_L_Right2Left_nbr', 'Hit_c_L_Right2Left_rate', 'Hit_day_c_L_Right2Left_rate', 'Hit_cond_c_L_Right2Left_rate',...
     'r_L_Right2Left_nbr', 'Hit_r_L_Right2Left_rate', 'Hit_day_r_L_Right2Left_rate', 'Hit_cond_r_L_Right2Left_rate',...
     'l_L_Left2Right_nbr', 'Hit_l_L_Left2Right_rate', 'Hit_day_l_L_Left2Right_rate', 'Hit_cond_l_L_Left2Right_rate',...
     'c_L_Left2Right_nbr', 'Hit_c_L_Left2Right_rate', 'Hit_day_c_L_Left2Right_rate', 'Hit_cond_c_L_Left2Right_rate',...
     'r_L_Left2Right_nbr', 'Hit_r_L_Left2Right_rate', 'Hit_day_r_L_Left2Right_rate', 'Hit_cond_r_L_Left2Right_rate',...
     'W_clean_AlignedTrial_nbr', 'W_clean_Right2Left_nbr', 'W_clean_Left2Right_nbr',...
     'W_Hit_clean_AlignedTrial_nbr', 'W_Hit_clean_Right2Left_nbr', 'W_Hit_clean_Left2Right_nbr'};


for w=1:w_nbr
    WOI=week_idx(w);
    
    W_validTrials_nbr=0;
    W_Success_nbr=0;
    W_conditionLeft_nbr=0;
    W_Hit_Left_nbr=0;
    W_l_A_nbr=0;
    W_Hit_l_A_nbr=0;
    W_l_L_Right2Left_nbr=0;
    W_Hit_l_L_Right2Left_nbr=0;
    W_l_L_Left2Right_nbr=0;
    W_Hit_l_L_Left2Right_nbr=0;
    W_l_R_Right2Left_nbr=0;
    W_Hit_l_R_Right2Left_nbr=0;
    W_l_R_Left2Right_nbr=0;
    W_Hit_l_R_Left2Right_nbr=0;
    W_conditionCenter_nbr=0;
    W_Hit_Center_nbr=0;
    W_c_A_nbr=0;
    W_Hit_c_A_nbr=0;
    W_c_L_Right2Left_nbr=0;
    W_Hit_c_L_Right2Left_nbr=0;
    W_c_L_Left2Right_nbr=0;
    W_Hit_c_L_Left2Right_nbr=0;
    W_c_R_Right2Left_nbr=0;
    W_Hit_c_R_Right2Left_nbr=0;
    W_c_R_Left2Right_nbr=0;
    W_Hit_c_R_Left2Right_nbr=0;
    W_r_A_nbr=0;
    W_Hit_r_A_nbr=0;
    W_conditionRight_nbr=0;
    W_Hit_Right_nbr=0;
    W_r_L_Right2Left_nbr=0;
    W_Hit_r_L_Right2Left_nbr=0;
    W_r_R_Right2Left_nbr=0;
    W_Hit_r_R_Right2Left_nbr=0;
    W_r_R_Left2Right_nbr=0;
    W_Hit_r_R_Left2Right_nbr=0;
    W_r_L_Left2Right_nbr=0;
    W_Hit_r_L_Left2Right_nbr=0;
    
    W_A_nbr=0;
    W_Hit_A_nbr=0;
    W_L_Right2Left_nbr=0;
    W_Hit_L_Right2Left_nbr=0;
    W_L_Left2Right_nbr=0;
    W_Hit_L_Left2Right_nbr=0;
    W_R_Right2Left_nbr=0;
    W_Hit_R_Right2Left_nbr=0;
    W_R_Left2Right_nbr=0;
    W_Hit_R_Left2Right_nbr=0;
    
    W_clean_AlignedTrial_nbr=0;
    W_clean_Right2Left_nbr=0;
    W_clean_Left2Right_nbr=0;
   
    W_Hit_clean_AlignedTrial_nbr=0;
    W_Hit_clean_Right2Left_nbr=0;
    W_Hit_clean_Left2Right_nbr=0;
    
    W_diff_0_nbr=0;
    W_Hit_diff_0_nbr=0;
    W_diff_1_nbr=0;
    W_Hit_diff_1_nbr=0;
    W_diff_2_nbr=0;
    W_Hit_diff_2_nbr=0;
    W_diff_3_nbr=0;
    W_Hit_diff_3_nbr=0;
    
    
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
            
            W_validTrials_nbr=W_validTrials_nbr+validTrials_nbr;

            Success=find(videotable.Success==1);
            Success_nbr=length(Success);
           
            W_Success_nbr=W_Success_nbr+Success_nbr;
            
          %overall condition
                %aligned trial - A
                    A_idx=find((videotable.RakeStarting==15 & strcmp(videotable.TargetStarting,'b'))|...
                                (videotable.RakeStarting==17 & strcmp(videotable.TargetStarting,'c'))|...
                                (videotable.RakeStarting==19 & strcmp(videotable.TargetStarting,'d')));

                    A_nbr=length(A_idx);
                    Hit_A_nbr=length(find(videotable.Success(A_idx)==1));

                    W_A_nbr=W_A_nbr+A_nbr;
                    W_Hit_A_nbr=W_Hit_A_nbr+Hit_A_nbr;

                  %lateral trial - L: right to left movement
                    L_Right2Left=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==16|videotable.RakeStarting==17|...
                            videotable.RakeStarting==18|videotable.RakeStarting==19|videotable.RakeStarting==20))|...
                            (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==18|videotable.RakeStarting==19|...
                            videotable.RakeStarting==20))|...
                            (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==20|videotable.RakeStarting==21)));


                    L_Right2Left_idx=find(L_Right2Left);
                    L_Right2Left_nbr=length(L_Right2Left_idx);
                    Hit_L_Right2Left_nbr=length(find(videotable.Success(L_Right2Left_idx)==1));

                    W_L_Right2Left_nbr=W_L_Right2Left_nbr+L_Right2Left_nbr;
                    W_Hit_L_Right2Left_nbr=W_Hit_L_Right2Left_nbr+Hit_L_Right2Left_nbr;

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

                    W_L_Left2Right_nbr=W_L_Left2Right_nbr+L_Left2Right_nbr;
                    W_Hit_L_Left2Right_nbr=W_Hit_L_Left2Right_nbr+Hit_L_Left2Right_nbr;

                %reach trial - R: forward right to left movement
                    R_Right2Left=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==21|...
                            videotable.RakeStarting==22|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7|...
                            videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11))|...
                            (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==21|videotable.RakeStarting==22|...
                            videotable.RakeStarting==7|videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|...
                            videotable.RakeStarting==11))|...
                            (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==22|videotable.RakeStarting==9|...
                            videotable.RakeStarting==10|videotable.RakeStarting==11)));


                    R_Right2Left_idx=find(R_Right2Left);
                    R_Right2Left_nbr=length(R_Right2Left_idx);
                    Hit_R_Right2Left_nbr=length(find(videotable.Success(R_Right2Left_idx)==1));

                    W_R_Right2Left_nbr=W_R_Right2Left_nbr+R_Right2Left_nbr;
                    W_Hit_R_Right2Left_nbr=W_Hit_R_Right2Left_nbr+Hit_R_Right2Left_nbr;

                %reach trial - R: forward, left to right movement
                    R_Left2Right=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==12|videotable.RakeStarting==1|...
                            videotable.RakeStarting==2|videotable.RakeStarting==3))|...
                            (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                            videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|videotable.RakeStarting==4|...
                            videotable.RakeStarting==5))|...
                            (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                            videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|...
                            videotable.RakeStarting==4|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7)));


                    R_Left2Right_idx=find(R_Left2Right);
                    R_Left2Right_nbr=length(R_Left2Right_idx);
                    Hit_R_Left2Right_nbr=length(find(videotable.Success(R_Left2Right_idx)==1));

                    W_R_Left2Right_nbr=W_R_Left2Right_nbr+R_Left2Right_nbr;
                    W_Hit_R_Left2Right_nbr=W_Hit_R_Left2Right_nbr+Hit_R_Left2Right_nbr;

                %difficulty level 0
                    diff_0=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==15))|...
                            (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==17))|...
                            (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==19)));

                    diff_0_idx=find(diff_0);
                    diff_0_nbr=length(diff_0_idx);
                    Hit_diff_0_nbr=length(find(videotable.Success(diff_0)==1));

                    W_diff_0_nbr=W_diff_0_nbr+diff_0_nbr;
                    W_Hit_diff_0_nbr=W_Hit_diff_0_nbr+Hit_diff_0_nbr;

                %difficulty 1
                    diff_1=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==16|videotable.RakeStarting==14))|...
                                (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==18|videotable.RakeStarting==16))|...
                                (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==20|videotable.RakeStarting==18)));

                    diff_1_idx=find(diff_1);
                    diff_1_nbr=length(diff_1_idx);
                    Hit_diff_1_nbr=length(find(videotable.Success(diff_1)==1));

                    W_diff_1_nbr=W_diff_1_nbr+diff_1_nbr;
                    W_Hit_diff_1_nbr=W_Hit_diff_1_nbr+Hit_diff_1_nbr;

               %difficulty 2
                    diff_2=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==17|videotable.RakeStarting==18|...
                            videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==13|videotable.RakeStarting==2|videotable.RakeStarting==3))|...
                            (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==19|videotable.RakeStarting==7|videotable.RakeStarting==8|...
                            videotable.RakeStarting==15|videotable.RakeStarting==4|videotable.RakeStarting==5))|...    
                            (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==21|videotable.RakeStarting==10|videotable.RakeStarting==9|...
                            videotable.RakeStarting==17|videotable.RakeStarting==6|videotable.RakeStarting==7|videotable.RakeStarting==16)));

                    diff_2_idx=find(diff_2);    
                    diff_2_nbr=length(diff_2_idx);
                    Hit_diff_2_nbr=length(find(videotable.Success(diff_2)==1));

                    W_diff_2_nbr=W_diff_2_nbr+diff_2_nbr;
                    W_Hit_diff_2_nbr=W_Hit_diff_2_nbr+Hit_diff_2_nbr;

               %difficulty 3
                    diff_3=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==19|videotable.RakeStarting==20|videotable.RakeStarting==21|...
                            videotable.RakeStarting==22|videotable.RakeStarting==7|videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|...
                            videotable.RakeStarting==11|videotable.RakeStarting==12|videotable.RakeStarting==1))|...
                            (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==20|videotable.RakeStarting==21|videotable.RakeStarting==22|...
                            videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11|videotable.RakeStarting==14|videotable.RakeStarting==13|...
                            videotable.RakeStarting==12|videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3))|... 
                            (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==22|videotable.RakeStarting==11|videotable.RakeStarting==15|...
                            videotable.RakeStarting==14|videotable.RakeStarting==13|videotable.RakeStarting==12|videotable.RakeStarting==5|videotable.RakeStarting==4|...
                            videotable.RakeStarting==3|videotable.RakeStarting==2|videotable.RakeStarting==1)));

                    diff_3_idx=find(diff_3);
                    diff_3_nbr=length(diff_3_idx);
                    Hit_diff_3_nbr=length(find(videotable.Success(diff_3)==1));

                    W_diff_3_nbr=W_diff_3_nbr+diff_3_nbr;
                    W_Hit_diff_3_nbr=W_Hit_diff_3_nbr+Hit_diff_3_nbr;


      %left condition - l
            conditionLeft_idx=find(strcmp(videotable.TargetStarting,'b'));
            conditionLeft_nbr=length(conditionLeft_idx);
            Hit_Left_nbr=length(find(videotable.Success(conditionLeft_idx)==1));

                W_conditionLeft_nbr=W_conditionLeft_nbr+conditionLeft_nbr;
                W_Hit_Left_nbr=W_Hit_Left_nbr+Hit_Left_nbr;


            %aligned trial - A

                    % use aligned trial without multiple attempt
                l_A_idx=find((videotable.RakeStarting==15 & strcmp(videotable.TargetStarting,'b')));

                l_A_nbr=length(l_A_idx);
                Hit_l_A_nbr=length(find(videotable.Success(l_A_idx)==1));

                    W_l_A_nbr=W_l_A_nbr+l_A_nbr;
                    W_Hit_l_A_nbr=W_Hit_l_A_nbr+Hit_l_A_nbr;


             %lateral trial - L: right to left movement
                l_L_Right2Left=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==16|videotable.RakeStarting==17|...
                videotable.RakeStarting==18|videotable.RakeStarting==19|videotable.RakeStarting==20)));

                l_L_Right2Left_idx=find(l_L_Right2Left);
                l_L_Right2Left_nbr=length(l_L_Right2Left_idx);
                Hit_l_L_Right2Left_nbr=length(find(videotable.Success(l_L_Right2Left_idx)==1));

                    W_l_L_Right2Left_nbr=W_l_L_Right2Left_nbr+l_L_Right2Left_nbr;
                    W_Hit_l_L_Right2Left_nbr=W_Hit_l_L_Right2Left_nbr+Hit_l_L_Right2Left_nbr;


            %lateral trial - L: left to right movement
                l_L_Left2Right=(strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                videotable.RakeStarting==14));

                l_L_Left2Right_idx=find(l_L_Left2Right);
                l_L_Left2Right_nbr=length(l_L_Left2Right_idx);
                Hit_l_L_Left2Right_nbr=length(find(videotable.Success(l_L_Left2Right_idx)==1));

                    W_l_L_Left2Right_nbr=W_l_L_Left2Right_nbr+l_L_Left2Right_nbr;
                    W_Hit_l_L_Left2Right_nbr=W_Hit_l_L_Left2Right_nbr+Hit_l_L_Left2Right_nbr;


            %reach trial - R: forward right to left movement
                l_R_Right2Left=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==21|...
                videotable.RakeStarting==22|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7|...
                videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11)));

                l_R_Right2Left_idx=find(l_R_Right2Left);
                l_R_Right2Left_nbr=length(l_R_Right2Left_idx);
                Hit_l_R_Right2Left_nbr=length(find(videotable.Success(l_R_Right2Left_idx)==1));

                    W_l_R_Right2Left_nbr=W_l_R_Right2Left_nbr+l_R_Right2Left_nbr;
                    W_Hit_l_R_Right2Left_nbr=W_Hit_l_R_Right2Left_nbr+Hit_l_R_Right2Left_nbr;


            %reach trial - R: forward, left to right movement
                l_R_Left2Right=(strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==12|videotable.RakeStarting==1|...
                videotable.RakeStarting==2|videotable.RakeStarting==3));

                l_R_Left2Right_idx=find(l_R_Left2Right);
                l_R_Left2Right_nbr=length(l_R_Left2Right_idx);
                Hit_l_R_Left2Right_nbr=length(find(videotable.Success(l_R_Left2Right_idx)==1));

                    W_l_R_Left2Right_nbr=W_l_R_Left2Right_nbr+l_R_Left2Right_nbr;
                    W_Hit_l_R_Left2Right_nbr=W_Hit_l_R_Left2Right_nbr+Hit_l_R_Left2Right_nbr;




      %center condition - c
            conditionCenter_idx=find(strcmp(videotable.TargetStarting,'c'));
            conditionCenter_nbr=length(conditionCenter_idx);
            Hit_Center_nbr=length(find(videotable.Success(conditionCenter_idx)==1));

                W_conditionCenter_nbr=W_conditionCenter_nbr+conditionCenter_nbr;
                W_Hit_Center_nbr=W_Hit_Center_nbr+Hit_Center_nbr;

            %aligned trial

            % use aligned trial without multiple attempt
                c_A_idx=find((videotable.RakeStarting==17 & strcmp(videotable.TargetStarting,'c')));
                c_A_nbr=length(c_A_idx);
                Hit_c_A_nbr=length(find(videotable.Success(c_A_idx)==1));

                    W_c_A_nbr=W_c_A_nbr+c_A_nbr;
                    W_Hit_c_A_nbr=W_Hit_c_A_nbr+Hit_c_A_nbr;


            %lateral trial: right to left movement
                    c_L_Right2Left=(strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==18|videotable.RakeStarting==19|...
                    videotable.RakeStarting==20));

                c_L_Right2Left_idx=find(c_L_Right2Left);
                c_L_Right2Left_nbr=length(c_L_Right2Left_idx);
                Hit_c_L_Right2Left_nbr=length(find(videotable.Success(c_L_Right2Left_idx)==1));

                    W_c_L_Right2Left_nbr=W_c_L_Right2Left_nbr+c_L_Right2Left_nbr;
                    W_Hit_c_L_Right2Left_nbr=W_Hit_c_L_Right2Left_nbr+Hit_c_L_Right2Left_nbr;


            %lateral trial: left to right movement
                        c_L_Left2Right=(strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==14|videotable.RakeStarting==15|...
                        videotable.RakeStarting==16));

                c_L_Left2Right_idx=find(c_L_Left2Right);
                c_L_Left2Right_nbr=length(c_L_Left2Right_idx);
                Hit_c_L_Left2Right_nbr=length(find(videotable.Success(c_L_Left2Right_idx)==1));

                     W_c_L_Left2Right_nbr=W_c_L_Left2Right_nbr+c_L_Left2Right_nbr;
                    W_Hit_c_L_Left2Right_nbr=W_Hit_c_L_Left2Right_nbr+Hit_c_L_Left2Right_nbr;


            %reach trial: forward right to left movement
                        c_R_Right2Left=(strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==21|videotable.RakeStarting==22|...
                        videotable.RakeStarting==7|videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|...
                        videotable.RakeStarting==11));

                c_R_Right2Left_idx=find(c_R_Right2Left);
                c_R_Right2Left_nbr=length(c_R_Right2Left_idx);
                Hit_c_R_Right2Left_nbr=length(find(videotable.Success(c_R_Right2Left_idx)==1));

                    W_c_R_Right2Left_nbr=W_c_R_Right2Left_nbr+c_R_Right2Left_nbr;
                    W_Hit_c_R_Right2Left_nbr=W_Hit_c_R_Right2Left_nbr+Hit_c_R_Right2Left_nbr;

             %reach trial: forward, left to right movement
                        c_R_Left2Right=(strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                        videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|videotable.RakeStarting==4|...
                        videotable.RakeStarting==5));

                c_R_Left2Right_idx=find(c_R_Left2Right);
                c_R_Left2Right_nbr=length(c_R_Left2Right_idx);
                Hit_c_R_Left2Right_nbr=length(find(videotable.Success(c_R_Left2Right_idx)==1));

                    W_c_R_Left2Right_nbr=W_c_R_Left2Right_nbr+c_R_Left2Right_nbr;
                    W_Hit_c_R_Left2Right_nbr=W_Hit_c_R_Left2Right_nbr+Hit_c_R_Left2Right_nbr;


      %right condition - r
            conditionRight_idx=find(strcmp(videotable.TargetStarting,'d'));
            conditionRight_nbr=length(conditionRight_idx);
            Hit_Right_nbr=length(find(videotable.Success(conditionRight_idx)==1));

                W_conditionRight_nbr=W_conditionRight_nbr+conditionRight_nbr;
                W_Hit_Right_nbr=W_Hit_Right_nbr+Hit_Right_nbr;


            %aligned trial

            % use aligned trial without multiple attempt
                r_A_idx=find((videotable.RakeStarting==19 & strcmp(videotable.TargetStarting,'d')));
                r_A_nbr=length(r_A_idx);
                Hit_r_A_nbr=length(find(videotable.Success(r_A_idx)==1));

                    W_r_A_nbr=W_r_A_nbr+r_A_nbr;
                    W_Hit_r_A_nbr=W_Hit_r_A_nbr+Hit_r_A_nbr;


            %lateral trial: right to left movement
                    r_L_Right2Left=((strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==20|videotable.RakeStarting==21)));

                r_L_Right2Left_idx=find(r_L_Right2Left);
                r_L_Right2Left_nbr=length(r_L_Right2Left_idx);
                Hit_r_L_Right2Left_nbr=length(find(videotable.Success(r_L_Right2Left_idx)==1));

                    W_r_L_Right2Left_nbr=W_r_L_Right2Left_nbr+r_L_Right2Left_nbr;
                    W_Hit_r_L_Right2Left_nbr=W_Hit_r_L_Right2Left_nbr+Hit_r_L_Right2Left_nbr;

            %lateral trial: left to right movement
                        r_L_Left2Right=((strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==14|videotable.RakeStarting==15|...
                        videotable.RakeStarting==16|videotable.RakeStarting==17|videotable.RakeStarting==18)));

                r_L_Left2Right_idx=find(r_L_Left2Right);
                r_L_Left2Right_nbr=length(r_L_Left2Right_idx);
                Hit_r_L_Left2Right_nbr=length(find(videotable.Success(r_L_Left2Right_idx)==1));

                    W_r_L_Left2Right_nbr=W_r_L_Left2Right_nbr+r_L_Left2Right_nbr;
                    W_Hit_r_L_Left2Right_nbr=W_Hit_r_L_Left2Right_nbr+Hit_r_L_Left2Right_nbr;

            %reach trial: forward right to left movement
                        r_R_Right2Left=((strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==22|videotable.RakeStarting==9|...
                        videotable.RakeStarting==10|videotable.RakeStarting==11)));

                r_R_Right2Left_idx=find(r_R_Right2Left);
                r_R_Right2Left_nbr=length(r_R_Right2Left_idx);
                Hit_r_R_Right2Left_nbr=length(find(videotable.Success(r_R_Right2Left_idx)==1));

                    W_r_R_Right2Left_nbr=W_r_R_Right2Left_nbr + r_R_Right2Left_nbr;
                    W_Hit_r_R_Right2Left_nbr=W_Hit_r_R_Right2Left_nbr + Hit_r_R_Right2Left_nbr;

            %reach trial: forward, left to right movement
                        r_R_Left2Right=((strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                        videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|...
                        videotable.RakeStarting==4|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7)));

                r_R_Left2Right_idx=find(r_R_Left2Right);
                r_R_Left2Right_nbr=length(r_R_Left2Right_idx);
                Hit_r_R_Left2Right_nbr=length(find(videotable.Success(r_R_Left2Right_idx)==1));

                    W_r_R_Left2Right_nbr=W_r_R_Left2Right_nbr+r_R_Left2Right_nbr;
                    W_Hit_r_R_Left2Right_nbr=W_Hit_r_R_Left2Right_nbr+Hit_r_R_Left2Right_nbr;
                        
      %clean trial for MU/HMM analysis
                     %aligned trial    
             clean_AlignedTrial=find(((videotable.RakeStarting==15 & strcmp(videotable.TargetStarting,'b')) | ...
        (videotable.RakeStarting==17 & strcmp(videotable.TargetStarting,'c')) | ...
        (videotable.RakeStarting==19 & strcmp(videotable.TargetStarting,'d'))) & ...
                videotable.beyond_trap==0 & ...
                videotable.Success==1 & ...
                videotable.MultipleAttempts==0 & ...
                videotable.Overshoot==0 & ...
                (videotable.hand_after_trial==1 | ...
                videotable.hand_after_trial==2) & ...
                (videotable.parasite_mvt==0 | ...
                videotable.parasite_mvt==3 | ...   
                videotable.parasite_mvt==5) & ...
                ~strcmp(videotable.comments,'volte') & ...
                ~strcmp(videotable.comments,'kick') & ...
                ~strcmp(videotable.comments,'momentum gain') & ...
                ~strcmp(videotable.comments,'shaft correction') & ...
                ~strcmp(videotable.comments,'v mvt'));
  
            
 clean_AlignedTrial_idx=find(clean_AlignedTrial);
 clean_AlignedTrial_nbr=length(clean_AlignedTrial_idx);
 Hit_clean_AlignedTrial_nbr=length(find(videotable.Success(clean_AlignedTrial_idx)==1));

 W_clean_AlignedTrial_nbr=W_clean_AlignedTrial_nbr+clean_AlignedTrial_nbr;
 W_Hit_clean_AlignedTrial_nbr=W_Hit_clean_AlignedTrial_nbr+Hit_clean_AlignedTrial_nbr;
 
 
    %Right2Left
    clean_Right2Left=find(((strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==16 | videotable.RakeStarting==17 | ...
        videotable.RakeStarting==18 | videotable.RakeStarting==19 | videotable.RakeStarting==20 | videotable.RakeStarting==21|...
        videotable.RakeStarting==22 | videotable.RakeStarting==5 | videotable.RakeStarting==6 | videotable.RakeStarting==7 |...
        videotable.RakeStarting==8 | videotable.RakeStarting==9 | videotable.RakeStarting==10 | videotable.RakeStarting==11)) | ...
        (strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==18 | videotable.RakeStarting==19 | videotable.RakeStarting==20 | ...
        videotable.RakeStarting==21 | videotable.RakeStarting==22 | videotable.RakeStarting==7 | videotable.RakeStarting==8 | videotable.RakeStarting==9 | ...
        videotable.RakeStarting==10 | videotable.RakeStarting==11)) | ...
        (strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==20|videotable.RakeStarting==21 | videotable.RakeStarting==22|videotable.RakeStarting==9|...
        videotable.RakeStarting==10|videotable.RakeStarting==11))) & ...
                videotable.beyond_trap==0 & ...
                videotable.Success==1 & ...
                videotable.MultipleAttempts==0 & ...
               (videotable.Overshoot==1 | videotable.Overshoot==0) & ...
                (videotable.hand_after_trial==1 | ...
                videotable.hand_after_trial==2) & ...
                (videotable.parasite_mvt==0 | ...
                videotable.parasite_mvt==3 | ...   
                videotable.parasite_mvt==5) & ...
                ~strcmp(videotable.comments,'volte') & ...
                ~strcmp(videotable.comments,'kick') & ...
                ~strcmp(videotable.comments,'momentum gain') & ...
                ~strcmp(videotable.comments,'shaft correction') & ...
                ~strcmp(videotable.comments,'v mvt'));
    
 clean_Right2Left_idx=find(clean_Right2Left);
 clean_Right2Left_nbr=length(clean_Right2Left_idx);
 Hit_clean_Right2Left_nbr=length(find(videotable.Success(clean_Right2Left_idx)==1));

 W_clean_Right2Left_nbr=W_clean_Right2Left_nbr+clean_Right2Left_nbr;
 W_Hit_clean_Right2Left_nbr=W_Hit_clean_Right2Left_nbr+Hit_clean_Right2Left_nbr;
    
    %Left2Right
    clean_Left2Right=find(((strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==12 | videotable.RakeStarting==13 | ...
        videotable.RakeStarting==14 | videotable.RakeStarting==1 | videotable.RakeStarting==2 | videotable.RakeStarting==3)) | ...
        (strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==14 | videotable.RakeStarting==15 | videotable.RakeStarting==16 | ...
        videotable.RakeStarting==12 | videotable.RakeStarting==13 | videotable.RakeStarting==1 | videotable.RakeStarting==2 | videotable.RakeStarting==3 | ...
        videotable.RakeStarting==4 | videotable.RakeStarting==5)) | ...
        (strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==14 | videotable.RakeStarting==15 | videotable.RakeStarting==16 | videotable.RakeStarting==17 | ...
        videotable.RakeStarting==18 | videotable.RakeStarting==12|videotable.RakeStarting==13 | videotable.RakeStarting==1 | videotable.RakeStarting==2 | ...
        videotable.RakeStarting==3 | videotable.RakeStarting==4 | videotable.RakeStarting==5 | videotable.RakeStarting==6 | videotable.RakeStarting==7)) ) & ...    
                videotable.beyond_trap==0 & ...
                videotable.Success==1 & ...
                videotable.MultipleAttempts==0 & ...
                (videotable.Overshoot==1 | videotable.Overshoot==0) & ...
                (videotable.hand_after_trial==1 | ...
                videotable.hand_after_trial==2) & ...
                (videotable.parasite_mvt==0 | ...
                videotable.parasite_mvt==3 | ...   
                videotable.parasite_mvt==5) & ...
                ~strcmp(videotable.comments,'volte') & ...
                ~strcmp(videotable.comments,'kick') & ...
                ~strcmp(videotable.comments,'momentum gain') & ...
                ~strcmp(videotable.comments,'shaft correction')& ...
                ~strcmp(videotable.comments,'v mvt'));
            
       
 clean_Left2Right_idx=find(clean_Left2Right);
 clean_Left2Right_nbr=length(clean_Left2Right_idx);
 Hit_clean_Left2Right_nbr=length(find(videotable.Success(clean_Left2Right_idx)==1));

 W_clean_Left2Right_nbr=W_clean_Left2Right_nbr+clean_Left2Right_nbr;
 W_Hit_clean_Left2Right_nbr=W_Hit_clean_Left2Right_nbr+Hit_clean_Left2Right_nbr;
        else
            continue
        end
    end            
    
    W_Success_rate=(W_Success_nbr/W_validTrials_nbr)*100;
    
    if W_Hit_A_nbr>2
        W_Hit_A_rate=(W_Hit_A_nbr/W_A_nbr)*100;
        W_Hit_day_A_rate=(W_Hit_A_nbr/W_validTrials_nbr)*100;
    else
        W_Hit_A_rate=(W_Hit_A_nbr/W_A_nbr)*100;
        W_Hit_day_A_rate=(W_Hit_A_nbr/W_validTrials_nbr)*100;
    end
    
    if W_L_Right2Left_nbr<10
        W_Hit_L_Right2Left_rate=NaN;
    else
        W_Hit_L_Right2Left_rate=(W_Hit_L_Right2Left_nbr/W_L_Right2Left_nbr)*100;
    end
    W_Hit_day_L_Right2Left_rate=(W_Hit_L_Right2Left_nbr/W_validTrials_nbr)*100;
    
    if W_L_Left2Right_nbr<10
        W_Hit_L_Left2Right_rate=NaN;
    else
        W_Hit_L_Left2Right_rate=(W_Hit_L_Left2Right_nbr/W_L_Left2Right_nbr)*100;
    end
    W_Hit_day_L_Left2Right_rate=(W_Hit_L_Left2Right_nbr/W_validTrials_nbr)*100;
    
    W_Hit_R_Right2Left_rate=(W_Hit_R_Right2Left_nbr/W_R_Right2Left_nbr)*100;
    W_Hit_day_R_Right2Left_rate=(W_Hit_R_Right2Left_nbr/W_validTrials_nbr)*100;
    
    if W_R_Left2Right_nbr<10
        W_Hit_R_Left2Right_rate=NaN;
    else    
        W_Hit_R_Left2Right_rate=(W_Hit_R_Left2Right_nbr/W_R_Left2Right_nbr)*100;
    end
    W_Hit_day_R_Left2Right_rate=(W_Hit_R_Left2Right_nbr/W_validTrials_nbr)*100;
    
    if W_conditionLeft_nbr
        W_Hit_Left_rate=NaN;
    else
        W_Hit_Left_rate=(W_Hit_Left_nbr/W_conditionLeft_nbr)*100;
    end
    W_Hit_day_Left_rate=(W_Hit_Left_nbr/W_validTrials_nbr)*100;
    
    W_Hit_l_A_rate=(W_Hit_l_A_nbr/W_l_A_nbr)*100;
    W_Hit_day_l_A_rate=(W_Hit_l_A_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_l_A_rate=(W_Hit_l_A_nbr/W_conditionLeft_nbr)*100;
    
    W_Hit_l_L_Right2Left_rate=(W_Hit_l_L_Right2Left_nbr/W_l_L_Right2Left_nbr)*100;
    W_Hit_day_l_L_Right2Left_rate=(W_Hit_l_L_Right2Left_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_l_L_Right2Left_rate=(W_Hit_l_L_Right2Left_nbr/W_conditionLeft_nbr)*100;
    
    W_Hit_l_L_Left2Right_rate=(W_Hit_l_L_Left2Right_nbr/W_l_L_Left2Right_nbr)*100;
    W_Hit_day_l_L_Left2Right_rate=(W_Hit_l_L_Left2Right_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_l_L_Left2Right_rate=(W_Hit_l_L_Left2Right_nbr/W_conditionLeft_nbr)*100;
    
    W_Hit_l_R_Right2Left_rate=(W_Hit_l_R_Right2Left_nbr/W_l_R_Right2Left_nbr)*100;
    W_Hit_day_l_R_Right2Left_rate=(W_Hit_l_R_Right2Left_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_l_R_Right2Left_rate=(W_Hit_l_R_Right2Left_nbr/W_conditionLeft_nbr)*100;
    
    W_Hit_l_R_Left2Right_rate=(W_Hit_l_R_Left2Right_nbr/W_l_R_Left2Right_nbr)*100;
    W_Hit_day_l_R_Left2Right_rate=(W_Hit_l_R_Left2Right_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_l_R_Left2Right_rate=(W_Hit_l_R_Left2Right_nbr/W_conditionLeft_nbr)*100;
    
    W_Hit_Center_rate=(W_Hit_Center_nbr/W_conditionCenter_nbr)*100;
    W_Hit_day_center_rate=(W_Hit_Center_nbr/W_validTrials_nbr)*100;

    W_Hit_c_A_rate=(W_Hit_c_A_nbr/W_c_A_nbr)*100;
    W_Hit_day_c_A_rate=(W_Hit_c_A_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_c_A_rate=(W_Hit_c_A_nbr/W_conditionCenter_nbr)*100;
    
    W_Hit_c_L_Right2Left_rate=(W_Hit_c_L_Right2Left_nbr/W_c_L_Right2Left_nbr)*100;
    W_Hit_day_c_L_Right2Left_rate=(W_Hit_c_L_Right2Left_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_c_L_Right2Left_rate=(W_Hit_c_L_Right2Left_nbr/W_conditionCenter_nbr)*100;
    
    W_Hit_c_L_Left2Right_rate=(W_Hit_c_L_Left2Right_nbr/W_c_L_Left2Right_nbr)*100;
    W_Hit_day_c_L_Left2Right_rate=(W_Hit_c_L_Left2Right_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_c_L_Left2Right_rate=(W_Hit_c_L_Left2Right_nbr/W_conditionCenter_nbr)*100;
    
    W_Hit_c_R_Right2Left_rate=(W_Hit_c_R_Right2Left_nbr/W_c_R_Right2Left_nbr)*100;
    W_Hit_day_c_R_Right2Left_rate=(W_Hit_c_R_Right2Left_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_c_R_Right2Left_rate=(W_Hit_c_R_Right2Left_nbr/W_conditionCenter_nbr)*100;

    W_Hit_c_R_Left2Right_rate=(W_Hit_c_R_Left2Right_nbr/W_c_R_Left2Right_nbr)*100;
    W_Hit_day_c_R_Left2Right_rate=(W_Hit_c_R_Left2Right_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_c_R_Left2Right_rate=(W_Hit_c_R_Left2Right_nbr/W_conditionCenter_nbr)*100;
    
    W_Hit_Right_rate=(W_Hit_Right_nbr/W_conditionRight_nbr)*100;
    W_Hit_day_right_rate=(W_Hit_Right_nbr/W_validTrials_nbr)*100;
    
    W_Hit_r_A_rate=(W_Hit_r_A_nbr/W_r_A_nbr)*100;
    W_Hit_day_r_A_rate=(W_Hit_r_A_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_r_A_rate=(W_Hit_r_A_nbr/W_conditionRight_nbr)*100;
    
    W_Hit_r_L_Right2Left_rate=(W_Hit_r_L_Right2Left_nbr/W_r_L_Right2Left_nbr)*100;
    W_Hit_day_r_L_Right2Left_rate=(W_Hit_r_L_Right2Left_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_r_L_Right2Left_rate=(W_Hit_r_L_Right2Left_nbr/W_conditionRight_nbr)*100;
    
    W_Hit_r_L_Left2Right_rate=(W_Hit_r_L_Left2Right_nbr/W_r_L_Left2Right_nbr)*100;
    W_Hit_day_r_L_Left2Right_rate=(W_Hit_r_L_Left2Right_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_r_L_Left2Right_rate=(W_Hit_r_L_Left2Right_nbr/W_conditionRight_nbr)*100;
    
    W_Hit_r_R_Right2Left_rate=(W_Hit_r_R_Right2Left_nbr/W_r_R_Right2Left_nbr)*100;
    W_Hit_day_r_R_Right2Left_rate=(W_Hit_r_R_Right2Left_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_r_R_Right2Left_rate=(W_Hit_r_R_Right2Left_nbr/W_conditionRight_nbr)*100;
    
    W_Hit_r_R_Left2Right_rate=(W_Hit_r_R_Left2Right_nbr/W_r_R_Left2Right_nbr)*100;
    W_Hit_day_r_R_Left2Right_rate=(W_Hit_r_R_Left2Right_nbr/W_validTrials_nbr)*100;
    W_Hit_cond_r_R_Left2Right_rate=(W_Hit_r_R_Left2Right_nbr/W_conditionRight_nbr)*100;
    
    if W_diff_0_nbr<10
        W_Hit_diff_0_rate=NaN;
    else
        W_Hit_diff_0_rate=(W_Hit_diff_0_nbr/W_diff_0_nbr)*100;
    end    
    W_Hit_day_diff_0_rate=(W_Hit_diff_0_nbr/W_validTrials_nbr)*100;
    
    if W_diff_1_nbr<10
        W_Hit_diff_1_rate=NaN;
    else
        W_Hit_diff_1_rate=(W_Hit_diff_1_nbr/W_diff_1_nbr)*100;
    end
    W_Hit_day_diff_1_rate=(W_Hit_diff_1_nbr/W_validTrials_nbr)*100;
    
    if W_diff_2_nbr<10
        W_Hit_diff_2_rate=NaN;
    else
        W_Hit_diff_2_rate=(W_Hit_diff_2_nbr/W_diff_2_nbr)*100;
    end
    W_Hit_day_diff_2_rate=(W_Hit_diff_2_nbr/W_validTrials_nbr)*100;
    
    if W_diff_3_nbr<10
        W_Hit_diff_3_rate=NaN;
    else
        W_Hit_diff_3_rate=(W_Hit_diff_3_nbr/W_diff_3_nbr)*100;
    end
    W_Hit_day_diff_3_rate=(W_Hit_diff_3_nbr/W_validTrials_nbr)*100;
   

      
    Behavior_week_DirCond(w,:)={WOI,W_validTrials_nbr,W_Success_nbr,W_Success_rate,...
        W_Hit_A_rate,W_Hit_L_Right2Left_rate,W_Hit_L_Left2Right_rate,W_Hit_R_Right2Left_rate,W_Hit_R_Left2Right_rate,...
        W_Hit_day_A_rate,W_Hit_day_L_Right2Left_rate,W_Hit_day_L_Left2Right_rate,W_Hit_day_R_Right2Left_rate,W_Hit_day_R_Left2Right_rate,...
        W_Hit_diff_0_nbr,W_Hit_diff_1_nbr,W_Hit_diff_2_nbr,W_Hit_diff_3_nbr,...
        W_Hit_diff_0_rate,W_Hit_diff_1_rate,W_Hit_diff_2_rate,W_Hit_diff_3_rate,...
        W_Hit_day_diff_0_rate,W_Hit_day_diff_1_rate,W_Hit_day_diff_2_rate,W_Hit_day_diff_3_rate,...
        W_conditionLeft_nbr,W_conditionCenter_nbr,W_conditionRight_nbr,...
        W_Hit_Left_nbr,W_Hit_Left_rate,W_Hit_day_Left_rate,...
        W_Hit_Center_nbr,W_Hit_Center_rate,W_Hit_day_center_rate,...
        W_Hit_Right_nbr,W_Hit_Right_rate,W_Hit_day_right_rate,...
        W_l_A_nbr,W_Hit_l_A_rate, W_Hit_day_l_A_rate, W_Hit_cond_l_A_rate,...
        W_c_A_nbr,W_Hit_c_A_rate, W_Hit_day_c_A_rate, W_Hit_cond_c_A_rate,...
        W_r_A_nbr,W_Hit_r_A_rate, W_Hit_day_r_A_rate, W_Hit_cond_r_A_rate,...
        W_l_R_Right2Left_nbr, W_Hit_l_R_Right2Left_rate, W_Hit_day_l_R_Right2Left_rate, W_Hit_cond_l_R_Right2Left_rate,...
        W_c_R_Right2Left_nbr, W_Hit_c_R_Right2Left_rate, W_Hit_day_c_R_Right2Left_rate, W_Hit_cond_c_R_Right2Left_rate,...
        W_r_R_Right2Left_nbr, W_Hit_r_R_Right2Left_rate, W_Hit_day_r_R_Right2Left_rate, W_Hit_cond_r_R_Right2Left_rate,...
        W_l_R_Left2Right_nbr, W_Hit_l_R_Left2Right_rate, W_Hit_day_l_R_Left2Right_rate, W_Hit_cond_l_R_Left2Right_rate,...
        W_c_R_Left2Right_nbr, W_Hit_c_R_Left2Right_rate, W_Hit_day_c_R_Left2Right_rate, W_Hit_cond_c_R_Left2Right_rate,...
        W_r_R_Left2Right_nbr, W_Hit_r_R_Left2Right_rate, W_Hit_day_r_R_Left2Right_rate, W_Hit_cond_r_R_Left2Right_rate,...
        W_l_L_Right2Left_nbr, W_Hit_l_L_Right2Left_rate, W_Hit_day_l_L_Right2Left_rate, W_Hit_cond_l_L_Right2Left_rate,...
        W_c_L_Right2Left_nbr, W_Hit_c_L_Right2Left_rate, W_Hit_day_c_L_Right2Left_rate, W_Hit_cond_c_L_Right2Left_rate,...
        W_r_L_Right2Left_nbr, W_Hit_r_L_Right2Left_rate, W_Hit_day_r_L_Right2Left_rate, W_Hit_cond_r_L_Right2Left_rate,...
        W_l_L_Left2Right_nbr, W_Hit_l_L_Left2Right_rate, W_Hit_day_l_L_Left2Right_rate, W_Hit_cond_l_L_Left2Right_rate,...
        W_c_L_Left2Right_nbr, W_Hit_c_L_Left2Right_rate, W_Hit_day_c_L_Left2Right_rate, W_Hit_cond_c_L_Left2Right_rate,...
        W_r_L_Left2Right_nbr, W_Hit_r_L_Left2Right_rate, W_Hit_day_r_L_Left2Right_rate, W_Hit_cond_r_L_Left2Right_rate,...
        W_clean_AlignedTrial_nbr, W_clean_Right2Left_nbr, W_clean_Left2Right_nbr,...
        W_Hit_clean_AlignedTrial_nbr, W_Hit_clean_Right2Left_nbr, W_Hit_clean_Left2Right_nbr};

end

writetable(Behavior_week_DirCond,fullfile(output_path_fig,...
     [subject '_' 'BehaviorWeek' '.xls']))