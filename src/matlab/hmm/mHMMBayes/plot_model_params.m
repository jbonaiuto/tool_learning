function plot_model_params(model)

figure();
subplot(1,3,1);
imagesc(model.trans_mat);
set(gca,'ydir','normal');
set(gca,'XTick',[1:model.n_states],'XTickLabel',model.metadata.state_labels);
set(gca,'YTick',[1:model.n_states],'YTickLabel',model.metadata.state_labels);
colorbar()
subplot(1,3,2);
plot(model.emiss_alpha_mat');
legend(model.metadata.state_labels);
xlim([1 32]);
xlabel('Electrode');
ylabel('Alpha');
subplot(1,3,3);
plot(model.emiss_beta_mat');
legend(model.metadata.state_labels);
xlim([1 32]);
xlabel('Electrode');
ylabel('Beta');