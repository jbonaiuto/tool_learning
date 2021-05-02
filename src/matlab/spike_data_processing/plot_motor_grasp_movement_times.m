function plot_motor_grasp_movement_times(exp_info, subject)

CIFcn = @(x,p)prctile(x,abs([0,100]-(100-p)/2));

conditions={'motor_grasp_left','motor_grasp_center','motor_grasp_right'};

start_date=datenum('26.02.19','dd.mm.YY');
%end_date=datenum('01.05.19','dd.mm.YY');
end_date=datenum(now());

% Read all directories in preprocessed data directory
data_dir=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject);
d=dir(fullfile(data_dir, '*.*.*'));
d=d(2:end);
% Sort by date
d_datetimes=[];
d_names={};
for d_idx=1:length(d)
    dn=datenum(d(d_idx).name,'dd.mm.YY');
    if dn>=start_date && dn<=end_date
      d_datetimes(end+1)=dn;
      d_names{end+1}=d(d_idx).name;
    end
end
[~,sorted_idx]=sort(d_datetimes);
dates=d_names(sorted_idx);

all_rts=[];
all_mts=[];
all_pts=[];

for i = 1:length(dates)
    dateexp=dates{i}
    if exist(fullfile(data_dir, dateexp, 'multiunit/binned'),'dir')==7
      load(fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dateexp,'multiunit','binned',...
        sprintf('fr_b_F1_%s_whole_trial.mat', dateexp)));
      condition_trials=zeros(1,length(data.metadata.condition));
      for i=1:length(conditions)
          condition_trials = condition_trials | (strcmp(data.metadata.condition,conditions{i}));
      end
      condition_trials=find(condition_trials);
      % Figure out RT of each trial
      rts=data.metadata.hand_mvmt_onset(condition_trials)-data.metadata.go(condition_trials);
      % Figure out MT of each trial
      mts=data.metadata.obj_contact(condition_trials)-data.metadata.hand_mvmt_onset(condition_trials);
      % Figure out PT of each trial
      pts=data.metadata.place(condition_trials)-data.metadata.obj_contact(condition_trials);

      all_rts(end+1:end+length(rts))=rts;
      all_mts(end+1:end+length(mts))=mts;
      all_pts(end+1:end+length(pts))=pts;
    end
end

med_rt=median(all_rts)
ci_rt=CIFcn(all_rts,95)
med_mt=median(all_mts)
ci_mt=CIFcn(all_mts,95)
med_pt=median(all_pts)
ci_pt=CIFcn(all_pts,95)

figure();
subplot(3,1,1);
hist(all_rts,100);
hold all;
plot([med_rt med_rt],ylim(),'k--');
plot([ci_rt(1) ci_rt(1)],ylim(),'r--');
plot([ci_rt(2) ci_rt(2)],ylim(),'r--');
xlabel('RT');
title('Motor grasp');
subplot(3,1,2);
hist(all_mts,100);
hold all;
plot([med_mt med_mt],ylim(),'k--');
plot([ci_mt(1) ci_mt(1)],ylim(),'r--');
plot([ci_mt(2) ci_mt(2)],ylim(),'r--');
xlabel('Movement onset to object contact');
subplot(3,1,3);
hist(all_pts,100);
hold all;
plot([med_pt med_pt],ylim(),'k--');
plot([ci_pt(1) ci_pt(1)],ylim(),'r--');
plot([ci_pt(2) ci_pt(2)],ylim(),'r--');
xlabel('Place');