addpath('../..');
exp_info=init_exp_info();
array='F1';
subject='betta';
conditions={'motor_grasp_center','motor_grasp_right','motor_grasp_left'};
cond_labels={'center','right','left'};

dt=10;

dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
    '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19',...
    '13.03.19','14.03.19','15.03.19','18.03.19','19.03.19',...
    '20.03.19','21.03.19','25.03.19'};

output_path=fullfile(exp_info.base_output_dir, 'HMM', subject,...
    'motor_grasp', '5w_multiday_condHMM', array);

% Load best model (lowest AIC)
model=get_best_model(output_path, 'type', 'condition_covar');
load(fullfile(output_path,'data.mat'));
state_trial_stats=extract_state_trial_stats(model, data, dates, 'min_time_steps',1);

for c_idx=1:length(conditions)
        condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
        cond_trial_nbr(c_idx)=length(condition_trials);
end
max_cond_trials=max(cond_trial_nbr);
state_trials=sum(cond_trial_nbr);

anova_State_mat=NaN(state_trials,2);
anova_State_cond_mat=NaN(max_cond_trials,3);

%% number of activation for each state
%between state comparison
for s_idx=1:model.n_states
    for c_idx=1:length(conditions)
        % Find data trials for this condition
        condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
    
        active_mat=zeros(1,length(condition_trials));
        trial_cond=zeros(1,length(condition_trials));
        trial_state=zeros(1,length(condition_trials));
        for tc=1:length(condition_trials)
            active_mat(tc)=length(state_trial_stats.state_onsets{s_idx,condition_trials(tc)});
            trial_cond(tc)=c_idx;
            trial_state(tc)=s_idx;
        end
        
        if c_idx==1 && s_idx==1
        active_mat_cond_state=active_mat;
        active_mat_state=trial_state;
        active_mat_cond=trial_cond;
        else
        active_mat_cond_state= [active_mat_cond_state active_mat];
        active_mat_state=[active_mat_state trial_state];
        active_mat_cond=[active_mat_cond trial_cond];
        end
    end
end

for s_idx=1:model.n_states
    eval(['active_S' num2str(s_idx) '=active_mat_cond_state(find(active_mat_state==s_idx));']);
    eval(['active_S' num2str(s_idx) 'C1=active_mat_cond_state(find(active_mat_state==s_idx & active_mat_cond==1));']);
    eval(['active_S' num2str(s_idx) 'C2=active_mat_cond_state(find(active_mat_state==s_idx & active_mat_cond==2));']);
    eval(['active_S' num2str(s_idx) 'C3=active_mat_cond_state(find(active_mat_state==s_idx & active_mat_cond==3));']); 
end

% %     %export csv file to do a linear mixed model on R
%         %StateActivation_data=zeros(state_trials*model.n_states,4);
%         StateActivation_data={};
%         StAcDa_idx=0;
%         for s_idx=1:model.n_states
%             eval(['active_S' num2str(s_idx) '=active_mat_cond_state(find(active_mat_state==s_idx));']);
%             eval(['active_S' num2str(s_idx) 'C1=active_mat_cond_state(find(active_mat_state==s_idx & active_mat_cond==1));']);
%             eval(['active_S' num2str(s_idx) 'C2=active_mat_cond_state(find(active_mat_state==s_idx & active_mat_cond==2));']);
%             eval(['active_S' num2str(s_idx) 'C3=active_mat_cond_state(find(active_mat_state==s_idx & active_mat_cond==3));']); 
%             
%             for c_idx=1:length(conditions)
%                 for m=1:length(eval(['active_S' num2str(s_idx) 'C' num2str(c_idx)]))
%                     StAcDa_idx=StAcDa_idx+1;
%                     StateActivation_data{StAcDa_idx,1}=StAcDa_idx;
%                        if c_idx==1
%                       StateActivation_data{StAcDa_idx,2}='center';
%                        elseif c_idx==2
%                           StateActivation_data{StAcDa_idx,2}='right';
%                        else c_idx==3
%                            StateActivation_data{StAcDa_idx,2}='left';
%                        end
%                     StateActivation_data{StAcDa_idx,3}=s_idx;
%                     StateActivation_data{StAcDa_idx,4}=eval(['active_S' num2str(s_idx) 'C' num2str(c_idx) '(m)']);
%                 end
%             end
%         end
%         trial=StateActivation_data(:,1);
%         condition=StateActivation_data(:,2);
%         state=StateActivation_data(:,3);
%         state_activation=StateActivation_data(:,4);
%         T=table(trial,condition,state,state_activation);
%         writetable(T,fullfile(output_path,'NumberActivations.csv'));


results_stmt=fopen(fullfile(output_path,'ANOVA_ResultStatement_Activation_2 states.txt'),'wt');

for s_idx=1:model.n_states-1
        for ss_idx=s_idx+1:model.n_states
            anova_State_mat(:,1)=eval(['active_S' num2str(s_idx)]);
            anova_State_mat(:,2)=eval(['active_S' num2str(ss_idx)]);
            
%              % test for mean and variance normality assumtion with Shapiro-wilk test
%                 [H, pValue, W]=swtest(anova_State_mat(:,2), 0.05);
        
        %non parametric t-test: Mann-Whitney (not matched) or Wilcoxon
        %(matched pairs)
        [p,h,stats]=ranksum(anova_State_mat(:,1),anova_State_mat(:,2));

        end
end


%between condition comparison

results_stmt=fopen(fullfile(output_path,'ANOVAHSD_ResultStatement_Activation_3conditions.txt'),'wt');
for s_idx=1:model.n_states
    for t_idx=1:cond_trial_nbr(1)
        anova_State_cond_mat(t_idx,1)=eval(['active_S' num2str(s_idx) 'C1(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(2)
        anova_State_cond_mat(t_idx,2)=eval(['active_S' num2str(s_idx) 'C2(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(3)
        anova_State_cond_mat(t_idx,3)=eval(['active_S' num2str(s_idx) 'C3(t_idx)']);
    end
    
    % test for mean and variance normality assumtion with Shapiro-wilk test
            %[H, pValue, W]=swtest(anova_State_cond_mat(:,3), 0.05);
            
    % non-parametric ANOVA: Kruskal-Wallis (post hoc=Dunn's mc test that fits group with different size) 
    % or Friedmann (better with matched groups, post hoc test: wilcoxon matched pairs test with Bonferroni or Holm adjustment)? 
    %since we are in the same neuronal population we are in a matched situation
    %Friedmann
        [p,tbl,stats]=friedman(rmmissing(anova_State_cond_mat),'displayopt','off');
        Wilcoxon_cond_p=[];
    if p<0.05
        %  if significtive: wilcoxon rank sum test
        for c_idx=1:length(conditions)-1
            for cc_idx=c_idx+1:length(conditions)
                [p,h,stats]=ranksum(anova_State_cond_mat(:,c_idx),anova_State_cond_mat(:,cc_idx));
                Wilcoxon_cond_p(end+1)=p;
            end
        end
        
        %Bonferroni-Holm correction
        [corrected_p, h]=bonf_holm(Wilcoxon_cond_p,0.05);
    end
    % or instead of Wilcoxon rank sum test: Conover post-hoc test
        %[rZ,ties] = ranksWithTies(Z);  
end



%% Life time calculated based on the max duration of a state 

anova_State_mat=NaN(state_trials,2);
anova_State_cond_mat=NaN(max_cond_trials,3);

lifetime=state_trial_stats.state_durations;
for s=1:model.n_states
     for t=1:data.ntrials
        if isempty(lifetime{s,t})
           lifetime{s,t}=0;
        end
     end
 end

 for s_idx=1:model.n_states
    for c_idx=1:length(conditions)
        % Find data trials for this condition
        condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
    
        LT_max=zeros(1,length(condition_trials));
        trial_cond=zeros(1,length(condition_trials));
        trial_state=zeros(1,length(condition_trials));
        for tc=1:length(condition_trials)
            LT_max(tc)=max(lifetime{s_idx,condition_trials(tc)});
            trial_cond(tc)=c_idx;
            trial_state(tc)=s_idx;
        end
        
        if c_idx==1 && s_idx==1
        LT_max_cond_state=LT_max;
        LT_max_state=trial_state;
        LT_max_cond=trial_cond;
        else
        LT_max_cond_state= [LT_max_cond_state LT_max];
        LT_max_state=[LT_max_state trial_state];
        LT_max_cond=[LT_max_cond trial_cond];
        end
    end
end

for s_idx=1:model.n_states
    eval(['LT_max_S' num2str(s_idx) '=LT_max_cond_state(find(LT_max_state==s_idx));']);
    eval(['LT_max_S' num2str(s_idx) 'C1=LT_max_cond_state(find(LT_max_state==s_idx & LT_max_cond==1));']);
    eval(['LT_max_S' num2str(s_idx) 'C2=LT_max_cond_state(find(LT_max_state==s_idx & LT_max_cond==2));']);
    eval(['LT_max_S' num2str(s_idx) 'C3=LT_max_cond_state(find(LT_max_state==s_idx & LT_max_cond==3));']); 
end

state1={};
state2={};
pValue={};

for s_idx=1:model.n_states-1
        for ss_idx=s_idx+1:model.n_states
            anova_State_mat(:,1)=eval(['LT_max_S' num2str(s_idx)]);
            anova_State_mat(:,2)=eval(['LT_max_S' num2str(ss_idx)]);
            
            [p, tbl, stats]=anova1(anova_State_mat);
             stats=struct2table(stats,'AsArray',true);
            writetable(stats,fullfile(output_path,sprintf('ANOVAstats_LifeTimeMax_state%d_state%d.txt',s_idx,ss_idx)),'Delimiter','\t');
            
            state1{end+1}=sprintf('state%d',s_idx);
            state2{end+1}=sprintf('state%d',ss_idx);
            pValue{end+1}=p;
        end
end

state1=state1';
state2=state2';
pValue=pValue';

T2states_LifeTime_max=table(state1,state2,pValue);

writetable(T2states_LifeTime_max,fullfile(output_path,'T2states_LifeTime_max.txt'),'Delimiter','\t');

%between condition comparison
state={};
%condition={};
pValue={};
condition1={};
condition2={};

for s_idx=1:model.n_states
    for t_idx=1:cond_trial_nbr(1)
        anova_State_cond_mat(t_idx,1)=eval(['LT_max_S' num2str(s_idx) 'C1(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(2)
        anova_State_cond_mat(t_idx,2)=eval(['LT_max_S' num2str(s_idx) 'C2(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(3)
        anova_State_cond_mat(t_idx,3)=eval(['LT_max_S' num2str(s_idx) 'C3(t_idx)']);
    end
    
    [p, tbl, stats]=anova1(anova_State_cond_mat);
    
    [c,m,h,gnames]=multcompare(stats,'dimension',[1 2],'Display','off');

    stats=struct2table(stats,'AsArray',true);
    writetable(stats,fullfile(output_path,sprintf('ANOVAstats_LifeTimeMax_state%d_3conditions.txt',s_idx)),'Delimiter','\t');
    
    for c_idx=1:length(conditions)
        state{end+1}=sprintf('state%d',s_idx);
        condition1{end+1}=sprintf('condition%d',c(c_idx,1));
        condition2{end+1}=sprintf('condition%d',c(c_idx,2));
        pValue{end+1}=c(c_idx,6);
    end
end

state=state';
condition1=condition1';
condition2=condition2';
pValue=pValue';

T1state3cond_LifeTime_max=table(state,condition1,condition2,pValue);

writetable(T1state3cond_LifeTime_max,fullfile(output_path,'T1state3cond_LifeTime_max.txt'),'Delimiter','\t');

%% lifetime of a state based on the sum of activation

anova_State_mat=NaN(state_trials,2);
anova_State_cond_mat=NaN(max_cond_trials,3);

 for s_idx=1:model.n_states
    for c_idx=1:length(conditions)
        % Find data trials for this condition
        condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
    
        LT_sum=zeros(1,length(condition_trials));
        trial_cond=zeros(1,length(condition_trials));
        trial_state=zeros(1,length(condition_trials));
        for tc=1:length(condition_trials)
           LT_sum(tc)=sum(state_trial_stats.state_durations{s_idx,condition_trials(tc)});
            trial_cond(tc)=c_idx;
            trial_state(tc)=s_idx;
        end
        
        if c_idx==1 && s_idx==1
        LT_sum_cond_state=LT_sum;
        LT_sum_state=trial_state;
        LT_sum_cond=trial_cond;
        else
        LT_sum_cond_state= [LT_sum_cond_state LT_sum];
        LT_sum_state=[LT_sum_state trial_state];
        LT_sum_cond=[LT_sum_cond trial_cond];
        end
    end
 end

for s_idx=1:model.n_states
    eval(['LT_sum_S' num2str(s_idx) '=LT_sum_cond_state(find(LT_sum_state==s_idx));']);
    eval(['LT_sum_S' num2str(s_idx) 'C1=LT_sum_cond_state(find(LT_sum_state==s_idx & LT_sum_cond==1));']);
    eval(['LT_sum_S' num2str(s_idx) 'C2=LT_sum_cond_state(find(LT_sum_state==s_idx & LT_sum_cond==2));']);
    eval(['LT_sum_S' num2str(s_idx) 'C3=LT_sum_cond_state(find(LT_sum_state==s_idx & LT_sum_cond==3));']); 
end

state1={};
state2={};
pValue={};

for s_idx=1:model.n_states-1
        for ss_idx=s_idx+1:model.n_states
            anova_State_mat(:,1)=eval(['LT_sum_S' num2str(s_idx)]);
            anova_State_mat(:,2)=eval(['LT_sum_S' num2str(ss_idx)]);
            
            [p, tbl, stats]=anova1(anova_State_mat);
             stats=struct2table(stats,'AsArray',true);
            writetable(stats,fullfile(output_path,sprintf('ANOVAstats_LifeTimeSum_state%d_state%d.txt',s_idx,ss_idx)),'Delimiter','\t');
            
            state1{end+1}=sprintf('state%d',s_idx);
            state2{end+1}=sprintf('state%d',ss_idx);
            pValue{end+1}=p;
        end
end

state1=state1';
state2=state2';
pValue=pValue';

T2states_LifeTime_sum=table(state1,state2,pValue);

writetable(T2states_LifeTime_sum,fullfile(output_path,'T2states_LifeTime_sum.txt'),'Delimiter','\t');

%between condition comparison
state={};
%condition={};
pValue={};
condition1={};
condition2={};

for s_idx=1:model.n_states
    for t_idx=1:cond_trial_nbr(1)
        anova_State_cond_mat(t_idx,1)=eval(['LT_sum_S' num2str(s_idx) 'C1(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(2)
        anova_State_cond_mat(t_idx,2)=eval(['LT_sum_S' num2str(s_idx) 'C2(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(3)
        anova_State_cond_mat(t_idx,3)=eval(['LT_sum_S' num2str(s_idx) 'C3(t_idx)']);
    end
    
    [p, tbl, stats]=anova1(anova_State_cond_mat);
    
    [c,m,h,gnames]=multcompare(stats,'dimension',[1 2]);

    stats=struct2table(stats,'AsArray',true);
    writetable(stats,fullfile(output_path,sprintf('ANOVAstats_LifeTimeSum_state%d_3conditions.txt',s_idx)),'Delimiter','\t');
    
    for c_idx=1:length(conditions)
        state{end+1}=sprintf('state%d',s_idx);
        condition1{end+1}=sprintf('condition%d',c(c_idx,1));
        condition2{end+1}=sprintf('condition%d',c(c_idx,2));
        pValue{end+1}=c(c_idx,6);
    end
end

state=state';
condition1=condition1';
condition2=condition2';
pValue=pValue';

T1state3cond_LifeTime_sum=table(state,condition1,condition2,pValue);

writetable(T1state3cond_LifeTime_sum,fullfile(output_path,'T1state3cond_LifeTime_sum.txt'),'Delimiter','\t');

%% fracional time occupancy of a state

anova_State_mat=NaN(state_trials,2);
anova_State_cond_mat=NaN(max_cond_trials,3);

for s_idx=1:model.n_states
    for c_idx=1:length(conditions)
        condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
    
        ft_mat=zeros(1,length(condition_trials));
        trial_cond=zeros(1,length(condition_trials));
        trial_state=zeros(1,length(condition_trials));
        for tc=1:length(condition_trials)
           ft_mat(tc)=(sum(state_trial_stats.state_durations{s_idx,condition_trials(tc)})/data.metadata.reward(condition_trials(tc))).*100.0;
            trial_cond(tc)=c_idx;
            trial_state(tc)=s_idx;
        end
        
        if c_idx==1 && s_idx==1
        ft_mat_cond_state=ft_mat;
        ft_mat_state=trial_state;
        ft_mat_cond=trial_cond;
        else
        ft_mat_cond_state=[ft_mat_cond_state ft_mat];
        ft_mat_state=[ft_mat_state trial_state];
        ft_mat_cond=[ft_mat_cond trial_cond];
        end
    end
end

for s_idx=1:model.n_states
    eval(['ft_S' num2str(s_idx) '=ft_mat_cond_state(find(ft_mat_state==s_idx));']);
    eval(['ft_S' num2str(s_idx) 'C1=ft_mat_cond_state(find(ft_mat_state==s_idx & ft_mat_cond==1));']);
    eval(['ft_S' num2str(s_idx) 'C2=ft_mat_cond_state(find(ft_mat_state==s_idx & ft_mat_cond==2));']);
    eval(['ft_S' num2str(s_idx) 'C3=ft_mat_cond_state(find(ft_mat_state==s_idx & ft_mat_cond==3));']); 
end

% %     %export csv file to do a linear mixed model on R
        %fractional_occupancy_data=zeros(state_trials*model.n_states,4);
        fractional_occupancy_data={};
        FtOcDa_idx=0;
        for s_idx=1:model.n_states
            eval(['ft_S' num2str(s_idx) '=ft_mat_cond_state(find(ft_mat_state==s_idx));']);
            eval(['ft_S' num2str(s_idx) 'C1=ft_mat_cond_state(find(ft_mat_state==s_idx & ft_mat_cond==1));']);
            eval(['ft_S' num2str(s_idx) 'C2=ft_mat_cond_state(find(ft_mat_state==s_idx & ft_mat_cond==2));']);
            eval(['ft_S' num2str(s_idx) 'C3=ft_mat_cond_state(find(ft_mat_state==s_idx & ft_mat_cond==3));']); 
            
            for c_idx=1:length(conditions)
                for m=1:length(eval(['ft_S' num2str(s_idx) 'C' num2str(c_idx)]))
                    FtOcDa_idx=FtOcDa_idx+1;
                    fractional_occupancy_data{FtOcDa_idx,1}=FtOcDa_idx;
                       if c_idx==1
                      fractional_occupancy_data{FtOcDa_idx,2}='center';
                       elseif c_idx==2
                          fractional_occupancy_data{FtOcDa_idx,2}='right';
                       else c_idx==3
                           fractional_occupancy_data{FtOcDa_idx,2}='left';
                       end
                    fractional_occupancy_data{FtOcDa_idx,3}=s_idx;
                    fractional_occupancy_data{FtOcDa_idx,4}=eval(['ft_S' num2str(s_idx) 'C' num2str(c_idx) '(m)']);
                end
            end
        end
        trial=fractional_occupancy_data(:,1);
        condition=fractional_occupancy_data(:,2);
        state=fractional_occupancy_data(:,3);
        fractionnal_occupancy=fractional_occupancy_data(:,4);
        T=table(trial,condition,state,fractionnal_occupancy);
        writetable(T,fullfile(output_path,'FractionnalOccupancy.csv'));



state1={};
state2={};
pValue={};

for s_idx=1:model.n_states-1
        for ss_idx=s_idx+1:model.n_states
            anova_State_mat(:,1)=eval(['ft_S' num2str(s_idx)]);
            anova_State_mat(:,2)=eval(['ft_S' num2str(ss_idx)]);
            
            [p, tbl, stats]=anova1(anova_State_mat);
             stats=struct2table(stats,'AsArray',true);
            writetable(stats,fullfile(output_path,sprintf('ANOVAstats_fractionalOccupancy_state%d_state%d.txt',s_idx,ss_idx)),'Delimiter','\t');
            
            state1{end+1}=sprintf('state%d',s_idx);
            state2{end+1}=sprintf('state%d',ss_idx);
            pValue{end+1}=p;
        end
end

state1=state1';
state2=state2';
pValue=pValue';

T2states_FractionalOccupancy=table(state1,state2,pValue);

writetable(T2states_FractionalOccupancy,fullfile(output_path,'T2states_FractionalOccupancy.txt'),'Delimiter','\t');

%between condition comparison
state={};
%condition={};
pValue={};
condition1={};
condition2={};

for s_idx=1:model.n_states
    for t_idx=1:cond_trial_nbr(1)
        anova_State_cond_mat(t_idx,1)=eval(['ft_S' num2str(s_idx) 'C1(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(2)
        anova_State_cond_mat(t_idx,2)=eval(['ft_S' num2str(s_idx) 'C2(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(3)
        anova_State_cond_mat(t_idx,3)=eval(['ft_S' num2str(s_idx) 'C3(t_idx)']);
    end
    
    [p, tbl, stats]=anova1(anova_State_cond_mat);
    
    [c,m,h,gnames]=multcompare(stats,'dimension',[1 2],'Display','off');

    stats=struct2table(stats,'AsArray',true);
    writetable(stats,fullfile(output_path,sprintf('ANOVAstats_FractionalOccupancy_state%d_3conditions.txt',s_idx)),'Delimiter','\t');
    
    for c_idx=1:length(conditions)
        state{end+1}=sprintf('state%d',s_idx);
        condition1{end+1}=sprintf('condition%d',c(c_idx,1));
        condition2{end+1}=sprintf('condition%d',c(c_idx,2));
        pValue{end+1}=c(c_idx,6);
    end
end
state=state';
condition1=condition1';
condition2=condition2';
pValue=pValue';

T1state3cond_FractionalOccupancy=table(state,condition1,condition2,pValue);

writetable(T1state3cond_FractionalOccupancy,fullfile(output_path,'T1state3cond_FractionalOccupancy.txt'),'Delimiter','\t');

%% interval time between same state activation

anova_State_mat=NaN(state_trials,2);
anova_State_cond_mat=NaN(max_cond_trials,3);

for s_idx=1:model.n_states
    for c_idx=1:length(conditions)
        condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
    
        interval_mat=[];
        trial_cond=[];
        trial_state=[];
        for tc=1:length(condition_trials)
            offset=state_trial_stats.state_offsets{s_idx,condition_trials(tc)};
            onset=state_trial_stats.state_onsets{s_idx,condition_trials(tc)};
                if length(offset)>1
                    interval_mat(end+1)=mean(onset(2:end)-offset(1:end-1));
                    trial_cond(end+1)=c_idx;
                    trial_state(end+1)=s_idx;
                end
        end
        
        if c_idx==1 && s_idx==1
        interval_mat_cond_state=interval_mat;
        interval_mat_state=trial_state;
        interval_mat_cond=trial_cond;
        else
        interval_mat_cond_state=[interval_mat_cond_state interval_mat];
        interval_mat_state=[interval_mat_state trial_state];
        interval_mat_cond=[interval_mat_cond trial_cond];
        end
    end
end

for s_idx=1:model.n_states
    eval(['interval_S' num2str(s_idx) '=interval_mat_cond_state(find(interval_mat_state==s_idx));']);
    eval(['interval_S' num2str(s_idx) 'C1=interval_mat_cond_state(find(interval_mat_state==s_idx & interval_mat_cond==1));']);
    eval(['interval_S' num2str(s_idx) 'C2=interval_mat_cond_state(find(interval_mat_state==s_idx & interval_mat_cond==2));']);
    eval(['interval_S' num2str(s_idx) 'C3=interval_mat_cond_state(find(interval_mat_state==s_idx & interval_mat_cond==3));']); 
end

state1={};
state2={};
pValue={};

for s_idx=1:model.n_states-1
        for ss_idx=s_idx+1:model.n_states
            for t_idx=1:length(eval(['interval_S' num2str(s_idx)]))
                anova_State_mat(t_idx,1)=eval(['interval_S' num2str(s_idx) '(t_idx)']);
            end
            for t_idx=1:length(eval(['interval_S' num2str(ss_idx)]))
                anova_State_mat(t_idx,2)=eval(['interval_S' num2str(ss_idx) '(t_idx)']);
            end
            
            [p, tbl, stats]=anova1(anova_State_mat);
             stats=struct2table(stats,'AsArray',true);
            writetable(stats,fullfile(output_path,sprintf('ANOVAstats_sameStateInterval_state%d_state%d.txt',s_idx,ss_idx)),'Delimiter','\t');
            
            state1{end+1}=sprintf('state%d',s_idx);
            state2{end+1}=sprintf('state%d',ss_idx);
            pValue{end+1}=p;
        end
end

state1=state1';
state2=state2';
pValue=pValue';

T2states_TimeIntervale=table(state1,state2,pValue);

writetable(T2states_TimeIntervale,fullfile(output_path,'T2states_TimeIntervale.txt'),'Delimiter','\t');

%between condition comparison
state={};
%condition={};
pValue={};
condition1={};
condition2={};

for s_idx=1:model.n_states
    for t_idx=1:length(eval(['interval_S' num2str(s_idx) 'C1']))
        anova_State_cond_mat(t_idx,1)=eval(['interval_S' num2str(s_idx) 'C1(t_idx)']);
    end
    for t_idx=1:length(eval(['interval_S' num2str(s_idx) 'C2']))
        anova_State_cond_mat(t_idx,2)=eval(['interval_S' num2str(s_idx) 'C2(t_idx)']);
    end
    for t_idx=1:length(eval(['interval_S' num2str(s_idx) 'C3']))
        anova_State_cond_mat(t_idx,3)=eval(['interval_S' num2str(s_idx) 'C3(t_idx)']);
    end
    
    [p, tbl, stats]=anova1(anova_State_cond_mat);
    
    [c,m,h,gnames]=multcompare(stats,'dimension',[1 2],'Display','off');

     stats=struct2table(stats,'AsArray',true);
    writetable(stats,fullfile(output_path,sprintf('ANOVAstats_SameStateInterval_state%d_3conditions.txt',s_idx)),'Delimiter','\t');
    
    for c_idx=1:length(conditions)
        state{end+1}=sprintf('state%d',s_idx);
        condition1{end+1}=sprintf('condition%d',c(c_idx,1));
        condition2{end+1}=sprintf('condition%d',c(c_idx,2));
        pValue{end+1}=c(c_idx,6);
    end
end
state=state';
condition1=condition1';
condition2=condition2';
pValue=pValue';

T1state3cond_TimeIntervale=table(state,condition1,condition2,pValue);

writetable(T1state3cond_TimeIntervale,fullfile(output_path,'T1state3cond_TimeIntervale.txt'),'Delimiter','\t');

%% state blips (activation of 10ms or less)

anova_State_mat=NaN(state_trials,2);
anova_State_cond_mat=NaN(max_cond_trials,3);

for s_idx=1:model.n_states
    for c_idx=1:length(conditions)
        condition_trials = find(strcmp(data.metadata.condition,conditions{c_idx}));
    
        blip_mat=zeros(1,length(condition_trials));
        trial_cond=zeros(1,length(condition_trials));
        trial_state=zeros(1,length(condition_trials));
        for tc=1:length(condition_trials)
           blip_mat(tc)=length(find(state_trial_stats.state_durations{s_idx,condition_trials(tc)}<=10));
           trial_cond(tc)=c_idx;
           trial_state(tc)=s_idx;
        end
        
        if c_idx==1 && s_idx==1
        blip_mat_cond_state=blip_mat;
        blip_mat_state=trial_state;
        blip_mat_cond=trial_cond;
        else
        blip_mat_cond_state=[blip_mat_cond_state blip_mat];
        blip_mat_state=[blip_mat_state trial_state];
        blip_mat_cond=[blip_mat_cond trial_cond];
        end
    end
end

for s_idx=1:model.n_states
    eval(['blip_S' num2str(s_idx) '=blip_mat_cond_state(find(blip_mat_state==s_idx));']);
    eval(['blip_S' num2str(s_idx) 'C1=blip_mat_cond_state(find(blip_mat_state==s_idx & blip_mat_cond==1));']);
    eval(['blip_S' num2str(s_idx) 'C2=blip_mat_cond_state(find(blip_mat_state==s_idx & blip_mat_cond==2));']);
    eval(['blip_S' num2str(s_idx) 'C3=blip_mat_cond_state(find(blip_mat_state==s_idx & blip_mat_cond==3));']); 
end

state1={};
state2={};
pValue={};

for s_idx=1:model.n_states-1
        for ss_idx=s_idx+1:model.n_states
            anova_State_mat(:,1)=eval(['blip_S' num2str(s_idx)]);
            anova_State_mat(:,2)=eval(['blip_S' num2str(ss_idx)]);
            
            [p, tbl, stats]=anova1(anova_State_mat);
             stats=struct2table(stats,'AsArray',true);
            writetable(stats,fullfile(output_path,sprintf('ANOVAstats_blips_state%d_state%d.txt',s_idx,ss_idx)),'Delimiter','\t');
            
            state1{end+1}=sprintf('state%d',s_idx);
            state2{end+1}=sprintf('state%d',ss_idx);
            pValue{end+1}=p;
        end
end

state1=state1';
state2=state2';
pValue=pValue';

T2states_Blips=table(state1,state2,pValue);

writetable(T2states_Blips,fullfile(output_path,'T2states_Blips.txt'),'Delimiter','\t');

%between condition comparison
state={};
%condition={};
pValue={};
condition1={};
condition2={};

for s_idx=1:model.n_states
    for t_idx=1:cond_trial_nbr(1)
        anova_State_cond_mat(t_idx,1)=eval(['blip_S' num2str(s_idx) 'C1(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(2)
        anova_State_cond_mat(t_idx,2)=eval(['blip_S' num2str(s_idx) 'C2(t_idx)']);
    end
    for t_idx=1:cond_trial_nbr(3)
        anova_State_cond_mat(t_idx,3)=eval(['blip_S' num2str(s_idx) 'C3(t_idx)']);
    end
    
    [p, tbl, stats]=anova1(anova_State_cond_mat);
    
    [c,m,h,gnames]=multcompare(stats,'dimension',[1 2],'Display','off');

     stats=struct2table(stats,'AsArray',true);
    writetable(stats,fullfile(output_path,sprintf('ANOVAstats_blip_state%d_3conditions.txt',s_idx)),'Delimiter','\t');
    
    for c_idx=1:length(conditions)
        state{end+1}=sprintf('state%d',s_idx);
        condition1{end+1}=sprintf('condition%d',c(c_idx,1));
        condition2{end+1}=sprintf('condition%d',c(c_idx,2));
        pValue{end+1}=c(c_idx,6);
    end
end
state=state';
condition1=condition1';
condition2=condition2';
pValue=pValue';

T1state3cond_Blips=table(state,condition1,condition2,pValue);

writetable(T1state3cond_Blips,fullfile(output_path,'T1state3cond_Blips.txt'),'Delimiter','\t');

close all
