function plot_visual_pliers_movement_times(exp_info, subjects)

conditions={'visual_pliers_left','visual_pliers_right'};

start_date=datenum('26.02.19','dd.mm.YY');
end_date=datenum(now());

subj_rts={};
subj_tts={};
subj_mts={};
subj_pts={};


for s_idx=1:length(subjects)
    subject=subjects{s_idx};

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
    all_tts=[];
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
            % Figure out TT of each trial
            tts=data.metadata.tool_mvmt_onset(condition_trials)-data.metadata.hand_mvmt_onset(condition_trials);
            % Figure out MT of each trial
            mts=data.metadata.obj_contact(condition_trials)-data.metadata.tool_mvmt_onset(condition_trials);
            % Figure out PT of each trial
            pts=data.metadata.place(condition_trials)-data.metadata.obj_contact(condition_trials);

            all_rts(end+1:end+length(rts))=rts;
            all_tts(end+1:end+length(tts))=tts;
            all_mts(end+1:end+length(mts))=mts;
            all_pts(end+1:end+length(pts))=pts;
        end
    end
    subj_rts{s_idx}=all_rts;
    subj_tts{s_idx}=all_tts;
    subj_mts{s_idx}=all_mts;
    subj_pts{s_idx}=all_pts;
end


figure();

subplot(4,1,1);
max_rt=max(cat(2,subj_rts{:}));
rt_bins=linspace(0,max_rt,100);
rt_bin_w=rt_bins(2)-rt_bins(1);
hold all
for i=1:length(subjects)
    all_rts=subj_rts{i};
    [n,bins]=histc(all_rts,rt_bins);
    bin_centers=rt_bins+(rt_bin_w/2);
    h=bar(bin_centers,n);
    set(h,'FaceAlpha',.5);
end
xlim([0 max_rt]);
legend(subjects,'AutoUpdate','off');
plot([100 100],ylim(),'r--');
plot([1500 1500],ylim(),'r--');
xlabel('RT');
title('Visual pliers');

subplot(4,1,2);
max_tt=max(cat(2,subj_tts{:}));
tt_bins=linspace(0,max_tt,100);
tt_bin_w=tt_bins(2)-tt_bins(1);
hold all
for i=1:length(subjects)
    all_tts=subj_tts{i};
    [n,bins]=histc(all_tts,tt_bins);
    bin_centers=tt_bins+(tt_bin_w/2);
    h=bar(bin_centers,n);
    set(h,'FaceAlpha',.5);
end
xlim([0 max_tt]);
plot([400 400],ylim(),'r--');
plot([1200 1200],ylim(),'r--');
xlabel('Tool grasp');


subplot(4,1,3);
max_mt=max(cat(2,subj_mts{:}));
mt_bins=linspace(0,max_mt,100);
mt_bin_w=mt_bins(2)-mt_bins(1);
hold all
for i=1:length(subjects)
    all_mts=subj_mts{i};
    [n,bins]=histc(all_mts,mt_bins);
    bin_centers=mt_bins+(mt_bin_w/2);
    h=bar(bin_centers,n);
    set(h,'FaceAlpha',.5);
end
xlim([0 max_mt]);
plot([100 100],ylim(),'r--');
plot([1200 1200],ylim(),'r--');
xlabel('Movement onset to object contact');


subplot(4,1,4);
max_pt=max(cat(2,subj_pts{:}));
pt_bins=linspace(0,max_pt,100);
pt_bin_w=pt_bins(2)-pt_bins(1);
hold all
for i=1:length(subjects)
    all_pts=subj_pts{i};
    [n,bins]=histc(all_pts,pt_bins);
    bin_centers=pt_bins+(pt_bin_w/2);
    h=bar(bin_centers,n);
    set(h,'FaceAlpha',.5);
end
xlim([0 max_pt]);
plot([100 100],ylim(),'r--');
plot([1200 1200],ylim(),'r--');
xlabel('Place');

