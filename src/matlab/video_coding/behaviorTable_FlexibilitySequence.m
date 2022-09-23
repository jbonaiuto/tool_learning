%BehaviorTable_week__DirectionByCondition_betta

subject= 'Betta'; %'Samovar' 'Betta'

if strcmp(subject,'Betta')
    coder= 'ND'; % ND = Noémie Dessaint, SK = Sébastien Kirchherr, GC = Gino Coudé
    dates={'07.05.19','09.05.19','13.05.19','14.05.19','15.05.19','16.05.19','17.05.19','20.05.19','21.05.19','22.05.19','23.05.19','13.06.19','14.06.19',...
    '19.06.19','24.06.19','25.06.19','26.06.19','27.06.19','28.06.19','01.07.19','02.07.19','03.07.19','04.07.19','05.07.19','08.07.19','11.07.19','12.07.19',...
    '15.07.19','17.07.19','18.07.19','19.07.19','22.07.19','23.07.19','24.07.19','25.07.19','26.07.19','31.07.19','01.08.19','02.08.19','05.08.19','06.08.19','07.08.19',...
    '09.08.19','20.08.19','21.08.19','22.08.19','23.08.19','26.08.19','27.08.19','28.08.19','29.08.19','04.09.19','05.09.19','06.09.19','09.09.19','10.09.19','12.09.19',...
    '13.09.19','16.09.19','19.09.19','20.09.19','23.09.19','25.09.19','26.09.19','27.09.19','30.09.19','04.10.19','07.10.19','08.10.19','09.10.19','10.10.19','11.10.19',...
    '14.10.19','16.10.19','17.10.19','18.10.19'};
elseif strcmp(subject,'Samovar')
    coder= 'SK'; 
   dates={'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21',...
    '29.06.21','30.06.21','02.07.21','06.07.21','08.07.21','09.07.21','13.07.21','14.07.21',...
    '15.07.21','16.07.21','27.07.21','28.07.21','29.07.21','30.07.21','03.08.21','04.08.21',...
    '05.08.21','06.08.21','10.08.21','11.08.21','12.08.21','13.08.21','17.08.21','18.08.21',...
    '19.08.21','20.08.21','24.08.21','25.08.21','27.08.21','31.08.21','01.09.21','02.09.21',...
    '03.09.21','07.09.21','08.09.21','09.09.21','10.09.21','14.09.21','15.09.21','17.09.21',...
    '21.09.21','22.09.21','23.09.21','24.09.21','29.09.21','30.09.21','01.10.21','05.10.21',...
    '06.10.21','07.10.21','08.10.21','11.10.21','12.10.21','13.10.21','14.10.21','26.10.21',...
    '27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'};
end

days_nbr=length(dates);

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
        % -12 to have the week of recording not the week of the year
        WeekOfRec{3,d}=w-12;
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
        weeks=weeks-12; %to transform the weeks of the year into week of tool training recording
elseif strcmp(subject,'Samovar')
         weeks=weeks-21;
end

week_idx=unique(weeks);
w_nbr=length(week_idx);

for n=1:length(week_idx)
    label_idx{n}=num2str(week_idx(n));
end

output_path=fullfile('E:\project\video_coding\', subject,'table');

FlexSeq_week={};
for w=1:w_nbr
    FlexSeq_week{end+1}={};
end

% 12 level of heterrogeneity 
flexibilitySeq=zeros(12,w_nbr);
hit_flexibilitySeq=zeros(12,w_nbr);

flexibilityTrans=zeros(12,w_nbr);
hit_flexibilityTrans=zeros(12,w_nbr);

TransDiffSuccess_week=zeros(1,w_nbr);

for w=1:w_nbr
    WOI=week_idx(w);
    WeekDay_nbr=length(find(weeks==WOI));
    WeekDay_idx=find(weeks==WOI);
   
    FlexSeq_day={};
    for o=1:WeekDay_nbr
        FlexSeq_day{end+1}={};
    end
    
    for d=1:WeekDay_nbr
            DOI=dates{WeekDay_idx(d)};
            date_xls=replace(DOI,'.','-');
            date_xls=insertAfter(date_xls,6,'20');
            date_backward=[date_xls(end-3:end) date_xls(end-6:end-5) date_xls(end-9:end-8)];
            videocod_file=fullfile(output_path, ['motor_rake_' date_backward '_' date_xls '_' coder '.xlsx']);

            videotable=readtable(videocod_file);
            
            validTrials=find(videotable.ValidVideo==1);
            validTrials_nbr=length(validTrials);
            
            FlexSeq_trial=zeros(6,validTrials_nbr);
            
            for t=1:validTrials_nbr
                validTrial_idx=validTrials(t);
                
                DayTrial=videotable(validTrial_idx,:);
                
                %find the diffculty of the trial: diff 0(alligned)=1 diff1=2 etc
                    if ((strcmp(DayTrial.TargetStarting,'b')&(DayTrial.RakeStarting==15))|...
                                                (strcmp(DayTrial.TargetStarting,'c')&(DayTrial.RakeStarting==17))|...
                                                (strcmp(DayTrial.TargetStarting,'d')&(DayTrial.RakeStarting==19)))

                        FlexSeq_trial(1,t)=1;

                    elseif ((strcmp(DayTrial.TargetStarting,'b')&(DayTrial.RakeStarting==16|DayTrial.RakeStarting==14))|...
                                                    (strcmp(DayTrial.TargetStarting,'c')&(DayTrial.RakeStarting==18|DayTrial.RakeStarting==16))|...
                                                    (strcmp(DayTrial.TargetStarting,'d')&(DayTrial.RakeStarting==20|DayTrial.RakeStarting==18))) 

                        FlexSeq_trial(1,t)=2;

                    elseif ((strcmp(DayTrial.TargetStarting,'b')&(DayTrial.RakeStarting==17|DayTrial.RakeStarting==18|...
                                                DayTrial.RakeStarting==5|DayTrial.RakeStarting==6|DayTrial.RakeStarting==13|DayTrial.RakeStarting==2|DayTrial.RakeStarting==3))|...
                                                (strcmp(DayTrial.TargetStarting,'c')&(DayTrial.RakeStarting==19|DayTrial.RakeStarting==7|DayTrial.RakeStarting==8|...
                                                DayTrial.RakeStarting==15|DayTrial.RakeStarting==4|DayTrial.RakeStarting==5))|...    
                                                (strcmp(DayTrial.TargetStarting,'d')&(DayTrial.RakeStarting==21|DayTrial.RakeStarting==10|DayTrial.RakeStarting==9|...
                                                DayTrial.RakeStarting==17|DayTrial.RakeStarting==6|DayTrial.RakeStarting==7|DayTrial.RakeStarting==16)))

                       FlexSeq_trial(1,t)=3;

                    elseif ((strcmp(DayTrial.TargetStarting,'b')&(DayTrial.RakeStarting==19|DayTrial.RakeStarting==20|DayTrial.RakeStarting==21|...
                                                DayTrial.RakeStarting==22|DayTrial.RakeStarting==7|DayTrial.RakeStarting==8|DayTrial.RakeStarting==9|DayTrial.RakeStarting==10|...
                                                DayTrial.RakeStarting==11|DayTrial.RakeStarting==12|DayTrial.RakeStarting==1))|...
                                                (strcmp(DayTrial.TargetStarting,'c')&(DayTrial.RakeStarting==20|DayTrial.RakeStarting==21|DayTrial.RakeStarting==22|...
                                                DayTrial.RakeStarting==9|DayTrial.RakeStarting==10|DayTrial.RakeStarting==11|DayTrial.RakeStarting==14|DayTrial.RakeStarting==13|...
                                                DayTrial.RakeStarting==12|DayTrial.RakeStarting==1|DayTrial.RakeStarting==2|DayTrial.RakeStarting==3))|... 
                                                (strcmp(DayTrial.TargetStarting,'d')&(DayTrial.RakeStarting==22|DayTrial.RakeStarting==11|DayTrial.RakeStarting==15|...
                                                DayTrial.RakeStarting==14|DayTrial.RakeStarting==13|DayTrial.RakeStarting==12|DayTrial.RakeStarting==5|DayTrial.RakeStarting==4|...
                                                DayTrial.RakeStarting==3|DayTrial.RakeStarting==2|DayTrial.RakeStarting==1)))

                       FlexSeq_trial(1,t)=4;  
                    end
            
               %find the direction of the trial: alligned=1 L-R2L=2  L-L2R=3 R-R2L=4  R-L2R=5
                    if ((DayTrial.RakeStarting==15 & strcmp(DayTrial.TargetStarting,'b'))|...
                                    (DayTrial.RakeStarting==17 & strcmp(DayTrial.TargetStarting,'c'))|...
                                    (DayTrial.RakeStarting==19 & strcmp(DayTrial.TargetStarting,'d')))
                                
                       FlexSeq_trial(2,t)=1;
                    elseif ((strcmp(DayTrial.TargetStarting,'b')&(DayTrial.RakeStarting==16|DayTrial.RakeStarting==17|...
                                DayTrial.RakeStarting==18|DayTrial.RakeStarting==19|DayTrial.RakeStarting==20))|...
                                (strcmp(DayTrial.TargetStarting,'c')&(DayTrial.RakeStarting==18|DayTrial.RakeStarting==19|...
                                DayTrial.RakeStarting==20))|...
                                (strcmp(DayTrial.TargetStarting,'d')&(DayTrial.RakeStarting==20|DayTrial.RakeStarting==21)))
                            
                       FlexSeq_trial(2,t)=2;
                    elseif ((strcmp(DayTrial.TargetStarting,'b')&(DayTrial.RakeStarting==12|DayTrial.RakeStarting==13|...
                                DayTrial.RakeStarting==14))|...
                                (strcmp(DayTrial.TargetStarting,'c')&(DayTrial.RakeStarting==14|DayTrial.RakeStarting==15|...
                                 DayTrial.RakeStarting==16))|...
                                (strcmp(DayTrial.TargetStarting,'d')&(DayTrial.RakeStarting==14|DayTrial.RakeStarting==15|...
                                DayTrial.RakeStarting==16|DayTrial.RakeStarting==17|DayTrial.RakeStarting==18)))
                            
                       FlexSeq_trial(2,t)=3;
                    elseif ((strcmp(DayTrial.TargetStarting,'b')&(DayTrial.RakeStarting==21|...
                                DayTrial.RakeStarting==22|DayTrial.RakeStarting==5|DayTrial.RakeStarting==6|DayTrial.RakeStarting==7|...
                                DayTrial.RakeStarting==8|DayTrial.RakeStarting==9|DayTrial.RakeStarting==10|DayTrial.RakeStarting==11))|...
                                (strcmp(DayTrial.TargetStarting,'c')&(DayTrial.RakeStarting==21|DayTrial.RakeStarting==22|...
                                DayTrial.RakeStarting==7|DayTrial.RakeStarting==8|DayTrial.RakeStarting==9|DayTrial.RakeStarting==10|...
                                DayTrial.RakeStarting==11))|...
                                (strcmp(DayTrial.TargetStarting,'d')&(DayTrial.RakeStarting==22|DayTrial.RakeStarting==9|...
                                DayTrial.RakeStarting==10|DayTrial.RakeStarting==11)))
                            
                       FlexSeq_trial(2,t)=4;
                    elseif ((strcmp(DayTrial.TargetStarting,'b')&(DayTrial.RakeStarting==12|DayTrial.RakeStarting==1|...
                                DayTrial.RakeStarting==2|DayTrial.RakeStarting==3))|...
                                (strcmp(DayTrial.TargetStarting,'c')&(DayTrial.RakeStarting==12|DayTrial.RakeStarting==13|...
                                DayTrial.RakeStarting==1|DayTrial.RakeStarting==2|DayTrial.RakeStarting==3|DayTrial.RakeStarting==4|...
                                DayTrial.RakeStarting==5))|...
                                (strcmp(DayTrial.TargetStarting,'d')&(DayTrial.RakeStarting==12|DayTrial.RakeStarting==13|...
                                DayTrial.RakeStarting==1|DayTrial.RakeStarting==2|DayTrial.RakeStarting==3|...
                                DayTrial.RakeStarting==4|DayTrial.RakeStarting==5|DayTrial.RakeStarting==6|DayTrial.RakeStarting==7)))
                            
                       FlexSeq_trial(2,t)=5;
                    end
                 
                %find if the trial is a succes or not: success=1 not a success=0
                    if DayTrial.Success==1
                        FlexSeq_trial(3,t)=1;
                    elseif DayTrial.Success==0
                        FlexSeq_trial(3,t)=0;
                    end
                    
                %find the condition of the trial: left condition=1 center=2 right=3
                    if strcmp(DayTrial.TargetStarting,'b')
                        FlexSeq_trial(4,t)=1;
                    elseif strcmp(DayTrial.TargetStarting,'c')
                        FlexSeq_trial(4,t)=2;
                    elseif strcmp(DayTrial.TargetStarting,'d')
                        FlexSeq_trial(4,t)=3;
                    end                             
                 
                
            end
            FlexSeq_day{1,d}=FlexSeq_trial;
    end
    FlexSeq_week{1,w}=FlexSeq_day;
end

for w=1:w_nbr
    WOI=FlexSeq_week{1,w};
    
    FlexSeq_day_nbr=zeros(12,1);
    hit_FlexSeq_day_nbr=zeros(12,1);
    
    FlexTrans_day_nbr=zeros(12,1);
    hit_FlexTrans_day_nbr=zeros(12,1);
    
    TransDiffSuccess_day=0;
    
    for d=1:length(WOI)
        DOI=WOI{1,d};
        
        TransDiffSuccess_DOI=0;
        tds_idx=1;
        
        for t=2:length(DOI)
            %determine the transition trial hétérogéneity score 
            %transition L2R <-> R2L
            if  DOI(2,t-1)==DOI(2,t)  
                DOI(5,t)=DOI(5,t)+0;
            end
            
            if  DOI(1,t-1)==DOI(1,t)
                DOI(5,t)=DOI(5,t)+0;
            end
                
            if  DOI(4,t-1)==DOI(4,t)
                DOI(5,t)=DOI(5,t)+0;
            end
                
            if  DOI(4,t-1)==DOI(4,t)
                DOI(5,t)=DOI(5,t)+0;
            end
            
            if (DOI(2,t-1)==2 && DOI(2,t)==5) || (DOI(2,t-1)==2 && DOI(2,t)==3) | ...
                    (DOI(2,t-1)==4 && DOI(2,t)==5) || (DOI(2,t-1)==4 && DOI(2,t)==3)
                DOI(5,t)=DOI(5,t)+2;
            end    
            
            if (DOI(2,t-1)==2 && DOI(2,t)==4) || (DOI(2,t-1)==5 && DOI(2,t)==3) 
                DOI(5,t)=DOI(5,t)+1;
            end  
            
            if DOI(4,t-1)~= DOI(4,t)
                DOI(5,t)=DOI(5,t)+1;
            end  
            
            if abs(DOI(2,t-1)-DOI(2,t))==1 
                DOI(5,t)=DOI(5,t)+1;
            end 
            
            if abs(DOI(2,t-1)-DOI(2,t))==2 
                DOI(5,t)=DOI(5,t)+2;
            end 
            
            %index to calcul the length of successful trials different from
            %the previous one
            if (DOI(1,t-1)~= DOI(1,t) | DOI(2,t-1)~= DOI(2,t) | DOI(4,t-1)~= DOI(4,t)) & DOI(3,t)==1
                TransDiffSuccess_DOI(tds_idx)=TransDiffSuccess_DOI(tds_idx)+1;
            else
                tds_idx=tds_idx+1;
                TransDiffSuccess_DOI(tds_idx)=0;
            end
            
        end 
        
        for t=3:length(DOI)
            %determine the sequence heterogeneity score for each trail
            %based on the 2 trial before
            DOI(6,t)=DOI(5,t)+DOI(5,t-1)+DOI(5,t-2);   
        end 
        
        WOI{1,d}=DOI;
        
        for h=1:12
            FlexSeq_day_nbr(h,1)=FlexSeq_day_nbr(h,1) + length(find(DOI(6,:)==h-1));
            hit_FlexSeq_day_nbr(h,1)=hit_FlexSeq_day_nbr(h,1) + length(find((DOI(6,:)==h-1) & DOI(3,:)==1));
            
            FlexTrans_day_nbr(h,1)=FlexTrans_day_nbr(h,1) + length(find(DOI(5,:)==h-1));
            hit_FlexTrans_day_nbr(h,1)=hit_FlexTrans_day_nbr(h,1) + length(find((DOI(5,:)==h-1) & DOI(3,:)==1));
             
        end
        mean_TransDiffSuccess_DOI=mean(TransDiffSuccess_DOI(find(TransDiffSuccess_DOI)));
        TransDiffSuccess_day = mean(TransDiffSuccess_day + mean_TransDiffSuccess_DOI);  %using nanmean (not recommended)
    end
   FlexSeq_week{1,w}=WOI;
   
   for h=1:12
        flexibilitySeq(h,w)=flexibilitySeq(h,w) + FlexSeq_day_nbr(h,1);
        hit_flexibilitySeq(h,w)=hit_flexibilitySeq(h,w) + hit_FlexSeq_day_nbr(h,1);
        hit_flexibilitySeq_rate(h,w)=(hit_FlexSeq_day_nbr(h,1)/FlexSeq_day_nbr(h,1))*100;
        
        flexibilityTrans(h,w)=flexibilityTrans(h,w) + FlexTrans_day_nbr(h,1);
        hit_flexibilityTrans(h,w)=hit_flexibilitySeq(h,w) + hit_FlexTrans_day_nbr(h,1);
        hit_flexibilityTrans_rate(h,w)=(hit_FlexTrans_day_nbr(h,1)/FlexTrans_day_nbr(h,1))*100;
   end
    
   TransDiffSuccess_week(1,w)=TransDiffSuccess_week(1,w)+TransDiffSuccess_day;
end


for h=1:10

hete_label=num2str(h);
f=figure;
hold
%plot(flexibilitySeq(h,:),'k-','LineWidth',1.5)
%plot(hit_flexibilitySeq(h,:),'k--','LineWidth',1.5)
plot(hit_flexibilitySeq_rate(h,:),'k-','LineWidth',1.5)

ylim([0 100])
xlim([1 w_nbr])
xticks([1 : w_nbr])
xticklabels(label_idx)
xtickangle(-90)
title([ subject ' ' 'performance on trial with heterogeneity sequence level' ' ' hete_label]);

saveas(f,fullfile('C:\Users\kirchher\project\tool_learning\output\figures\behavior', [subject '_' 'PerfTrialWithSeqHeteroLevel' '_' hete_label '.png']))
end

for h=1:6

hete_label=num2str(h);
f=figure;
hold
%plot(flexibilityTrans(h,:),'k-','LineWidth',1.5)
%plot(hit_flexibilityTrans(h,:),'k--','LineWidth',1.5)
plot(hit_flexibilityTrans_rate(h,:),'b-','LineWidth',1.5)

ylim([0 100])
xlim([1 w_nbr])
xticks([1 : w_nbr])
xticklabels(label_idx)
xtickangle(-90)
title([ subject ' ' 'performance on trial with transition heterogeneity level' ' ' hete_label]);

saveas(f,fullfile('C:\Users\kirchher\project\tool_learning\output\figures\behavior', [subject '_' 'PerfTrialWithTransHeteroLevel' '_' hete_label '.png']))
end

f=figure; 
plot(TransDiffSuccess_week,'g-','LineWidth',1.5)
ylim([0 20])
xlim([1 w_nbr])
xticks([1 : w_nbr])
xticklabels(label_idx)
xtickangle(-90)
title([ subject ' ' 'mean successuful sequence of heterogeneous trials']);

saveas(f,fullfile('C:\Users\kirchher\project\tool_learning\output\figures\behavior', [subject '_' 'MeanSuccessSeqHeteroTrials' '.png']))