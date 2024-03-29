function [direction,  video_idx, clean_trial]=ExtractVideoTrial(subject, date, directions, coder)

output_path=fullfile('E:\project\video_coding\', subject,'table');
  
date_xls=replace(date,'.','-');
date_xls=insertAfter(date_xls,6,'20');
date_backward=[date_xls(end-3:end) date_xls(end-6:end-5) date_xls(end-9:end-8)];
videocod_file=fullfile(output_path, ['motor_rake_' date_backward '_' date_xls '_' coder '.xlsx']);

videotable = readtable(videocod_file);

% %aligned trial
%             l_A_idx=find((videotable.RakeStarting==15 & strcmp(videotable.TargetStarting,'b')));
%             c_A_idx=find((videotable.RakeStarting==17 & strcmp(videotable.TargetStarting,'c')));
%             r_A_idx=find((videotable.RakeStarting==19 & strcmp(videotable.TargetStarting,'d')));
% 
%             AlignedTrial=[l_A_idx ; c_A_idx ; r_A_idx];
% 
% %lateral trial - L: right to left movement
%             l_L_Right2Left=find((strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==16|videotable.RakeStarting==17|...
%             videotable.RakeStarting==18|videotable.RakeStarting==19|videotable.RakeStarting==20)));
%             c_L_Right2Left=find((strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==18|videotable.RakeStarting==19|...
%             videotable.RakeStarting==20)));
%             r_L_Right2Left=find((strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==20|videotable.RakeStarting==21)));
%             
%             L_Right2Left=[l_L_Right2Left ; c_L_Right2Left ; r_L_Right2Left];
%         
%  %lateral trial - L: left to right movement
%             l_L_Left2Right=find((strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==12|videotable.RakeStarting==13|...
%             videotable.RakeStarting==14)));
%             c_L_Left2Right=find((strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==14|videotable.RakeStarting==15|...
%             videotable.RakeStarting==16)));
%             r_L_Left2Right=find((strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==14|videotable.RakeStarting==15|...
%             videotable.RakeStarting==16|videotable.RakeStarting==17|videotable.RakeStarting==18)));
%         
%             L_Left2Right=[l_L_Left2Right ; c_L_Left2Right ; r_L_Left2Right];
%         
% %reach trial - R: forward right to left movement
%             l_R_Right2Left=find((strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==21|...
%             videotable.RakeStarting==22|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7|...
%             videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11)));
%             c_R_Right2Left=find((strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==21|videotable.RakeStarting==22|...
%             videotable.RakeStarting==7|videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|...
%             videotable.RakeStarting==11)));
%             r_R_Right2Left=find((strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==22|videotable.RakeStarting==9|...
%             videotable.RakeStarting==10|videotable.RakeStarting==11)));
%         
%             R_Right2Left=[l_R_Right2Left ; c_R_Right2Left ; r_R_Right2Left];
%         
% %reach trial - R: forward, left to right movement
%             l_R_Left2Right=find((strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==12|videotable.RakeStarting==1|...
%             videotable.RakeStarting==2|videotable.RakeStarting==3)));
%             c_R_Left2Right=find((strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==12|videotable.RakeStarting==13|...
%             videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|videotable.RakeStarting==4|...
%             videotable.RakeStarting==5)));
%             r_R_Left2Right=find((strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==12|videotable.RakeStarting==13|...
%             videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|...
%             videotable.RakeStarting==4|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7)));
%         
%             R_Left2Right=[l_R_Left2Right ; c_R_Left2Right ; r_R_Left2Right];
% 
% AlignedTrial_list = videotable.Date(AlignedTrial);
% L_Right2Left_list = videotable.Date(L_Right2Left);
% L_Left2Right_list = videotable.Date(L_Left2Right);
% R_Right2Left_list = videotable.Date(R_Right2Left);
% R_Left2Right_list = videotable.Date(R_Left2Right);

if strcmp(subject,'samovar')==1
%clean trial - overall condition, direction
clean_trial=find(videotable.beyond_trap==0 & ...
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
            ~strcmp(videotable.comments,'shaft correction'));
        
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
                (~strcmp(videotable.comments,'volte')==1 | ...
                ~strcmp(videotable.comments,'kick')==1 | ...
                ~strcmp(videotable.comments,'momentum gain')==1 | ...
                ~strcmp(videotable.comments,'shaft correction')==1 | ...
                ~strcmp(videotable.comments,'v mvt')==1));
            
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
                (~strcmp(videotable.comments,'volte')==1 | ...
                ~strcmp(videotable.comments,'kick')==1 | ...
                ~strcmp(videotable.comments,'momentum gain')==1 | ...
                ~strcmp(videotable.comments,'shaft correction')==1 | ...
                ~strcmp(videotable.comments,'v mvt')==1));
    
    
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
                (~strcmp(videotable.comments,'volte')==1 | ...
                ~strcmp(videotable.comments,'kick')==1 | ...
                ~strcmp(videotable.comments,'momentum gain')==1 | ...
                ~strcmp(videotable.comments,'shaft correction')==1 | ...
                ~strcmp(videotable.comments,'v mvt')==1));
            
       %all directions but aligned
    clean_directions=find(((strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==16 | videotable.RakeStarting==17 | ...
        videotable.RakeStarting==18 | videotable.RakeStarting==19 | videotable.RakeStarting==20 | videotable.RakeStarting==21|...
        videotable.RakeStarting==22 | videotable.RakeStarting==5 | videotable.RakeStarting==6 | videotable.RakeStarting==7 |...
        videotable.RakeStarting==8 | videotable.RakeStarting==9 | videotable.RakeStarting==10 | videotable.RakeStarting==11)) | ...
        (strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==18 | videotable.RakeStarting==19 | videotable.RakeStarting==20 | ...
        videotable.RakeStarting==21 | videotable.RakeStarting==22 | videotable.RakeStarting==7 | videotable.RakeStarting==8 | videotable.RakeStarting==9 | ...
        videotable.RakeStarting==10 | videotable.RakeStarting==11)) | ...
        (strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==20|videotable.RakeStarting==21 | videotable.RakeStarting==22|videotable.RakeStarting==9|...
        videotable.RakeStarting==10|videotable.RakeStarting==11)) & ...
        (strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==12 | videotable.RakeStarting==13 | ...
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
                (~strcmp(videotable.comments,'volte')==1 | ...
                ~strcmp(videotable.comments,'kick')==1 | ...
                ~strcmp(videotable.comments,'momentum gain')==1 | ...
                ~strcmp(videotable.comments,'shaft correction')==1 | ...
                ~strcmp(videotable.comments,'v mvt')==1));
            
            
clean_Aligned_Trial_list=videotable.Date(clean_AlignedTrial);      
clean_Right2Left_Trial_list=videotable.Date(clean_Right2Left);
clean_Left2Right_Trial_list=videotable.Date(clean_Left2Right);
clean_directions_Trial_list=videotable.Date(clean_directions);

elseif strcmp(subject,'betta')==1
    
    %clean trial - overall condition, direction
clean_trial=find(videotable.Success==1 & ...
            videotable.MultipleAttempts==0 & ...
            videotable.Overshoot==0 & ...
            (videotable.hand_after_trial==1 | ...
            videotable.hand_after_trial==2) & ...
            videotable.StereotypedPulling== 0 & ...
            videotable.expInterv== 0 & ...
            videotable.touchRakeHead== 0 & ...
            videotable.rakeReleased== 0 & ...
            videotable.ShaftCorrection== 0 & ...
            ~strcmp(videotable.comments,'volte') & ...
            ~strcmp(videotable.comments,'kick') & ...
            ~strcmp(videotable.comments,'momentum gain') & ...
            ~strcmp(videotable.comments,'lift') & ...
            ~strcmp(videotable.comments,'shaft correction'));
        
                    %             (videotable.parasite_mvt==0 | ...
%                                videotable.parasite_mvt==4 | ...   
%                                  videotable.parasite_mvt==5) & ...
        
    %aligned trial    
    clean_AlignedTrial=find(((videotable.RakeStarting==15 & strcmp(videotable.TargetStarting,'b')) | ...
                (videotable.RakeStarting==17 & strcmp(videotable.TargetStarting,'c')) | ...
                (videotable.RakeStarting==19 & strcmp(videotable.TargetStarting,'d'))) & ...
                videotable.Success==1 & ...
                videotable.MultipleAttempts==0 & ...
                videotable.Overshoot==0 & ...               
                videotable.StereotypedPulling== 0 & ...
                videotable.touchRakeHead== 0 & ...
                videotable.rakeReleased== 0 & ...
                videotable.ShaftCorrection== 0 & ...
                (~strcmp(videotable.comments,'volte')==1 | ...
                ~strcmp(videotable.comments,'kick')==1 | ...
                ~strcmp(videotable.comments,'momentum gain')==1 | ...
                ~strcmp(videotable.comments,'shaft correction')==1 | ...
                ~strcmp(videotable.comments,'v mvt')==1));
%              (videotable.hand_after_trial==1 | ...
%                 videotable.hand_after_trial==2) & ...
%                              (videotable.parasite_mvt==0 | ...
%                 videotable.parasite_mvt==4 | ...   
%                 videotable.parasite_mvt==5) & ...
% videotable.expInterv== 0 & ...
            
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
                videotable.Success==1 & ...
                videotable.MultipleAttempts==0 & ...
                (videotable.Overshoot==1 | videotable.Overshoot==0) & ...
                videotable.StereotypedPulling== 0 & ...
                videotable.touchRakeHead== 0 & ...
                videotable.rakeReleased== 0 & ...
                videotable.ShaftCorrection== 0 & ...
                (~strcmp(videotable.comments,'volte')==1 | ...
                ~strcmp(videotable.comments,'kick')==1 | ...
                ~strcmp(videotable.comments,'momentum gain')==1 | ...
                ~strcmp(videotable.comments,'shaft correction')==1 | ...
                ~strcmp(videotable.comments,'v mvt')==1));
 
            % videotable.expInterv== 0 & ...
%             (videotable.hand_after_trial==1 | ...
%                 videotable.hand_after_trial==2) & ...
%                 (videotable.parasite_mvt==0 | ...
%                 videotable.parasite_mvt==4 | ...   
%                 videotable.parasite_mvt==5) & ...

    %Left2Right
    clean_Left2Right=find(((strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==12 | videotable.RakeStarting==13 | ...
        videotable.RakeStarting==14 | videotable.RakeStarting==1 | videotable.RakeStarting==2 | videotable.RakeStarting==3)) | ...
        (strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==14 | videotable.RakeStarting==15 | videotable.RakeStarting==16 | ...
        videotable.RakeStarting==12 | videotable.RakeStarting==13 | videotable.RakeStarting==1 | videotable.RakeStarting==2 | videotable.RakeStarting==3 | ...
        videotable.RakeStarting==4 | videotable.RakeStarting==5)) | ...
        (strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==14 | videotable.RakeStarting==15 | videotable.RakeStarting==16 | videotable.RakeStarting==17 | ...
        videotable.RakeStarting==18 | videotable.RakeStarting==12|videotable.RakeStarting==13 | videotable.RakeStarting==1 | videotable.RakeStarting==2 | ...
        videotable.RakeStarting==3 | videotable.RakeStarting==4 | videotable.RakeStarting==5 | videotable.RakeStarting==6 | videotable.RakeStarting==7)) ) & ...    
                 videotable.Success==1 & ...
                videotable.MultipleAttempts==0 & ...
                (videotable.Overshoot==1 | videotable.Overshoot==0) & ...
                videotable.StereotypedPulling== 0 & ...
                videotable.touchRakeHead== 0 & ...
                videotable.rakeReleased== 0 & ...
                videotable.ShaftCorrection== 0 & ...
                (~strcmp(videotable.comments,'volte')==1 | ...
                ~strcmp(videotable.comments,'kick')==1 | ...
                ~strcmp(videotable.comments,'momentum gain')==1 | ...
                ~strcmp(videotable.comments,'shaft correction')==1 | ...
                ~strcmp(videotable.comments,'v mvt')==1));

            %                 (videotable.hand_after_trial==1 | ...
%                 videotable.hand_after_trial==2) & ...

%                             (videotable.hand_after_trial==1 | ...
%                 videotable.hand_after_trial==2) & ...
%   (videotable.parasite_mvt==0 | ...
%                 videotable.parasite_mvt==3 | ...   
%                 videotable.parasite_mvt==5) & ...          
   

    %all directions but aligned
    clean_directions=find(((strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==16 | videotable.RakeStarting==17 | ...
        videotable.RakeStarting==18 | videotable.RakeStarting==19 | videotable.RakeStarting==20 | videotable.RakeStarting==21|...
        videotable.RakeStarting==22 | videotable.RakeStarting==5 | videotable.RakeStarting==6 | videotable.RakeStarting==7 |...
        videotable.RakeStarting==8 | videotable.RakeStarting==9 | videotable.RakeStarting==10 | videotable.RakeStarting==11)) | ...
        (strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==18 | videotable.RakeStarting==19 | videotable.RakeStarting==20 | ...
        videotable.RakeStarting==21 | videotable.RakeStarting==22 | videotable.RakeStarting==7 | videotable.RakeStarting==8 | videotable.RakeStarting==9 | ...
        videotable.RakeStarting==10 | videotable.RakeStarting==11)) | ...
        (strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==20|videotable.RakeStarting==21 | videotable.RakeStarting==22|videotable.RakeStarting==9|...
        videotable.RakeStarting==10|videotable.RakeStarting==11)) & ...
        (strcmp(videotable.TargetStarting,'b') & (videotable.RakeStarting==12 | videotable.RakeStarting==13 | ...
        videotable.RakeStarting==14 | videotable.RakeStarting==1 | videotable.RakeStarting==2 | videotable.RakeStarting==3)) | ...
        (strcmp(videotable.TargetStarting,'c') & (videotable.RakeStarting==14 | videotable.RakeStarting==15 | videotable.RakeStarting==16 | ...
        videotable.RakeStarting==12 | videotable.RakeStarting==13 | videotable.RakeStarting==1 | videotable.RakeStarting==2 | videotable.RakeStarting==3 | ...
        videotable.RakeStarting==4 | videotable.RakeStarting==5)) | ...
        (strcmp(videotable.TargetStarting,'d') & (videotable.RakeStarting==14 | videotable.RakeStarting==15 | videotable.RakeStarting==16 | videotable.RakeStarting==17 | ...
        videotable.RakeStarting==18 | videotable.RakeStarting==12|videotable.RakeStarting==13 | videotable.RakeStarting==1 | videotable.RakeStarting==2 | ...
        videotable.RakeStarting==3 | videotable.RakeStarting==4 | videotable.RakeStarting==5 | videotable.RakeStarting==6 | videotable.RakeStarting==7)) ) & ...    
                videotable.Success==1 & ...
                videotable.MultipleAttempts==0 & ...
                (videotable.Overshoot==1 | videotable.Overshoot==0) & ...
                videotable.StereotypedPulling== 0 & ...
                videotable.touchRakeHead== 0 & ...
                videotable.rakeReleased== 0 & ...
                videotable.ShaftCorrection== 0 & ...
                (~strcmp(videotable.comments,'volte')==1 | ...
                ~strcmp(videotable.comments,'kick')==1 | ...
                ~strcmp(videotable.comments,'momentum gain')==1 | ...
                ~strcmp(videotable.comments,'shaft correction')==1 | ...
                ~strcmp(videotable.comments,'v mvt')==1));
    
    

clean_Aligned_Trial_list=videotable.Date(clean_AlignedTrial);      
clean_Right2Left_Trial_list=videotable.Date(clean_Right2Left);
clean_Left2Right_Trial_list=videotable.Date(clean_Left2Right);
clean_directions_Trial_list=videotable.Date(clean_directions);

end

video_list={clean_Aligned_Trial_list, clean_directions_Trial_list};

TrialInfo_video={};
for d=1:length(directions)
    TrialInfo_video{end+1}={};
end

for d=1:length(directions)
    dir_list=video_list{d};
    for i=1:length(dir_list)
        TrialOfInterest=dir_list(i);
        TrialCropped=TrialOfInterest{1,1}(10:end);
        TrialInfo_video{i,d}=TrialCropped;
    end
end

trial_info_file = ['E:\project\tool_learning\data\preprocessed_data\', subject '\' date '\trial_info.csv'];
trial_info = readtable(trial_info_file, 'readVariableNames', true, 'delimiter','comma');

good_trial_idx=trial_info.overall_trial(find(strcmp(trial_info.status,'good')));

% fixationtrain_goodtrial=length(find(strcmp(trial_info.task,'fixation_training') & strcmp(trial_info.status,'good')));
% overall_datastructtrial_nbr= length(good_trial_idx) - fixationtrain_goodtrial;
                        
direction=cell(1,length(good_trial_idx));
video_idx=cell(1,length(good_trial_idx));

for d=1:length(directions)
%     if length(trialinfo_video(:,d))==0
%         continue
%     else
        TrialInfo_trial=TrialInfo_video(:,d);
%         kine_idx=1;
%         VideoList_kinematic={};
        for i=1:length(TrialInfo_trial)
            % Find trial for this video
            trial_of_interest=find(strcmp(trial_info.video, TrialInfo_trial(i)));
            overall_TOI=trial_info.overall_trial(trial_of_interest);
            if ~isempty(trial_of_interest) && strcmp(trial_info.status{trial_of_interest},'good') %%use trial_of_interest here because matlab doesn't count the header line 
                direction{good_trial_idx==overall_TOI}=directions{d};
                video_idx{good_trial_idx==overall_TOI}=TrialInfo_trial(i);
            end
        end
        %save(fullfile(output_path,[date '_' directions{d} '_' 'VideoList_kinematic.mat']),'VideoList_kinematic');
%     end
end
% clean_trial_test{d_idx}=direction;
% end
end
