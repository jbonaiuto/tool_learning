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


% Single day models
% Days to run on
output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '10w_singleday_condHMM', array);

last_model=multiday_model;

models={};
max_state_lbl=-1;

%% Run the remaining days
for d_idx=1:length(dates)
    date=dates{d_idx};
    
    day_output_path=fullfile(output_path,date);
    % Load best model (lowest AIC)
    model=get_best_model(day_output_path, 'type', 'condition_covar');
    
    % Align to last model
    aligned_model=align_models(last_model, model);
    models{d_idx}=aligned_model;
    
        
    max_states_model=max([cellfun(@str2num,aligned_model.metadata.state_labels)]);
    max_state_lbl=max([max_state_lbl, max_states_model]);
    
    % Align to aligned model in next iteration
    last_model=aligned_model;    
end


%Emission matrice
overall_Ea_mat=zeros(el_num, max_state_lbl,length(dates)).*NaN;
overall_Eb_mat=zeros(el_num, max_state_lbl,length(dates)).*NaN;

basis=[0.01:0.01:8];

cm=cbrewer('seq','Blues',length(models));
for s=1:max_state_lbl
    figure();
    for e=1:el_num
        subplot(ceil(el_num/3),3,e);
        hold all;
        for m=1:length(models)
            model=models{m};
            state_idx=find(strcmp(model.metadata.state_labels,num2str(s)));
            if length(state_idx)>0        
                alpha=model.emiss_alpha_mat(state_idx,e);
                beta=model.emiss_beta_mat(state_idx,e);
                overall_Ea_mat(e,s,m)=alpha;
                overall_Eb_mat(e,s,m)=beta;
                plot(basis,gampdf(basis, alpha, 1/beta),'Color',cm(m,:));
            end
        end
        if e==1
            legend();
        end
    end
end

%transition matrice
overall_trans_mat=zeros(max_state_lbl,max_state_lbl,length(dates)).*NaN;

for s1=1:max_state_lbl
    for s2=1:max_state_lbl
        for m=1:length(models)
            model=models{m};
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
        el_stat_pdf=zeros(length(vals),length(models));
        for m=1:length(models)
            alpha=overall_Ea_mat(el,st,m);
            beta=overall_Eb_mat(el,st,m);
            el_stat_pdf(:,m)=gampdf(vals,alpha,1/beta);
        end
        imagesc([1:length(dates)],vals,el_stat_pdf);
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
        plot(squeeze(overall_trans_mat(s1,s2,:)));
        ylim([0,1]);
    end
end       
