%load the behavior table from Behavior_Table.m

%plot success by condition
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
    xticklabels({'07.05.19','09.05.19','13.05.19','14.05.19','16.05.19','17.05.19','21.05.19','22.05.19',...
    '26.06.19','27.06.19','28.06.19','01.07.19','02.07.19','03.07.19','05.07.19','08.07.19','12.07.19','15.07.19',...
    '18.07.19','19.07.19','22.07.19','23.07.19','18.09.19','23.09.19','25.09.19','26.09.19','27.09.19','04.10.19',...
    '07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19'});
    xtickangle(45)

     xline(8.5,':',{'stage 2'});
     xline(22.5,':',{'stage 3'});

    legend('Success','Left','Center','Right')
    title([subject 'success by conditions']);

%plot the aligned l2r and r2l trials
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
    xticklabels({'07.05.19','09.05.19','13.05.19','14.05.19','16.05.19','17.05.19','21.05.19','22.05.19',...
    '26.06.19','27.06.19','28.06.19','01.07.19','02.07.19','03.07.19','05.07.19','08.07.19','12.07.19','15.07.19',...
    '18.07.19','19.07.19','22.07.19','23.07.19','18.09.19','23.09.19','25.09.19','26.09.19','27.09.19','04.10.19',...
    '07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19'});
    xtickangle(45)

    xline(8.5,':',{'stage 2'});
    xline(22.5,':',{'stage 3'});

    legend('Success','L2R','Aligned','R2L')
    title([subject 'success by direction']);

%plot multiple attempts success
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

    xticklabels({'07.05.19','09.05.19','13.05.19','14.05.19','16.05.19','17.05.19','21.05.19','22.05.19',...
    '26.06.19','27.06.19','28.06.19','01.07.19','02.07.19','03.07.19','05.07.19','08.07.19','12.07.19','15.07.19',...
    '18.07.19','19.07.19','22.07.19','23.07.19','18.09.19','23.09.19','25.09.19','26.09.19','27.09.19','04.10.19',...
    '07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19'});
    xtickangle(45)

   xline(8.5,':',{'stage 2'});
   xline(22.5,':',{'stage 3'});

    legend('Success','Multiple attempt nbr','Multiple attempt')
    title([subject 'Successful Multiple attempts']);    

%plot Overshoot success
    figure
    hold
    dates=Behavior.date;
    Succ=Behavior.Success;
    MA=Behavior.Overshoot_nbr;
    succMA=Behavior.SuccessOvershoot;


    plot([1:days_nbr],Succ,'k','LineWidth',1);
    plot([1:days_nbr],MA,'LineStyle','--','Color','r','Marker','o');
    plot([1:days_nbr],succMA,'LineStyle','--','Color','g','Marker','o');


    xlabel('days')
    xticks([1:days_nbr])
    ylabel('success(%)')
    ylim([0 100])

    xticklabels({'07.05.19','09.05.19','13.05.19','14.05.19','16.05.19','17.05.19','21.05.19','22.05.19',...
    '26.06.19','27.06.19','28.06.19','01.07.19','02.07.19','03.07.19','05.07.19','08.07.19','12.07.19','15.07.19',...
    '18.07.19','19.07.19','22.07.19','23.07.19','18.09.19','23.09.19','25.09.19','26.09.19','27.09.19','04.10.19',...
    '07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19','16.10.19','17.10.19','18.10.19'});
    xtickangle(45)

   xline(8.5,':',{'stage 2'});
   xline(22.5,':',{'stage 3'});

    legend('Success','Overshoot nbr','Overshoot')
    title([subject 'Successful Overshoots']);    

% %pie chartes
    % figure
    % %labels={'1/3','2/3','3/3'};
    % thirds_success=[mean(Behavior.DaySuccessSessionStart) mean(Behavior.DaySuccessSessionMiddle) mean(Behavior.DaySuccessSessionEnd)];
    % failures= 100 - sum(thirds_success);
    % thirds_session=[thirds_success failures];
    % pie(thirds_session)
    % legend('1/3','2/3','3/3','fail');
    % title([ subject 'success by sessions repartitions']);
