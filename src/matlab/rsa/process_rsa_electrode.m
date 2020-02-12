function process_rsa_electrode(exp_info)

addpath(genpath('C:\Users\jbonaiuto\Dropbox\Toolboxes\rsatoolbox-develop'));
conditions={'motor_grasp_left','motor_grasp_center','motor_grasp_right',...
    'visual_grasp_left','visual_grasp_right','visual_pliers_left','visual_pliers_right',...
    'visual_rake_pull_left','visual_rake_pull_right'};

condition_labels={};
for i=1:length(conditions)
    condition_labels{i}=strrep(conditions{i},'_', ' ');
end
events={'go_aligned','movement_aligned','movement_aligned2','object_contact_aligned','object_place_aligned'};

all_rdms=[];
for a_idx=1:length(exp_info.array_names)
    array_name=exp_info.array_names{a_idx};      
    
    for elec_idx=1:exp_info.ch_per_array
        for e_idx=1:length(events)
            event=events{e_idx};
            fname=fullfile('C:/Users/jbonaiuto/Downloads/tool_learning/output/data/multiunit_rsa', sprintf('%s_%d-%s.mat', array_name, elec_idx, event));
            all_rdms(a_idx,elec_idx,e_idx,:,:)=create_RDM(fname);
        end
    end
end

   
for a_idx=1:length(exp_info.array_names)
    array_name=exp_info.array_names{a_idx};      
    for elec_idx=1:exp_info.ch_per_array
        elec_rdms=squeeze(all_rdms(a_idx,elec_idx,:,:,:));
        lims=[0 max(elec_rdms(:))];
    
        fig=figure('Position',[1 1 1980 490],'PaperPosition',[0 0 64 32], 'PaperUnits','inches');
        for e_idx=1:length(events)
            event=events{e_idx};
            subplot(1,length(events),e_idx);
            imagesc(squeeze(elec_rdms(e_idx,:,:)),lims);
            axis square;
            set(gca,'ytick',[1:length(conditions)],'yticklabel',condition_labels);
            set(gca,'xtick',[1:length(conditions)],'xticklabel',condition_labels,'XTickLabelRotation',45);
            title(sprintf('%s-%d: %s', array_name, elec_idx, strrep(event,'_',' ')));
    %         if e_idx==length(events)
    %             originalSize = get(gca, 'Position');
    %             colorbar();
    %             set(gca, 'Position', originalSize);
    %         end
        end
        saveas(fig, fullfile('C:\Users\jbonaiuto\Downloads\tool_learning\output\figures\multiunit_rsa', sprintf('stage1-%s_%d.png',array_name,elec_idx)));
        close(fig);
    end
end

for e_idx=1:length(events)
    event=events{e_idx};
    for a_idx=1:length(exp_info.array_names)
        array_name=exp_info.array_names{a_idx};      
        event_rdms=squeeze(all_rdms(a_idx,:,e_idx,:,:));
        lims=[0 max(event_rdms(:))];
    
        fig=figure('Position',[1 1 1980 1080],'PaperPosition',[0 0 64 64], 'PaperUnits','inches');
        for elec_idx=1:exp_info.ch_per_array
            subplot(4,8,elec_idx);
            imagesc(squeeze(event_rdms(elec_idx,:,:)),lims);
            axis square;
            set(gca,'ytick',[1:length(conditions)],'yticklabel',condition_labels);
            set(gca,'xtick',[1:length(conditions)],'xticklabel',condition_labels,'XTickLabelRotation',45);
            title(sprintf('%s-%d: %s', array_name, elec_idx, strrep(event,'-',' ')));
    %         if e_idx==length(events)
    %             originalSize = get(gca, 'Position');
    %             colorbar();
    %             set(gca, 'Position', originalSize);
    %         end
        end
        saveas(fig, fullfile('C:\Users\jbonaiuto\Downloads\tool_learning\output\figures\multiunit_rsa', sprintf('stage1-%s_%s.png',event,array_name)));
        close(fig);
    end
end