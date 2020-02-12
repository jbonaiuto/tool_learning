function plot_rts(data)

conditions=unique(data.conditions);

cond_color=cbrewer('qual','Paired',length(conditions));
bins=[0:30:3000];
figure();
hold all
for cond_idx=1:length(conditions)
    condition=conditions{cond_idx};
    condition_trials=unique(data.trials(find(strcmp(data.conditions,condition))));
    cnt=histc(data.metadata.hand_mvmt_onset(condition_trials)-data.metadata.go(condition_trials),bins);
    bar(bins,cnt,'FaceColor',cond_color(cond_idx,:));
end
legend(conditions);