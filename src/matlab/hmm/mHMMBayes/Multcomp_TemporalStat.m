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

%%
%mean number of activation for each state
figure()
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

next_state=0;
for s_idx=1:model.n_states-1
        for ss_idx=s_idx+1:model.n_states
            anova_State_mat(:,1)=eval(['active_S' num2str(s_idx)]);
            anova_State_mat(:,2)=eval(['active_S' num2str(ss_idx)]);
            
            [p, tbl, stats]=anova1(anova_State_mat);
            results=multcompare(stats,'dimension',[1 2]);
            title(sprintf('state%d - state%d',s_idx,ss_idx))
            legend(['p value' ' ' num2str(p)],'location','EastOutside')
        end
end

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
    
    [p, tbl, stats]=anova1(anova_State_cond_mat);
    results=multcompare(stats,'dimension',[1 2]);
    title(sprintf('state%d - 3conditions',s_idx))
end


%%
figure()
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

[p, tbl, stats]=anovan(LT_max_cond_state,{LT_max_state,LT_max_cond},'model','interaction',...
    'varnames',{'LT_max_state','LT_max_cond'});
results=multcompare(stats,'dimension',[1 2]);

%%
figure()
for s_idx=1:model.n_states    
    for cond_idx=1:length(conditions)
        condition_trials = find(strcmp(data.metadata.condition,conditions{cond_idx}));
        LT_max=[];
        trial_cond=zeros(1,length(condition_trials));
        trial_state=zeros(1,length(condition_trials));
        for tc=1:length(condition_trials)
            if ~isempty(lifetime{s_idx,condition_trials(tc)})
                LT_max(end+1)=max(lifetime{s_idx,condition_trials(tc)});
            end
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

[p, tbl, stats]=anovan(LT_max_cond_state,{LT_max_state,LT_max_cond},'model','interaction',...
    'varnames',{'LT_max_state','LT_max_cond'});
results=multcompare(stats,'dimension',[1 2],'Display','on');


%%
figure()
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

[p, tbl, stats]=anovan(LT_sum_cond_state,{LT_sum_state,LT_sum_cond},'model','interaction',...
    'varnames',{'LT_sum_state','LT_sum_cond'});
results=multcompare(stats,'dimension',[1 2]);

%%
figure()
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

[p, tbl, stats]=anovan(ft_mat_cond_state,{ft_mat_state,ft_mat_cond},'model','interaction',...
    'varnames',{'ft_mat_state','ft_mat_cond'});
results=multcompare(stats,'dimension',[1 2]);

%%
figure()
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

[p, tbl, stats]=anovan(interval_mat_cond_state,{interval_mat_state,interval_mat_cond},'model','interaction',...
    'varnames',{'interval_mat_state','interval_mat_cond'});
results=multcompare(stats,'dimension',[1 2]);

%%
figure()
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

[p, tbl, stats]=anovan(blip_mat_cond_state,{blip_mat_state,blip_mat_cond},'model','interaction',...
    'varnames',{'blip_mat_state','blip_mat_cond'});
results=multcompare(stats,'dimension',[1 2]);

