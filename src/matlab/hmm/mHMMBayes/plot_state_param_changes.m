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

% metric for the alignment
metric='euclidean';
variable='EM';

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
dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
    '05.03.19','07.03.19','08.03.19','11.03.19'};


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
    [aligned_model,metric_val]=align_models(last_model, model, metric, variable);
    models{d_idx}=aligned_model;
    
        
    max_states_model=max([cellfun(@str2num,aligned_model.metadata.state_labels)]);
    max_state_lbl=max([max_state_lbl, max_states_model]);
    
    % Align to aligned model in next iteration
    last_model=aligned_model;    
end


%Emission matrice
overall_Ea_mat=zeros(el_num, max_state_lbl,length(dates));
overall_Eb_mat=zeros(el_num, max_state_lbl,length(dates));

for s=1:max_state_lbl
    for m=1:length(models)
        model=models{m};
        state_idx=find(strcmp(model.metadata.state_labels,num2str(s)));
        if length(state_idx)>0        
            overall_Ea_mat(:,state_idx,m)=model.emiss_alpha_mat(s,:);
            overall_Eb_mat(:,state_idx,m)=model.emiss_beta_mat(s,:);
        end
    end
end

%transition matrice
overall_trans_mat=zeros(max_state_lbl,max_state_lbl,length(dates));

for s1=1:max_state_lbl
    for s2=1:max_state_lbl
        for m=1:length(models)
            model=models{m};
            state1_idx=find(strcmp(model.metadata.state_labels,num2str(s1)));
            state2_idx=find(strcmp(model.metadata.state_labels,num2str(s2)));
            if length(state1_idx)>0 && length(state2_idx)>0
                overall_trans_mat(state1_idx,state2_idx,m)=model.trans_mat(s1,s2);  
            end
        end
    end
end       

%plots
figure();
elProbDay=zeros(el_num,length(dates));

%plot el prob by day for each state
for st=1:length( max_state_lbl)
    for d=1:length(dates)
        elProbDay(:,d)=overall_Ea_mat(:,st,d);
    end
    plot([1:length(dates)],elProbDay);   
end    

figure();
elProbDay=zeros(el_num,length(dates));

%plot el prob by day for each state
for st=1:length( max_state_lbl)
    for d=1:length(dates)
        elProbDay(:,d)=overall_Eb_mat(:,st,d);
    end
    plot([1:length(dates)],elProbDay);   
end    

figure();
elProbDay=zeros(el_num,length(dates));

%plot el prob by day for each state
for st=1:length( max_state_lbl)
    for d=1:length(dates)
        elProbDay(:,d)=overall_Eb_mat(:,st,d);
    end
    plot([1:length(dates)],elProbDay);   
end    
