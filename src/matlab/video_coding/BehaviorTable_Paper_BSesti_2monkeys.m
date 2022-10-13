%BehaviorTable_week_DirectionByCondition_Samovar
addpath('../..');

exp_info=init_exp_info();

colors=cbrewer2('qual','Dark2',7);
MoreColors=cbrewer2('qual','Set2',6);

ite_nbr=100; %number of iteration of the bootstraping estimation

subject= 'Betta'; % monkey1='Betta', monkey2='Samovar'

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

for w=1:w_nbr
    WOI=week_idx(w);
    
    w_TrialSuccess=0;
    
    w_A_success=0;
    w_L_Left_success=0;
    w_L_Right_success=0;
    w_F_Left_success=0;
    w_F_Right_success=0;
    
    w_dist0_success=0;
    w_dist1_success=0;
    w_dist2_success=0;
    w_dist3_success=0;

    for d=1:length(dates)
        if weeks(d)==WOI
            DOI=dates(d);
            date_xls=replace(dates{d},'.','-');
            date_xls=insertAfter(date_xls,6,'20');
            date_backward=[date_xls(end-3:end) date_xls(end-6:end-5) date_xls(end-9:end-8)];
            videocod_file=fullfile(output_path, ['motor_rake_' date_backward '_' date_xls '_' coder '.xlsx']);

            videotable=readtable(videocod_file);

           %% overall success
           vt_success_Nan=isnan(videotable.Success);
           vt_success_NoNan=videotable.Success(~vt_success_Nan);

           if w_TrialSuccess==0
               w_TrialSuccess=vt_success_NoNan';
           else
               w_TrialSuccess=cat(2,w_TrialSuccess,vt_success_NoNan');
           end
           w_succ_concat{1,w}=w_TrialSuccess;
           
           %% directions 
           %aligned trial - A
           A_idx=find((videotable.RakeStarting==15 & strcmp(videotable.TargetStarting,'b'))|...
                        (videotable.RakeStarting==17 & strcmp(videotable.TargetStarting,'c'))|...
                        (videotable.RakeStarting==19 & strcmp(videotable.TargetStarting,'d')));
           
           A_success=videotable.Success(A_idx);
           
           if w_A_success==0
               w_A_success=A_success';
           else
               w_A_success=cat(2,w_A_success,A_success');
           end
           w_dir_concat{1,w}=w_A_success;
           
           %lateral trial - L: right to left movement
           L_Right2Left=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==16|videotable.RakeStarting==17|...
                    videotable.RakeStarting==18|videotable.RakeStarting==19|videotable.RakeStarting==20))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==18|videotable.RakeStarting==19|...
                    videotable.RakeStarting==20))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==20|videotable.RakeStarting==21)));
                
           L_Left_success=videotable.Success(L_Right2Left);
           
           if w_L_Left_success==0
               w_L_Left_success=L_Left_success';
           else
               w_L_Left_success=cat(2,w_L_Left_success,L_Left_success');
           end
           w_dir_concat{2,w}=w_L_Left_success;
           
           %lateral trial - L: left to right movement
           L_Left2Right=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                    videotable.RakeStarting==14))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==14|videotable.RakeStarting==15|...
                     videotable.RakeStarting==16))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==14|videotable.RakeStarting==15|...
                    videotable.RakeStarting==16|videotable.RakeStarting==17|videotable.RakeStarting==18)));
           
           L_Right_success=videotable.Success(L_Left2Right);
           
           if w_L_Right_success==0
               w_L_Right_success=L_Right_success';
           else
               w_L_Right_success=cat(2,w_L_Right_success,L_Right_success');
           end
           w_dir_concat{3,w}=w_L_Right_success;
           
           %forward trial - F: forward right to left movement
           F_Right2Left=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==21|...
                    videotable.RakeStarting==22|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7|...
                    videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==21|videotable.RakeStarting==22|...
                    videotable.RakeStarting==7|videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|...
                    videotable.RakeStarting==11))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==22|videotable.RakeStarting==9|...
                    videotable.RakeStarting==10|videotable.RakeStarting==11)));
           
           F_Left_success=videotable.Success(F_Right2Left);
           
           if w_F_Left_success==0
               w_F_Left_success=F_Left_success';
           else
               w_F_Left_success=cat(2,w_F_Left_success,F_Left_success');
           end
           w_dir_concat{4,w}=w_F_Left_success;
           
           %reach trial - R: forward, left to right movement
            F_Left2Right=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==12|videotable.RakeStarting==1|...
                    videotable.RakeStarting==2|videotable.RakeStarting==3))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                    videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|videotable.RakeStarting==4|...
                    videotable.RakeStarting==5))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==12|videotable.RakeStarting==13|...
                    videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3|...
                    videotable.RakeStarting==4|videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==7)));
             
            F_Right_success=videotable.Success(F_Left2Right);
           
            if w_F_Right_success==0
                w_F_Right_success=F_Right_success';
            else
                w_F_Right_success=cat(2,w_F_Right_success,F_Right_success');
            end
            w_dir_concat{5,w}=w_F_Right_success;
            
        %% rake-target distance
            %rake-target distance level 0
            dist_0=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==15))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==17))|...
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==19)));
            
            dist0_success=videotable.Success(dist_0);
           
            if w_dist0_success==0
                w_dist0_success=dist0_success';
            else
                w_dist0_success=cat(2,w_dist0_success,dist0_success');
            end
            w_dist_concat{1,w}=w_dist0_success;
            
            % distance 1    
            dist_1=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==16|videotable.RakeStarting==14))|...
                        (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==18|videotable.RakeStarting==16))|...
                        (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==20|videotable.RakeStarting==18)));
            
            dist1_success=videotable.Success(dist_1);
           
            if w_dist1_success==0
                w_dist1_success=dist1_success';
            else
                w_dist1_success=cat(2,w_dist1_success,dist1_success');
            end
            w_dist_concat{2,w}=w_dist1_success;
            
            % distance 2        
            dist_2=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==17|videotable.RakeStarting==18|...
                    videotable.RakeStarting==5|videotable.RakeStarting==6|videotable.RakeStarting==13|videotable.RakeStarting==2|videotable.RakeStarting==3))|...
                    (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==19|videotable.RakeStarting==7|videotable.RakeStarting==8|...
                    videotable.RakeStarting==15|videotable.RakeStarting==4|videotable.RakeStarting==5))|...    
                    (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==21|videotable.RakeStarting==10|videotable.RakeStarting==9|...
                    videotable.RakeStarting==17|videotable.RakeStarting==6|videotable.RakeStarting==7|videotable.RakeStarting==16)));
            
            dist2_success=videotable.Success(dist_2);
           
            if w_dist2_success==0
                w_dist2_success=dist2_success';
            else
                w_dist2_success=cat(2,w_dist2_success,dist2_success');
            end
            w_dist_concat{3,w}=w_dist2_success;
                
            % distance 3    
            dist_3=((strcmp(videotable.TargetStarting,'b')&(videotable.RakeStarting==19|videotable.RakeStarting==20|videotable.RakeStarting==21|...
                   videotable.RakeStarting==22|videotable.RakeStarting==7|videotable.RakeStarting==8|videotable.RakeStarting==9|videotable.RakeStarting==10|...
                   videotable.RakeStarting==11|videotable.RakeStarting==12|videotable.RakeStarting==1))|...
                   (strcmp(videotable.TargetStarting,'c')&(videotable.RakeStarting==20|videotable.RakeStarting==21|videotable.RakeStarting==22|...
                   videotable.RakeStarting==9|videotable.RakeStarting==10|videotable.RakeStarting==11|videotable.RakeStarting==14|videotable.RakeStarting==13|...
                   videotable.RakeStarting==12|videotable.RakeStarting==1|videotable.RakeStarting==2|videotable.RakeStarting==3))|... 
                   (strcmp(videotable.TargetStarting,'d')&(videotable.RakeStarting==22|videotable.RakeStarting==11|videotable.RakeStarting==15|...
                   videotable.RakeStarting==14|videotable.RakeStarting==13|videotable.RakeStarting==12|videotable.RakeStarting==5|videotable.RakeStarting==4|...
                   videotable.RakeStarting==3|videotable.RakeStarting==2|videotable.RakeStarting==1)));
  
            dist3_success=videotable.Success(dist_3);
           
            if w_dist3_success==0
                w_dist3_success=dist3_success';
            else
                w_dist3_success=cat(2,w_dist3_success,dist3_success');
            end
            w_dist_concat{4,w}=w_dist3_success;
            
        else
            continue
        end
    end              
end


%% overall success

for w=1:w_nbr
    WOI=cell2mat(w_succ_concat(w));
    if isempty(WOI)
       w_succ(1:ite_nbr,w)=NaN;
       continue
    else    
        for r=1:ite_nbr
            FiftyRnd=randi([1 (length(WOI))],1,ceil(length(WOI)/2));
            rnd_succ_idx=WOI(FiftyRnd);
            rnd_succ_nbr=length(find(rnd_succ_idx));
            rnd_succ_rate=(rnd_succ_nbr/ceil(length(WOI)/2))*100;

            w_succ(r,w)=rnd_succ_rate;
        end 
    end
end

%plot estimation mean and SD 
f=figure;
hold

H=shadedErrorBar([],nanmean(w_succ,1),nanstd(w_succ,1)); %use nanmean and nanstd (not recommended)

%xlabel('week')
%ylabel('success %')
xlim([0 w_nbr])
ylim([0 100])
xticks([1:w_nbr])
xticklabels(week_idx);

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'overall_success' '_' 'BS_meanSD' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'overall_success' '_' 'BS_meanSD' '.eps']),'epsc');

% 1st derivative
FirstDerivative=diff(mean(w_succ,1));
mean_der=nanmean(FirstDerivative); %use nanmean (not recommended)
SD_der=nanstd(FirstDerivative); %use nanstd (not recommended)

f=figure;
hold

plot(FirstDerivative,'b-','LineWidth',2); 

yline(mean_der,'k--','LineWidth',2)
yline((mean_der - SD_der),'k--','LineWidth',1)
yline((mean_der + SD_der),'k--','LineWidth',1)

%xlabel('week')
xlim([0 w_nbr])
xticks([1:w_nbr-1])
xticklabels(week_idx(2:end));
legend('1st derivative')

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'overall_success' '_' 'BS_FirstDerivatives' '.png']));

% 2nd derivative
scndDerivative=diff(diff(mean(w_succ,1)));
mean_derder=nanmean(scndDerivative);
SD_derder=nanstd(scndDerivative);

f=figure;
hold

plot(scndDerivative,'r-','LineWidth',2); 

yline(mean_derder,'k--','LineWidth',2)
yline((mean_derder - SD_derder),'k--','LineWidth',1)
yline((mean_derder + SD_derder),'k--','LineWidth',1)

%xlabel('week')
xlim([0 w_nbr])
xticks([1:w_nbr-2])
xticklabels(week_idx(3:end));
legend('2nd derivative')

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'overall_success' '_' 'BS_SecondDerivative' '.png'])); 


%% direction
behav_var_names={'aligned' 'L_Right2Left' 'L_Left2Right' 'F_Right2Left' 'F_Leftt2Right'};

for d=1:5
    for w=1:w_nbr
        WOI=cell2mat(w_dir_concat(d,w));
        if isempty(WOI)
           w_dir(1:ite_nbr,w,d)=NaN;
           continue
        else    
            for r=1:ite_nbr
                FiftyRnd=randi([1 (length(WOI))],1,ceil(length(WOI)/2));
                rnd_succ_idx=WOI(FiftyRnd);
                rnd_succ_nbr=length(find(rnd_succ_idx));
                rnd_succ_rate=(rnd_succ_nbr/ceil(length(WOI)/2))*100;

                w_dir(r,w,d)=rnd_succ_rate;
            end 
        end
    end
end

%plot estimation mean and SD 
f=figure;
hold

H=shadedErrorBar([],nanmean(w_dir(:,:,1),1),nanstd(w_dir(:,:,1),1),'lineProps',{'Color',[0 0.5 1]}); %use nanmean and nanstd (not recommended)
H=shadedErrorBar([],nanmean(w_dir(:,:,2),1),nanstd(w_dir(:,:,2),1),'lineProps',{'Color',colors(1,:)});
H=shadedErrorBar([],nanmean(w_dir(:,:,3),1),nanstd(w_dir(:,:,3),1),'lineProps',{'Color',colors(2,:)});
H=shadedErrorBar([],nanmean(w_dir(:,:,4),1),nanstd(w_dir(:,:,4),1),'lineProps',{'Color',colors(3,:)});
H=shadedErrorBar([],nanmean(w_dir(:,:,5),1),nanstd(w_dir(:,:,5),1),'lineProps',{'Color',colors(4,:)});

%xlabel('week')
%ylabel('success %')
xlim([0 w_nbr])
ylim([0 100])
xticks([1:w_nbr])
xticklabels(week_idx);

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'directions' '_' 'BS_meanSD' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'directions' '_' 'BS_meanSD' '.eps']),'epsc');

for d=1:5
    behav_var_name=behav_var_names{d};

    % 1st derivative
    FirstDerivative=diff(mean(w_dir(:,:,d),1));
    mean_der=nanmean(FirstDerivative); %use nanmean (not recommended)
    SD_der=nanstd(FirstDerivative); %use nanstd (not recommended)

    f=figure;
    hold
    plot(FirstDerivative,'b-','LineWidth',2); 

    yline(mean_der,'k--','LineWidth',2)
    yline((mean_der - SD_der),'k--','LineWidth',1)
    yline((mean_der + SD_der),'k--','LineWidth',1)

    %xlabel('week')
    xlim([0 w_nbr])
    xticks([1:w_nbr-1])
    xticklabels(week_idx(2:end));
    legend('1st derivative')

    saveas(f,fullfile(output_path_fig,...
         [subject '_' behav_var_name '_' 'BS_FirstDerivatives' '.png']));

    % 2nd derivative
    scndDerivative=diff(diff(mean(w_dir(:,:,d),1)));
    mean_derder=nanmean(scndDerivative);
    SD_derder=nanstd(scndDerivative);

    f=figure;
    hold
    plot(scndDerivative,'r-','LineWidth',2); 

    yline(mean_derder,'k--','LineWidth',2)
    yline((mean_derder - SD_derder),'k--','LineWidth',1)
    yline((mean_derder + SD_derder),'k--','LineWidth',1)

    %xlabel('week')
    xlim([0 w_nbr])
    xticks([1:w_nbr-2])
    xticklabels(week_idx(3:end));
    legend('2nd derivative')

    saveas(f,fullfile(output_path_fig,...
         [subject '_' behav_var_name '_' 'BS_SecondDerivative' '.png'])); 
end

%% rake-target distance
behav_var_names={'distance0' 'distance1' 'distance2' 'distance3'};

for d=1:4
    for w=1:w_nbr
        WOI=cell2mat(w_dist_concat(d,w));
        if isempty(WOI)
           w_dist(1:ite_nbr,w,d)=NaN;
           continue
        else    
            for r=1:ite_nbr
                FiftyRnd=randi([1 (length(WOI))],1,ceil(length(WOI)/2));
                rnd_succ_idx=WOI(FiftyRnd);
                rnd_succ_nbr=length(find(rnd_succ_idx));
                rnd_succ_rate=(rnd_succ_nbr/ceil(length(WOI)/2))*100;

                w_dist(r,w,d)=rnd_succ_rate;
            end 
        end
    end
end

%plot estimation mean and SD 
f=figure;
hold

H=shadedErrorBar([],nanmean(w_dist(:,:,1),1),nanstd(w_dist(:,:,1),1),'lineProps',{'Color',[0 0.5 1]}); %use nanmean and nanstd (not recommended)
H=shadedErrorBar([],nanmean(w_dist(:,:,2),1),nanstd(w_dist(:,:,2),1),'lineProps',{'Color',colors(5,:)});
H=shadedErrorBar([],nanmean(w_dist(:,:,3),1),nanstd(w_dist(:,:,3),1),'lineProps',{'Color',colors(6,:)});
H=shadedErrorBar([],nanmean(w_dist(:,:,4),1),nanstd(w_dist(:,:,4),1),'lineProps',{'Color',colors(7,:)});

%xlabel('week')
%ylabel('success %')
xlim([0 w_nbr])
ylim([0 100])
xticks([1:w_nbr])
xticklabels(week_idx);

saveas(f,fullfile(output_path_fig,...
     [subject '_' 'distances' '_' 'BS_meanSD' '.png']));
saveas(f,fullfile(output_path_fig,...
     [subject '_' 'distances' '_' 'BS_meanSD' '.eps']),'epsc');

for d=1:4
    behav_var_name=behav_var_names{d};

    % 1st derivative
    FirstDerivative=diff(mean(w_dist(:,:,d),1));
    mean_der=nanmean(FirstDerivative); %use nanmean (not recommended)
    SD_der=nanstd(FirstDerivative); %use nanstd (not recommended)

    f=figure;
    hold
    plot(FirstDerivative,'b-','LineWidth',2); 

    yline(mean_der,'k--','LineWidth',2)
    yline((mean_der - SD_der),'k--','LineWidth',1)
    yline((mean_der + SD_der),'k--','LineWidth',1)

    %xlabel('week')
    xlim([0 w_nbr])
    xticks([1:w_nbr-1])
    xticklabels(week_idx(2:end));
    legend('1st derivative')

    saveas(f,fullfile(output_path_fig,...
         [subject '_' behav_var_name '_' 'BS_FirstDerivatives' '.png']));

    % 2nd derivative
    scndDerivative=diff(diff(mean(w_dist(:,:,d),1)));
    mean_derder=nanmean(scndDerivative);
    SD_derder=nanstd(scndDerivative);

    f=figure;
    hold
    plot(scndDerivative,'r-','LineWidth',2); 

    yline(mean_derder,'k--','LineWidth',2)
    yline((mean_derder - SD_derder),'k--','LineWidth',1)
    yline((mean_derder + SD_derder),'k--','LineWidth',1)

    %xlabel('week')
    xlim([0 w_nbr])
    xticks([1:w_nbr-2])
    xticklabels(week_idx(3:end));
    legend('2nd derivative')

    saveas(f,fullfile(output_path_fig,...
         [subject '_' behav_var_name '_' 'BS_SecondDerivative' '.png'])); 
end







%  %plot estimation mean and SD with subplot
% f=figure;
% hold
% 
% subplot(5,1,1)
% H=shadedErrorBar([],nanmean(w_behav_var(:,:,1),1),nanstd(w_behav_var(:,:,1),1),'lineProps',{'Color',[0 0.5 1]}); %use nanmean and nanstd (not recommended)
% xlim([0 w_nbr])
% ylim([0 100])
% xticks([1:w_nbr])
% xticklabels(week_idx);
% 
% subplot(5,1,2)
% H=shadedErrorBar([],nanmean(w_behav_var(:,:,2),1),nanstd(w_behav_var(:,:,2),1),'lineProps',{'Color',colors(1,:)});
% xlim([0 w_nbr])
% ylim([0 100])
% xticks([1:w_nbr])
% xticklabels(week_idx);
% 
% subplot(5,1,3)
% H=shadedErrorBar([],nanmean(w_behav_var(:,:,3),1),nanstd(w_behav_var(:,:,3),1),'lineProps',{'Color',colors(2,:)});
% xlim([0 w_nbr])
% ylim([0 100])
% xticks([1:w_nbr])
% xticklabels(week_idx);
% 
% subplot(5,1,4)
% H=shadedErrorBar([],nanmean(w_behav_var(:,:,4),1),nanstd(w_behav_var(:,:,4),1),'lineProps',{'Color',colors(3,:)});
% xlim([0 w_nbr])
% ylim([0 100])
% xticks([1:w_nbr])
% xticklabels(week_idx);
% 
% subplot(5,1,5)
% H=shadedErrorBar([],nanmean(w_behav_var(:,:,5),1),nanstd(w_behav_var(:,:,5),1),'lineProps',{'Color',colors(4,:)});
% xlim([0 w_nbr])
% ylim([0 100])
% xticks([1:w_nbr])
% xticklabels(week_idx);
% 
% saveas(f,fullfile(output_path_fig,...
%      [subject '_' 'directions' '_' 'BS_meanSD_subplot' '.png']));
% saveas(f,fullfile(output_path_fig,...
%      [subject '_' 'directions' '_' 'BS_meanSD_subplot' '.eps']),'epsc');