%subject==betta


videocod_file1 = 'E:\project\video_coding\Betta\table\motor_rake_20191008_08-10-2019_SK.xlsx';
videocod_file2 = 'C:\Users\kirchher\Desktop\ISC_CNRS\Team_PPF\team\trainees\Noemie_M1_2022\motor_rake_20191008_08-10-2019_ND_testmatlab.xlsx';
table1 = readtable(videocod_file1);
table2 = readtable(videocod_file2);

%table1.withCube(isnan(table1.withCube))=9;

nan_idx=ismissing(table1(:,5:end-1));
table1{:,5:end-1}(nan_idx)=9;

nan_idx=ismissing(table2(:,5:end-1));
table2{:,5:end-1}(nan_idx)=9;

n_trial=height(table1);

cube1=table1.withCube;
cube2=table2.withCube;     
    diff_idx=find(cube1~=cube2);
    
    disp('cube1/cube2 differences lines:')
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
    
StereotypedPulling1=table1.StereotypedPulling;
StereotypedPulling2=table2.StereotypedPulling;     
    diff_idx=find(StereotypedPulling1~=StereotypedPulling2);
    
    disp('StereotypedPulling1/StereotypedPulling2 differences lines:')
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
    
expInterv1=table1.expInterv;
expInterv2=table2.expInterv;     
    diff_idx=find(expInterv1~=expInterv2);
    
    disp('expInterv1/expInterv2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)    

touchRakeHead1=table1.touchRakeHead;
touchRakeHead2=table2.touchRakeHead;     
    diff_idx=find(touchRakeHead1~=touchRakeHead2);
    
    disp('touchRakeHead1/touchRakeHead2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)      

pulledInSteps1=table1.pulledInSteps;
pulledInSteps2=table2.pulledInSteps;     
    diff_idx=find(pulledInSteps1~=pulledInSteps2);
    
    disp('pulledInSteps1/pulledInSteps2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)  
    
ShaftCorrection1=table1.ShaftCorrection;
ShaftCorrection2=table2.ShaftCorrection;     
    diff_idx=find(ShaftCorrection1~=ShaftCorrection2);
    
    disp('ShaftCorrection1/ShaftCorrection2 differences lines:')
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

rakeReleased1=table1.rakeReleased;
rakeReleased2=table2.rakeReleased;     
    diff_idx=find(rakeReleased1~=rakeReleased2);
    
    disp('rakeReleased1/rakeReleased2 differences lines:')
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
  
Screen1=table1.Screen;
Screen2=table2.Screen;     
    diff_idx=find(Screen1~=Screen2);
    
    disp('Screen1/Screen2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent)    

spasmHandle1=table1.spasmHandle;
spasmHandle2=table2.spasmHandle;     
    diff_idx=find(spasmHandle1~=spasmHandle2);
    
    disp('spasmHandle1/spasmHandle2 differences lines:')
    disp( diff_idx')
   
    n_error=length(diff_idx);
    diff_percent=(n_error*100)/n_trial;
    
    disp('error percentage:')
    disp(diff_percent) 
    
    
    
    
    
    % rakeStarting2=num2str(rakeStarting2);
%     rakeStarting2=cellstr(rakeStarting2);
% 
% for n=1:trial_nbr
%     rakeStarting2{n}=rakeStarting2{n}(rakeStarting2{n} ~= ' ');
% end
