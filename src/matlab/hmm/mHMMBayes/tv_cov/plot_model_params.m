function plot_model_params(model, conditions)

state_idx=get_state_idx(model);

f=figure();
n_row=1;
n_col=3;
if strcmp(model.type,'condition_covar')
    n_row=3;
    n_col=3;
end

sp_idx=1;
subplot(n_row,n_col,sp_idx);
imagesc(log(model.trans_mat(state_idx,state_idx)));
set(gca,'XTick',[1:model.n_states],'XTickLabel',model.metadata.state_labels(state_idx));
set(gca,'YTick',[1:model.n_states],'YTickLabel',model.metadata.state_labels(state_idx));
title('overall');
a=colorbar();
ylabel(a,'log(prob)');

if strcmp(model.type,'condition_covar')
    sp_idx=4;
    for i=1:length(conditions)
        subplot(n_row,n_col,sp_idx);
        imagesc(log(squeeze(model.cond_trans_cov_med_mat(i,state_idx,state_idx))));
        set(gca,'XTick',[1:model.n_states],'XTickLabel',model.metadata.state_labels(state_idx));
        set(gca,'YTick',[1:model.n_states],'YTickLabel',model.metadata.state_labels(state_idx));
        title(strrep(conditions{i},'_',' '));
        a=colorbar();
        ylabel(a,'log(prob)');
        sp_idx=sp_idx+1;
    end
else
    sp_idx=2;
end
subplot(n_row,n_col,sp_idx);
plot(model.emiss_mu_mat(state_idx,:)');
legend(model.metadata.state_labels(state_idx));
xlim([1 size(model.emiss_mu_mat,2)]);
xlabel('Electrode');
ylabel('Mean');
sp_idx=sp_idx+1;

subplot(n_row,n_col,sp_idx);
plot(model.emiss_varmu_mat(state_idx,:)');
legend(model.metadata.state_labels(state_idx));
xlim([1 size(model.emiss_varmu_mat,2)]);
xlabel('Electrode');
ylabel('Var');
sp_idx=sp_idx+1;

