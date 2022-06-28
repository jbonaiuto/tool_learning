clear all

addpath('../..');
addpath('../../spike_data_processing');
exp_info=init_exp_info();
subject='betta';

% Array to run model on
array='F1';
%array='F5hand';
%array='46v-12r';
%array='F5mouth';

% Conditions to run on
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};

% Days to run on
dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
    '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19'};


% Load multi-day
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '10w_multiday_condHMM', array);

% Load best model (lowest AIC)
multiday_model=get_best_model(output_path, 'type', 'condition_covar');
el_num=size(multiday_model.emiss_alpha_mat,2);
max_state_lbl=max([cellfun(@str2num,multiday_model.metadata.state_labels)]);


% % Load multilevel
% for cond_idx=1:length(conditions)
%     output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
%         'motor_grasp', '10w_mHMM', array, conditions{cond_idx});
%         
%     % Load best model (lowest AIC)
%     model=get_best_model(output_path, 'type', 'multilevel');
%     
%     multilevel_models(cond_idx)=model;
% end
% 
% threshold=compute_kl_threshold(multilevel_models);
% 
% for cond_idx=1:length(conditions)
%     multilevel_models(cond_idx)=align_models([multiday_model], multilevel_models(cond_idx), threshold);
%     max_states_model=max([cellfun(@str2num,multilevel_models(cond_idx).metadata.state_labels)]);
%     max_state_lbl=max([max_state_lbl, max_states_model]);
% end

% Single day models
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '10w_twoday_condHMM', array);
    %'motor_grasp', '10w_singleday_condHMM', array);

%% Run the remaining days
for d_idx=1:length(dates)/2
    date=dates{d_idx};
    
    %day_output_path=fullfile(output_path,date);
    day_output_path=fullfile(output_path,num2str(d_idx));
    % Load best model (lowest AIC)
    model=get_best_model(day_output_path, 'type', 'condition_covar', 'plot', false);
    
    singleday_models(d_idx)=model;
end

threshold=compute_kl_threshold([multiday_model]);
prev_models=[multiday_model];
for d_idx=1:length(singleday_models)
    % Align to last model
    singleday_models(d_idx)=align_models(prev_models, singleday_models(d_idx), threshold);
    % Align to aligned model in next iteration
    prev_models(end+1)=singleday_models(d_idx);    
    max_states_model=max([cellfun(@str2num,singleday_models(d_idx).metadata.state_labels)]);
    max_state_lbl=max([max_state_lbl, max_states_model]);
    
end

%Emission matrice
%overall_Ea_mat=zeros(el_num, max_state_lbl,length(dates)+1+length(conditions)).*NaN;
overall_Ea_mat=zeros(el_num, max_state_lbl,length(dates)+1).*NaN;
%overall_Eb_mat=zeros(el_num, max_state_lbl,length(dates)+1+length(conditions)).*NaN;
overall_Eb_mat=zeros(el_num, max_state_lbl,length(dates)+1).*NaN;

basis=[0.01:0.01:8];

cm=cbrewer('seq','Blues',length(singleday_models));
for s=1:max_state_lbl
    figure();
    for e=1:el_num
        subplot(ceil(el_num/3),3,e);
        leg_lbls={};
        hold all;
        state_idx=find(strcmp(multiday_model.metadata.state_labels,num2str(s)));
        if length(state_idx)>0        
            leg_lbls{end+1}='multiday';
            alpha=multiday_model.emiss_alpha_mat(state_idx,e);
            beta=multiday_model.emiss_beta_mat(state_idx,e);
            overall_Ea_mat(e,s,1)=alpha;
            overall_Eb_mat(e,s,1)=beta;
            plot(basis,gampdf(basis, alpha, 1/beta));
        end
%         for m=1:length(conditions)
%             model=multilevel_models(m);
%             state_idx=find(strcmp(model.metadata.state_labels,num2str(s)));
%             if length(state_idx)>0 
%                 leg_lbls{end+1}=sprintf('Multilevel - %s', conditions{m});       
%                 alpha=model.emiss_alpha_mat(state_idx,e);
%                 beta=model.emiss_beta_mat(state_idx,e);
%                 overall_Ea_mat(e,s,m+1)=alpha;
%                 overall_Eb_mat(e,s,m+1)=beta;
%                 plot(basis,gampdf(basis, alpha, 1/beta));
%             end
%         end
        for m=1:length(singleday_models)
            model=singleday_models(m);
            state_idx=find(strcmp(model.metadata.state_labels,num2str(s)));
            if length(state_idx)>0 
                leg_lbls{end+1}=num2str(m);       
                alpha=model.emiss_alpha_mat(state_idx,e);
                beta=model.emiss_beta_mat(state_idx,e);
                %overall_Ea_mat(e,s,m+1+length(conditions))=alpha;
                overall_Ea_mat(e,s,m+1)=alpha;
                %overall_Eb_mat(e,s,m+1+length(conditions))=beta;
                overall_Eb_mat(e,s,m+1)=beta;
                plot(basis,gampdf(basis, alpha, 1/beta),'Color',cm(m,:));
            end
        end
        if e==1
            legend(leg_lbls);
        end
    end
end

%transition matrice
overall_trans_mat=zeros(max_state_lbl,max_state_lbl,length(singleday_models)).*NaN;

for s1=1:max_state_lbl
    for s2=1:max_state_lbl
        for m=1:length(singleday_models)
            model=singleday_models(m);
            state1_idx=find(strcmp(model.metadata.state_labels,num2str(s1)));
            state2_idx=find(strcmp(model.metadata.state_labels,num2str(s2)));
            if length(state1_idx)>0 && length(state2_idx)>0
                overall_trans_mat(s1,s2,m)=model.trans_mat(state1_idx,state2_idx);  
            end
        end
    end
end       

vals=[0.01:0.01:5];

%plots
figure();
for st=1:max_state_lbl
    for el=1:el_num
        subplot(el_num,max_state_lbl,(el-1)*max_state_lbl+st);
        el_stat_pdf=zeros(length(vals),length(singleday_models)+1);
        for m=1:length(singleday_models)+1%+length(conditions)
            alpha=overall_Ea_mat(el,st,m);
            beta=overall_Eb_mat(el,st,m);
            el_stat_pdf(:,m)=gampdf(vals,alpha,1/beta);
        end
        %imagesc([1:length(singleday_models)+length(conditions)],vals,el_stat_pdf);
        imagesc([1:length(singleday_models)+1],vals,el_stat_pdf);
        hold on
        plot([1.5 1.5],ylim(),'w--');
        %for m=1:length(conditions)
        %    plot([1.5 1.5]+m,ylim(),'w--');
        %end
        set(gca,'XTickLabel','');
        ax = gca;
        outerpos = ax.OuterPosition;
        ti = ax.TightInset; 
        left = outerpos(1) + ti(1);
        bottom = outerpos(2) + ti(2);
        ax_width = outerpos(3) - ti(1) - ti(3);
        ax_height = outerpos(4) - ti(2) - ti(4);
        ax.Position = [left bottom ax_width ax_height];
        if st==1
            ylabel(sprintf('E%d',el));
        end
        if el==1
            title(sprintf('State %d',st));
        end
        if el==el_num
            xlabel('Day');
        end
    end
end

%transition plots
figure();
for s1=1:max_state_lbl
    for s2=1:max_state_lbl
        subplot(max_state_lbl,max_state_lbl,(s1-1)*max_state_lbl+s2);
        hold all;
        plot(squeeze(overall_trans_mat(s1,s2,:)));
        state1_idx=find(strcmp(multiday_model.metadata.state_labels,num2str(s1)));
        state2_idx=find(strcmp(multiday_model.metadata.state_labels,num2str(s2)));
        if length(state1_idx)>0 && length(state2_idx)>0
            p=multiday_model.trans_mat(state1_idx,state2_idx);  
            plot(xlim(),[p p]);
        end
%         for m=1:length(conditions)
%             model=multilevel_models(m);
%             state1_idx=find(strcmp(model.metadata.state_labels,num2str(s1)));
%             state2_idx=find(strcmp(model.metadata.state_labels,num2str(s2)));
%             if length(state1_idx)>0 && length(state2_idx)>0
%                 p=model.trans_mat(state1_idx,state2_idx);  
%                 plot(xlim(),[p p]);
%             end
%         end
        ylim([0,1]);
    end
end       
