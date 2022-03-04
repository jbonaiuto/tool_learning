%load the behavior table from Behavior_Table.m
figure
hold
dates=Behavior.date;
Succ=Behavior.Success;
Left=Behavior.DaySuccessLeft;
Center=Behavior.DaySuccessCenter;
Right=Behavior.DaySuccessRight;

plot([1:days_nbr],Succ,'k','LineWidth',1);
plot([1:days_nbr],Left,'LineStyle','--','Color','r','Marker','o');
plot([1:days_nbr],Center,'LineStyle','--','Color','g','Marker','o');
plot([1:days_nbr],Right,'LineStyle','--','Color','b','Marker','o');

xlabel('days')
xticks([1:days_nbr])
ylabel('success(%)')
ylim([0 100])

% xticklabels({'07.05.19','09.05.19','14.05.19','22.05.19','01.07.19','02.07.19','03.07.19','05.07.19','08.07.19','12.07.19','15.07.19',...
%     '07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19',});
xticklabels({'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21','09.07.21','13.07.21','14.07.21','15.07.21',...
    '10.08.21','11.08.21','12.08.21','13.08.21','17.08.21','18.08.21','19.08.21','24.08.21','11.10.21','12.10.21','13.10.21',...
    '14.10.21','26.10.21','27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'});
xtickangle(45)

xline(11.5,':',{'stage 2'});
xline(19.5,':',{'stage 3'});

legend('Success','Left','Center','Right')
title([subject 'success part by condition']);

%plot the aligned l2r and r2l trials day succes
figure
hold
dates=Behavior.date;
Succ=Behavior.Success;
L2R=Behavior.DaySuccessL2R;
aligned=Behavior.DaySuccessAligned;
R2L=Behavior.DaySuccessR2L;

plot([1:days_nbr],Succ,'k','LineWidth',1);
plot([1:days_nbr],L2R,'LineStyle','--','Color','r','Marker','o');
plot([1:days_nbr],aligned,'LineStyle','--','Color','g','Marker','o');
plot([1:days_nbr],R2L,'LineStyle','--','Color','b','Marker','o');

xlabel('days')
xticks([1:days_nbr])
ylabel('success(%)')
ylim([0 100])

% xticklabels({'07.05.19','09.05.19','14.05.19','22.05.19','01.07.19','02.07.19','03.07.19','05.07.19','08.07.19','12.07.19','15.07.19',...
%     '07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19',});
xticklabels({'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21','09.07.21','13.07.21','14.07.21','15.07.21',...
    '10.08.21','11.08.21','12.08.21','13.08.21','17.08.21','18.08.21','19.08.21','24.08.21','11.10.21','12.10.21','13.10.21',...
    '14.10.21','26.10.21','27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'});
xtickangle(45)

xline(11.5,':',{'stage 2'});
xline(19.5,':',{'stage 3'});

legend('Success','L2R','Aligned','R2L')
title([subject 'success part by direction']);

%plot the aligned, l2r and r2l trials success
figure
hold
dates=Behavior.date;
Succ=Behavior.Success;
L2R=Behavior.SuccessL2R;
aligned=Behavior.SuccessAligned;
R2L=Behavior.SuccessR2L;

plot([1:days_nbr],Succ,'k','LineWidth',1);
plot([1:days_nbr],L2R,'LineStyle','--','Color','r','Marker','o');
plot([1:days_nbr],aligned,'LineStyle','--','Color','g','Marker','o');
plot([1:days_nbr],R2L,'LineStyle','--','Color','b','Marker','o');

xlabel('days')
xticks([1:days_nbr])
ylabel('success(%)')
ylim([0 100])

xticklabels({'11.06.21','15.06.21','16.06.21','17.06.21','18.06.21','22.06.21','23.06.21','09.07.21','13.07.21','14.07.21','15.07.21',...
    '10.08.21','11.08.21','12.08.21','13.08.21','17.08.21','18.08.21','19.08.21','24.08.21','11.10.21','12.10.21','13.10.21',...
    '14.10.21','26.10.21','27.10.21','28.10.21','29.10.21','02.11.21','03.11.21'});
xtickangle(45)

xline(11.5,':',{'stage 2'});
xline(19.5,':',{'stage 3'});

legend('Success','L2R','Aligned','R2L')
title([subject 'success by direction']);

%plot the aligned, l2r and r2l trials success
figure
hold
dates=Behavior.date;
Succ=Behavior.Success;
MA=Behavior.MultipleAttempt_nbr;
succMA=Behavior.SuccessMultipleAttempt;


plot([1:days_nbr],Succ,'k','LineWidth',1);
plot([1:days_nbr],MA,'LineStyle','--','Color','r','Marker','o');
plot([1:days_nbr],succMA,'LineStyle','--','Color','g','Marker','o');


xlabel('days')
xticks([1:days_nbr])
ylabel('success(%)')
ylim([0 100])

xticklabels({'22.06.21','23.06.21','09.07.21','13.07.21','14.07.21','15.07.21','10.08.21','11.08.21','13.08.21','17.08.21',...
    '18.08.21','19.08.21','24.08.21','11.10.21','12.10.21','13.10.21','14.10.21','26.10.21','27.10.21','28.10.21','29.10.21',...
    '02.11.21','03.11.21'});
xtickangle(45)

xline(6.5,':',{'stage 2'});
xline(12.5,':',{'stage 3'});

legend('Success','Multiple attempt nbr','Multiple attempt')
title([subject 'Successful Multiple attempts']);

% %pie chartes
% figure
% %labels={'1/3','2/3','3/3'};
% thirds_success=[mean(Behavior.DaySuccessSessionStart) mean(Behavior.DaySuccessSessionMiddle) mean(Behavior.DaySuccessSessionEnd)];
% failures= 100 - sum(thirds_success);
% thirds_session=[thirds_success failures];
% pie(thirds_session)
% legend('1/3','2/3','3/3','fail');
% title([ subject 'success by sessions repartitions']);
