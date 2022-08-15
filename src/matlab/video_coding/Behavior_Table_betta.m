%code the Success after a failure if the parameter are the same (same rake
%and target starting). Check if the trial before is a failure in the same
%condition and the trial after a success in the same condition. Check also
%if the one with success is with multiple attempts and if after this one
%there is a success in the same condition without multiple attempts.and take
%into consideration the possible invalid trials between a failure and a success. 



subject= 'Betta';
coder= 'ND'; % ND = Noémie Dessaint, SK = Sébastien Kirchherr, GC = Gino Coudé
stage=1;

%dates={'01.07.19','02.07.19','03.07.19','04.07.19','05.07.19','08.07.19','11.07.19','12.07.19','15.07.19'};
%dates={'07.05.19','09.05.19','14.05.19','16.05.19','17.05.19','20.05.19','21.05.19','22.05.19'};
%dates={'04.10.19','07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19',};

dates={'07.05.19','09.05.19','13.05.19','14.05.19','15.05.19','16.05.19','17.05.19','20.05.19','21.05.19','22.05.19','23.05.19','13.06.19','14.06.19',...
    '19.06.19','24.06.19','25.06.19','26.06.19','27.06.19','28.06.19','01.07.19','02.07.19','03.07.19','04.07.19','05.07.19','08.07.19','11.07.19','12.07.19',...
    '15.07.19','17.07.19','18.07.19','19.07.19','22.07.19','23.07.19','24.07.19','25.07.19','26.07.19','31.07.19','01.08.19','02.08.19','05.08.19','06.08.19','07.08.19',...
    '09.08.19','20.08.19','21.08.19','22.08.19','23.08.19','26.08.19','27.08.19','28.08.19','29.08.19','04.09.19','05.09.19','06.09.19','09.09.19','10.09.19','12.09.19',...
    '13.09.19','16.09.19','19.09.19','20.09.19','23.09.19','25.09.19','26.09.19','27.09.19','30.09.19','04.10.19','07.10.19','08.10.19','09.10.19','10.10.19','11.10.19',...
    '14.10.19','16.10.19','17.10.19','18.10.19'};

days_nbr=length(dates);

behaviors={'Success','Stereotyped pulling','Multiple attempts','touch rake head','pulled in steps',...
    'Shaft correction','Overshoot','parasite mvt'};

%variable count
%variables={};

output_path=fullfile('E:\project\video_coding\', subject,'table');

Behavior=table('Size',[days_nbr 46],'VariableTypes',{'string','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double','double','double','double','double','double',...
    'double','double','double','double','double','double','double'});
Behavior.Properties.VariableNames={'date','ValidTrial','cube','Left','Center','Right','Success nbr','Success','Thirds',...
    'Modulo','SuccessSessionStart nbr','SuccessSessionMiddle nbr','SuccessSessionEnd nbr','SuccessSessionStart',...
    'SuccessSessionMiddle','SuccessSessionEnd','DaySuccessSessionStart','DaySuccessSessionMiddle','DaySuccessSessionEnd',...
    'SuccessLeft nbr','SuccessLeft','SuccessCenter nbr','SuccessCenter','SuccessRight nbr','SuccessRight','DaySuccessLeft',...
    'DaySuccessCenter','DaySuccessRight','SuccessCube nbr','SuccessCube','DaySuccessCube','SuccessAligned nbr',...
    'SuccessAligned','DaySuccessAligned','SuccessR2L nbr','SuccessR2L','DaySuccessR2L','SuccessL2R nbr','SuccessL2R',...
    'DaySuccessL2R','MultipleAttempt_nbr','SuccessMultipleAttempt_nbr','SuccessMultipleAttempt','Overshoot_nbr',...
    'SuccessOvershoot_nbr','SuccessOvershoot'};

%fhgmdfghqmfghqù
for d=1:length(dates)
    DOI=dates(d);
    date_xls=replace(dates{d},'.','-');
    date_xls=insertAfter(date_xls,6,'20');
    date_backward=[date_xls(end-3:end) date_xls(end-6:end-5) date_xls(end-9:end-8)];
    videocod_file=fullfile(output_path, ['motor_rake_' date_backward '_' date_xls '_' coder '.xlsx']);
    
    videotable=readtable(videocod_file);
    
    validTrials=find(videotable.ValidVideo==1);
    validTrials_nbr=length(validTrials);
    thirds=floor(validTrials_nbr/3);
    modulo=mod(validTrials_nbr,3);
    onethird_idx=validTrials(1:thirds);
    twothird_idx=validTrials(thirds+1:2*thirds+modulo);
    threethird_idx=validTrials(2*thirds+modulo+1:3*thirds+modulo);
    
    Success=find(videotable.Success==1);
    Success_nbr=length(Success);
    Success_rate=(Success_nbr/validTrials_nbr)*100;
    
    Success_oneT_nbr=length(find(videotable.Success(onethird_idx)==1));
    Success_twoT_nbr=length(find(videotable.Success(twothird_idx)==1));
    Success_threeT_nbr=length(find(videotable.Success(threethird_idx)==1));
    Success_oneT_rate=(Success_oneT_nbr/thirds)*100;
    Success_twoT_rate=(Success_twoT_nbr/(thirds+modulo))*100;
    Success_threeT_rate=(Success_threeT_nbr/thirds)*100;
    
    Success_day_oneT_rate=(Success_oneT_nbr/validTrials_nbr)*100;
    Success_day_twoT_rate=(Success_twoT_nbr/validTrials_nbr)*100;
    Success_day_threeT_rate=(Success_threeT_nbr/validTrials_nbr)*100;
    
    conditionLeft_idx=find(strcmp(videotable.TargetStarting,'b'));
    conditionLeft_nbr=length(conditionLeft_idx);
    Success_left_nbr=length(find(videotable.Success(conditionLeft_idx)==1));
    Success_left_rate=(Success_left_nbr/conditionLeft_nbr)*100;
    Success_day_left_rate=(Success_left_nbr/validTrials_nbr)*100;
    
    conditionCenter_idx=find(strcmp(videotable.TargetStarting,'c'));
    conditionCenter_nbr=length(conditionCenter_idx);
    Success_Center_nbr=length(find(videotable.Success(conditionCenter_idx)==1));
    Success_Center_rate=(Success_Center_nbr/conditionCenter_nbr)*100;
    Success_day_center_rate=(Success_Center_nbr/validTrials_nbr)*100;
    
    conditionRight_idx=find(strcmp(videotable.TargetStarting,'d'));
    conditionRight_nbr=length(conditionRight_idx);
    Success_Right_nbr=length(find(videotable.Success(conditionRight_idx)==1));
    Success_Right_rate=(Success_Right_nbr/conditionRight_nbr)*100;
    Success_day_right_rate=(Success_Right_nbr/validTrials_nbr)*100;
    
    CubeTrial_idx=find(videotable.withCube==1);
    CubeTrial_nbr=length(CubeTrial_idx);
    SuccessCube_nbr=length(find(videotable.Success(CubeTrial_idx)==1));
    SuccessCube_rate=(SuccessCube_nbr/CubeTrial_nbr)*100;
    Success_day_Cube_rate=(SuccessCube_nbr/validTrials_nbr)*100;
    
    alignedTrial_idx=find((videotable.RakeStarting==15 & strcmp(videotable.TargetStarting,'b')) | ...
         (videotable.RakeStarting==17 & strcmp(videotable.TargetStarting,'c')) | ...
         (videotable.RakeStarting==19 & strcmp(videotable.TargetStarting,'d')));
    alignedTrial_nbr=length(alignedTrial_idx);
    SuccessAligned_nbr=length(find(videotable.Success(alignedTrial_idx)==1));
    SuccessAligned_rate=(SuccessAligned_nbr/alignedTrial_nbr)*100;
    Success_day_Aligned_rate=(SuccessAligned_nbr/validTrials_nbr)*100;
     
     Right2left=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==16|videotable.RakeStarting==17|...
    videotable.RakeStarting==18|videotable.RakeStarting==19|videotable.RakeStarting==20|videotable.RakeStarting==21|...
    videotable.RakeStarting==22|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7|...
    videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11))|...
    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==18|videotable.RakeStarting==19|...
    videotable.RakeStarting==20|videotable.RakeStarting==21|videotable.RakeStarting==22|videotable.RakeStarting==7|...
    videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11))|...
    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==20|videotable.RakeStarting==21|...
    videotable.RakeStarting==22|videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11)));

    Right2left_idx=find(Right2left);
    Right2left_nbr=length(Right2left_idx);
    SuccessR2L_nbr=length(find(videotable.Success(Right2left_idx)==1));
    SuccessR2L_rate=(SuccessR2L_nbr/Right2left_nbr)*100;
    Success_day_R2L_rate=(SuccessR2L_nbr/validTrials_nbr)*100;
    
    Left2right=((strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
    videotable.RakeStarting==14|videotable.RakeStarting==15|videotable.RakeStarting==16|videotable.RakeStarting==17|...
    videotable.RakeStarting==18|videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|...
    videotable.RakeStarting==4|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7))|...
    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
    videotable.RakeStarting==14|videotable.RakeStarting==15|videotable.RakeStarting==16|videotable.RakeStarting==1|...
    videotable.RakeStarting==2|videotable.RakeStarting==3|videotable.RakeStarting==4|videotable.RakeStarting==5))|...
    (strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
    videotable.RakeStarting==14|videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3)));
    
    Left2right_idx=find(Left2right);
    Left2right_nbr=length(Left2right_idx);
    SuccessL2R_nbr=length(find(videotable.Success(Left2right_idx)==1));
    SuccessL2R_rate=(SuccessL2R_nbr/Left2right_nbr)*100;
    Success_day_L2R_rate=(SuccessL2R_nbr/validTrials_nbr)*100;
    
    MultipleAttempts_idx=find(videotable.MultipleAttempts==1);
    MultipleAttempts_nbr=length(MultipleAttempts_idx);
    Success_MultipleAttempts_nbr=length(find(videotable.Success(MultipleAttempts_idx)==1));
    Success_MultipleAttempts_rate=(Success_MultipleAttempts_nbr/MultipleAttempts_nbr)*100;
    Success_day_MultipleAttempts_rate=(Success_MultipleAttempts_nbr/validTrials_nbr)*100;
    
    Overshoot_idx=find(videotable.Overshoot==1);
    Overshoot_nbr=length(Overshoot_idx);
    Success_Overshoot_nbr=length(find(videotable.Success(Overshoot_idx)==1));
    Success_Overshoot_rate=(Success_Overshoot_nbr/Overshoot_nbr)*100;
    Success_day_Overshoot_rate=(Success_Overshoot_nbr/validTrials_nbr)*100;
    
    Behavior(d,:)={DOI,validTrials_nbr,CubeTrial_nbr,conditionLeft_nbr,conditionCenter_nbr,conditionRight_nbr,...
        Success_nbr,Success_rate,thirds,modulo,Success_oneT_nbr,Success_twoT_nbr,Success_threeT_nbr,...
        Success_oneT_rate,Success_twoT_rate,Success_threeT_rate,Success_day_oneT_rate,Success_day_twoT_rate,...
        Success_day_threeT_rate,Success_left_nbr,Success_left_rate,Success_Center_nbr,Success_Center_rate,...
        Success_Right_nbr,Success_Right_rate,Success_day_left_rate,Success_day_center_rate,...
        Success_day_right_rate,SuccessCube_nbr,SuccessCube_rate,Success_day_Cube_rate,alignedTrial_nbr,...
        SuccessAligned_rate,Success_day_Aligned_rate,Right2left_nbr,SuccessR2L_rate,Success_day_R2L_rate,...
        Left2right_nbr,SuccessL2R_rate,Success_day_L2R_rate,MultipleAttempts_nbr,Success_MultipleAttempts_nbr,...
        Success_MultipleAttempts_rate,Overshoot_nbr,Success_Overshoot_nbr,Success_Overshoot_rate};
end



%save table in output directory