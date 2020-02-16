function process_rsa_population(exp_info, event)

addpath(genpath('C:/Users/jbonaiuto/Dropbox/Toolboxes/rsatoolbox-develop/'));
conditions={'motor_grasp_left','motor_grasp_center','motor_grasp_right',...
    'visual_grasp_left','visual_grasp_right','visual_pliers_left','visual_pliers_right',...
    'visual_rake_pull_left','visual_rake_pull_right'};

condition_labels={};
for i=1:length(conditions)
    condition_labels{i}=strrep(conditions{i},'_', ' ');
end
%events={'go_aligned','movement_aligned','movement_aligned2','object_contact_aligned','object_place_aligned'};

all_condition_responses=[];
all_rdms=[];
for a_idx=1:length(exp_info.array_names)
    array_name=exp_info.array_names{a_idx};      
    fname=fullfile('C:/Users/jbonaiuto/Downloads/tool_learning/output/data/multiunit_rsa', sprintf('%s-%s.mat', array_name, event));        
    load(fname);
    all_condition_responses(a_idx,:,:)=condition_responses;
    all_rdms(a_idx,:,:) = corrcoef(normalise(condition_responses,1)');
end

model_rdms=create_model_RDMs();
model_labels={};
%fig=figure('Position',[1 1 1980 1080],'PaperPosition',[0 0 64 64], 'PaperUnits','inches');
for i=1:length(model_rdms)
    model_rdm=model_rdms{i};
    %ax=subplot(3,4,i);
    %plot_RDM(ax, model_rdm.RDM, condition_labels, strrep(model_rdm.name,'_',' '), [-1.2 1.2]);
    model_labels{i}=strrep(model_rdm.name,'_',' ');
end
%saveas(fig, 'C:\Users\jbonaiuto\Downloads\tool_learning\output\figures\templates.png');

userOptions=[];
userOptions.RDMrelatednessTest='randomisation';
userOptions.RDMcorrelationType='Spearman';
userOptions.candRDMdifferencesTest='conditionRFXbootstrap';
userOptions.rootPath=pwd;
userOptions.saveFiguresPS=false;
userOptions.saveFiguresPDF=false;
userOptions.saveFiguresFig=false;
userOptions.figureIndex=[];

% all_relatedness_r=[];
% all_relatedness_p=[];
% all_relatedness_names={};
% for a_idx=1:length(exp_info.array_names)
%     array_name=exp_info.array_names{a_idx};      
%     array_rdms=squeeze(all_rdms(a_idx,:,:,:));
%     for e_idx=1:length(events)
%         event=events{e_idx};
% %         stats_p_r = rsa.compareRefRDM2candRDMs(squeeze(array_rdms(e_idx,:,:)), model_rdms, userOptions);        
% %         all_relatedness_r(a_idx,e_idx,:)=stats_p_r.candRelatedness_r;
% %         all_relatedness_p(a_idx,e_idx,:)=stats_p_r.candRelatedness_p(2,:);
% %         all_relatedness_names(a_idx,e_idx,1:length(model_rdms))=[stats_p_r.orderedCandidateRDMnames];
%     end
% end

RSAmat={};
RSAdat=[];
for a_idx=1:length(exp_info.array_names)
    RSAmat{a_idx}=squeeze(all_rdms(a_idx,:,:));
    RSAdat(:,a_idx) = RSAmat{a_idx}(:);
end

r1 = ones(length(conditions),length(conditions));
r2 = eye(length(conditions));
%build design matrix:
dm = [r1(:) r2(:)];
for i=1:length(model_rdms)
    model_rdm=model_rdms{i};
    dm=[dm model_rdm.RDM(:)];
end
dm(:,3:end) = dm(:,3:end) ./ repmat(max(abs(dm(:,3:end))),[size(dm,1) 1]);
cmat = eye(size(dm,2));
dmr = (reshape(dm',size(dm,2),length(conditions),length(conditions))); 

[c,v,t] = ols(RSAdat,dm,cmat);

nP = 10000; %number of permutations - in the paper this was set to 10000.
cp=[];
vp=[];
tp=[];
RSAmatp={};
RSAdatp=[];
for p = 1:nP
    pp = randperm(length(conditions)); %randomly permute the 20 conditions
    
    %recompute the RSA matrices for each region:
    for a_idx=1:length(exp_info.array_names)
        all_condition_responses(a_idx,:,:)=condition_responses;
        RSAmatp{a_idx} = corrcoef(normalise(squeeze(all_condition_responses(a_idx,pp,:)),1)');
        RSAdatp(:,a_idx) = RSAmatp{a_idx}(:);
    end
    
    %calculate the test statistics in this permuted RSA matrix:
    [cp(p,:,:),vp(p,:,:),tp(p,:,:)] = ols(RSAdatp,dm,cmat);
    if mod(p,100)==0
        fprintf('%0.0f of %0.0f permutations complete\n',p,nP);
    end
end

fig=figure('Position',[1 1 1980 1080],'PaperPosition',[0 0 64 64], 'PaperUnits','inches');
ebars = squeeze(std(tp,[],1));
for i=3:size(dm,2)
    subplot(2,size(dm,2),i-2);
    imagesc(squeeze(dmr(i,:,:)));title(model_rdms{i-2}.name);%tidyfig;
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    caxis([-1.5 1.5]);
    colormap hot;freezeColors;
    axis square
    
    subplot(2,size(dm,2),size(dm,2)+i-2);
    bb=barwitherr([ebars(i,:); zeros(size(t(i,:)))],[t(i,:); zeros(size(t(i,:)))],0.5);%,'LineWidth',2);
    xlim([0.5 1.5]); box off; set(gca,'Box','off','XTickLabel',[]);%,'LineWidth',2);
    ylabel('T-statistic');
    %set(gca,'FontSize',13);set(get(gca,'YLabel'),'FontSize',13);
    %axis square
    colormap parula;freezeColors
end
l = legend(exp_info.array_names);
set(l,'Box','off');
    
fig=figure('Position',[1 1 1980 490],'PaperPosition',[0 0 64 32], 'PaperUnits','inches');
    
for a_idx=1:length(exp_info.array_names)
    array_name=exp_info.array_names{a_idx};      
    array_rdms=squeeze(all_rdms(a_idx,:,:));
    lims=[-max(abs(array_rdms(:))) max(abs(array_rdms(:)))];
    
    ax=subplot(2,length(exp_info.array_names),a_idx);
    plot_RDM(ax, array_rdms, condition_labels, sprintf('%s: %s', array_name, strrep(event,'_',' ')), lims, 'colorbar', a_idx==length(exp_info.array_names))
    
    subplot(2,length(exp_info.array_names),length(exp_info.array_names)+a_idx);
    bb=barwitherr([ebars(3:end,a_idx)'; zeros(size(t(3:end,a_idx)))'],[t(3:end,a_idx)'; zeros(size(t(3:end,a_idx)))'],0.5);%,'LineWidth',2);
    xlim([0.5 1.5]); box off; set(gca,'Box','off','XTickLabel',[]);%,'LineWidth',2);
    ylabel('T-statistic');
    %set(gca,'FontSize',13);set(get(gca,'YLabel'),'FontSize',13);
    %axis square
    colormap parula;freezeColors
    legend(model_labels);
%     
    %colorbar();
%     saveas(fig, fullfile('C:\Users\jbonaiuto\Downloads\tool_learning\output\figures\multiunit_rsa', sprintf('stage1-%s.png',array_name)));
    %close(fig);
end
% 
% fig=figure('Position',[1 1 1980 1080],'PaperPosition',[0 0 64 64], 'PaperUnits','inches');
% lims=[-max(abs(all_rdms(:))) max(abs(all_rdms(:)))];
% for e_idx=1:length(events)
%     event=events{e_idx};
%     event_rdms=squeeze(all_rdms(:,e_idx,:,:));
%     
%     for a_idx=1:length(exp_info.array_names)
%         array_name=exp_info.array_names{a_idx};      
%         ax=subplot(length(exp_info.array_names),length(events),(a_idx-1)*length(events)+e_idx);
%         plot_RDM(ax, squeeze(event_rdms(a_idx,:,:)), condition_labels, sprintf('%s: %s', array_name, strrep(event,'_',' ')), lims)
%         
% %         if a_idx==length(exp_info.array_names)
% %             originalSize = get(gca, 'Position');
% %             colorbar();
% %             set(gca, 'Position', originalSize);
% %         end
%     end        
% end
% saveas(fig, fullfile('C:\Users\jbonaiuto\Downloads\tool_learning\output\figures\multiunit_rsa', 'stage1-population.png'));
% %close(fig);