%dbstop if error
clear all
addpath('../..');
addpath('../../spike_data_processing');
exp_info=init_exp_info();

subject='betta';
array='F1';
dt=10;
metric='euclidean';
variable='EM';
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};
el_num=32 ;

dates={'26.02.19','27.02.19','28.02.19'};
days_num=length(dates);


% Create output path if it doesnt exist
output_path=fullfile(exp_info.base_output_dir, 'HMM', 'betta',...
    'motor_grasp', '10w_singleday_condHMM', array);
if exist(output_path,'dir')~=7
    mkdir(output_path);
end

%day1
day1_model_date=dates{1};
day1_output_path=fullfile(output_path,dates{1});
day1_model=get_best_model(day1_output_path);
%previous_max1=max([cellfun(@str2num,day1_model.metadata.state_labels)]);
%day1_model.metadata.state_labels{end}=num2str(cellfun(@str2num,day1_model.metadata.state_labels(end))+1);

%day2
day2_model_date=dates{2};
day2_output_path=fullfile(output_path,dates{2});
day2_model=get_best_model(day2_output_path);
% Align to last model
aligned_model2=align_models(day1_model, day2_model, metric, variable);
%previous_max2=max([cellfun(@str2num,day2_model.metadata.state_labels)]);
%aligned_model2.metadata.state_labels{end}=num2str(cellfun(@str2num,aligned_model2.metadata.state_labels(end))-1);
    
%day3
day3_model_date=dates{3};
day3_output_path=fullfile(output_path,dates{3});
day3_model=get_best_model(day3_output_path);
% Align to last model
aligned_model3=align_models(aligned_model2, day3_model, metric, variable);
%previous_max3=max([cellfun(@str2num,day3_model.metadata.state_labels)]);
%aligned_model3.metadata.state_labels{end}=num2str(cellfun(@str2num,aligned_model3.metadata.state_labels(end))+1);

    
max_states_model1=max([cellfun(@str2num,day1_model.metadata.state_labels)]);
max_states_model2=max([cellfun(@str2num,aligned_model2.metadata.state_labels)]);
max_states_model3=max([cellfun(@str2num,aligned_model3.metadata.state_labels)]);

overall_max=max([max_states_model1, max_states_model2, max_states_model3]);

%Emission matrice
overall_Ea_mat=zeros(el_num, overall_max,days_num);
overall_Eb_mat=zeros(el_num, overall_max,days_num);

for s=1:overall_max
    %day1
    state_idx=find(strcmp(day1_model.metadata.state_labels,num2str(s)));
    if length(state_idx)>0        
        overall_Ea_mat(:,state_idx,1)=day1_model.emiss_alpha_mat(s,:);
        overall_Eb_mat(:,state_idx,1)=day1_model.emiss_beta_mat(s,:);
    end
    %day2
    state_idx=find(strcmp(aligned_model2.metadata.state_labels,num2str(s)));
    if length(state_idx)>0        
        overall_Ea_mat(:,state_idx,2)=aligned_model2.emiss_alpha_mat(s,:);
        overall_Eb_mat(:,state_idx,2)=aligned_model2.emiss_beta_mat(s,:);
    end
    %day3
    state_idx=find(strcmp(aligned_model3.metadata.state_labels,num2str(s)));
    if length(state_idx)>0        
        overall_Ea_mat(:,state_idx,3)=aligned_model3.emiss_alpha_mat(s,:);
        overall_Eb_mat(:,state_idx,3)=aligned_model3.emiss_beta_mat(s,:);        
    end    
end       

%transition matrice
overall_trans_mat=zeros(overall_max,overall_max,days_num);

for s=1:overall_max
    state_idx=find(strcmp(day1_model.metadata.state_labels,num2str(s)));
    %day1
    if length(state_idx)>0        
        overall_trans_mat(:,state_idx,1)=day1_model.trans_mat(s,:);  
    end 
    %day2
    state_idx=find(strcmp(day2_model.metadata.state_labels,num2str(s)));
    if length(state_idx)>0        
        overall_trans_mat(:,state_idx,2)=aligned_model2.trans_mat(s,:);
    end
    %day3
    state_idx=find(strcmp(day3_model.metadata.state_labels,num2str(s)));
    if length(state_idx)>0        
        overall_trans_mat(:,state_idx,3)=aligned_model3.trans_mat(s,:);     
    end    
end       


