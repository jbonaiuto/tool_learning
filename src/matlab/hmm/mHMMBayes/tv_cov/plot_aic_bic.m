function plot_aic_bic(output_path)

df=readtable(fullfile(output_path,'plnorm_aic_bic.csv'));

max_aic=max(df.aic);
df.aic=df.aic-max_aic;

max_bic=max(df.bic);
df.bic=df.bic-max_bic;

figure();
bar([df.aic df.bic]);
set(gca,'xticklabel',[3:8]);
legend({'AIC','BIC'});
ylabel('metric');
xlabel('number of states');