%subject==samovar


videocod_file1 = 'E:\project\video_coding\Samovar\table\rake_coding_grid_in_xlsx\motor_rake_20210804_04-08-2021_SK.xlsx';
videocod_file2 = 'C:\Users\kirchher\Desktop\ISC_CNRS\Team_PPF\team\trainees\Noemie_M1_2022\motor_rake_20210804_04-08-2021_ND.xlsx';
table1 = readtable(videocod_file1);
table2 = readtable(videocod_file2);

%replace the NaN value in the table from the fith column to the end because
%find(~=)identifies NaN as difference
nan_idx=ismissing(table1(:,5:end-1));
table1{:,5:end-1}(nan_idx)=9;

nan_idx=ismissing(table2(:,5:end-1));
table2{:,5:end-1}(nan_idx)=9;

n_trial=height(table1);

beyond_trap1=table1.beyond_trap;
beyond_trap2=table2.beyond_trap;     
    diff_idx=find(beyond_trap1~=beyond_trap2);
    
    disp('beyond_trap1/beyond_trap2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)
    
    
rakeStarting1=table1.RakeStarting;
rakeStarting2=table2.RakeStarting; 

if isa(rakeStarting1,'cell')==1 & isa(rakeStarting2,'cell')==1 
    
    diff_idx=find(strcmp(rakeStarting1,rakeStarting2)==0);
    disp('rakeStarting1/rakeStarting2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)
 
elseif isa(rakeStarting1,'double')==1 & isa(rakeStarting2,'double')==1
    
    nan_idx=ismissing(rakeStarting1);
    rakeStarting1(nan_idx)=0;

    nan_idx=ismissing(rakeStarting2);
    rakeStarting2(nan_idx)=0;
    
    diff_idx=find(rakeStarting1~=rakeStarting2);
    
   disp('rakeStarting1/rakeStarting2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)    
end


targetStarting1=table1.TargetStarting;
targetStarting2=table2.TargetStarting; 
    diff_idx=find(strcmp(targetStarting1,targetStarting2)==0);
    disp('targetStarting1/targetStarting2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)

Success1=table1.Success;
Success2=table2.Success;     
    diff_idx=find(Success1~=Success2);
    
    disp('Success1/Success2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)
    
pulledStrongly1=table1.pulledStrongly;
pulledStrongly2=table2.pulledStrongly;     
    diff_idx=find(pulledStrongly1~=pulledStrongly2);
    
    disp('pulledStrongly1/pulledStrongly2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)    

MultipleAttempts1=table1.MultipleAttempts;
MultipleAttempts2=table2.MultipleAttempts;     
    diff_idx=find(MultipleAttempts1~=MultipleAttempts2);
    
    disp('MultipleAttempts1/MultipleAttempts2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)    

Overshoot1=table1.Overshoot;
Overshoot2=table2.Overshoot;     
    diff_idx=find(Overshoot1~=Overshoot2);
    
    disp('Overshoot1/Overshoot2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)     
    
hand_after_trial1=table1.hand_after_trial;
hand_after_trial2=table2.hand_after_trial;     
    diff_idx=find(hand_after_trial1~=hand_after_trial2);
    
    disp('hand_after_tria1l/hand_after_trial2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)   
  
exp_hand_Screen1=table1.exp_hand_Screen;
exp_hand_Screen2=table2.exp_hand_Screen;     
    diff_idx=find(exp_hand_Screen1~=exp_hand_Screen2);
    
    disp('exp_hand_Screen1/exp_hand_Screen2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)    

