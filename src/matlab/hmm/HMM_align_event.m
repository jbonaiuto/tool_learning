
%load('C:/Users/kirchher/project/tool_learning/data/HMM/betta/betta_stage1_F1_go.mat');

%dates={'26.02.19','27.02.19','28.02.19','01.03.19','05.03.19','07.03.19','08.03.19','13.03.19','14.03.19','15.03.19','18.03.19',...
    %'19.03.19','21.03.19','22.03.19','25.03.19''11.03.19','12.03.19','27.03.19','28.03.19','29.03.19',...
    %'01.04.19','02.04.19','03.04.19','05.04.19','08.04.19','09.04.19','10.04.19','11.04.19','12.04.19','15.04.19','16.04.19',...
    %'17.04.19','18.04.19','19.04.19','23.04.19','24.04.19','26.04.19','29.04.19','01.05.19','02.05.19','03.05.19','06.05.19',...
    %'07.05.19','09.05.19','10.05.19','13.05.19','15.05.19','16.05.19','17.05.19','20.05.19','21.05.19','22.05.19','23.05.19',...
    %'27.05.19'};
    %dates={'13.03.19','14.03.19','15.03.19','18.03.19','19.03.19','21.03.19'};%,'22.03.19','25.03.19','26.03.19'};
dates={'13.03.19'};
addpath('../spike_data_processing');
date_data={};
for i=1:length(dates)
    load(fullfile('C:\Users\kirchher\project\tool_learning\data\preprocessed_data\betta\binned',sprintf('fr_b_F1_%s_trial_start.mat',dates{i})));
    date_data{i}=datafr;
    clear('datafr');
end
data=concatenate_data(date_data, 'spike_times', false);
clear('date_data');
   
F1_trials = squeeze(data.binned_spikes(1,:,:,1:end-1));
motor_trials=find(strcmp(data.metadata.condition,'motor_grasp_right'));% | strcmp(data.metadata.condition,'motor_grasp_left') | strcmp(data.metadata.condition,'motor_grasp_center'));
%motor_trials=motor_trials(1:10);

% Cell array - each element will contain a vector - sequence for each trial
SEQ= {};

% Loop over each motor trial
for g = 1:length(motor_trials)
    motor_trials_idx = motor_trials(g);
    bin_idx=find((data.bins>=0) & (data.bins<data.metadata.reward(motor_trials_idx)));
    
    vec = [];
    for i = 1:length(bin_idx)
        x = find(F1_trials(:,motor_trials_idx,bin_idx(i)) == 1);
        if ~isempty(x)
            if length(x) == 1
                vec(i) = x;
            else
                rand_idx=randi(numel(x));
                vec(i)= x(rand_idx);
            end
        else
            vec(i) = 0;
        end
    end
    
    % Add vec to SEQ
    SEQ{end+1}=vec;
end

n_states=10;
n_state_possibilities=[2:10];
%n_state_possibilities=[2 3];
n_iter=10;
AIC_storing = zeros(length(n_state_possibilities),1);

ESTEMIT_statesequence_storing = {};
ESTTR_statesequence_storing ={};

models=[];
        
for n=1:length(n_state_possibilities)
    n_states=n_state_possibilities(n);
    disp(sprintf('Trying %d states',n_states));
    
    for t=1:n_iter
        
        % Initialize transition prob guess
        TRGUESS=[];
        for i=1:n_states
            for j=1:n_states
                if i==j %the diagonal
                    % random between .5 and 1, above 0.5 because it is the
                    % transition probability to stay in the same state.
                  
                    TRGUESS(i,j)= .5+rand()*.5;
                else
                    % random between 0 and .5
                    TRGUESS(i,j)=rand()*.5;
                end
            end
        end
        % Normalize so probabilities add to 1
        TRGUESS=TRGUESS./repmat(sum(TRGUESS,2),1,n_states);
        
        % Initialize emission prob guess
        EMITGUESS=[];
        for i=1:n_states
            state_emission=rand(1,33);
            % Normalize so probabilities add to 1
            state_emission=state_emission./sum(state_emission);
            EMITGUESS(i,:)=state_emission;
        end
        
        % Train model
        [ESTTR,ESTEMIT] = hmmtrain(SEQ,TRGUESS,EMITGUESS,'Symbols',[0:32]);
        
        all_log_likelihood=[];
        for k = 1:length(SEQ);
            [PSTATES,logpseq] = hmmdecode(SEQ{k},ESTTR,ESTEMIT,'Symbols',[0:32]);
            % add logpseq to all_log_likelihood
            all_log_likelihood(end+1) = logpseq;
        end
        % compute sum log likelihood
        sum_log_likelihood = sum(all_log_likelihood);
        
        models(n,t).n_states=n_states;
        models(n,t).TRGUESS=TRGUESS;
        models(n,t).EMITGUESS=EMITGUESS;
        models(n,t).ESTTR=ESTTR;
        models(n,t).ESTEMIT=ESTEMIT;
        models(n,t).sum_log_likelihood=sum_log_likelihood;                
    end
end
AIC_storing = zeros(length(n_state_possibilities),1);
maxLL_idx_storing = zeros(length(n_state_possibilities),1);
maxLL_storing = zeros(length(n_state_possibilities),1);
for n=1:length(n_state_possibilities)
    [LL,max_idx]=max([models(n,:).sum_log_likelihood]);
    n_states=n_state_possibilities(n);
    AIC=2*((33-1)*n_states+(n_states-1)*n_states)-(2*LL);
    maxLL_storing(n)=LL;
    maxLL_idx_storing(n)=max_idx;
    AIC_storing(n) = AIC;
end

aligned_pstates=zeros(500);
event_aligned=find(strcmp(data.metadata.event_types,'go'));

%event time for each trial
for n=1:length(motor_trials)
    event_time = data.metadata.go(n);
    event-bin = round(event_time);
    
     %bin_idx=find((data.bins>=0) & (data.bins<data.metadata.reward(motor_trials_idx)));
    
%indexing the event time (1 ms bins)

%take p_states from -/+250 bin

%add to the aligned_states matrix

f=figure();
subplot(2,1,1);
plot(n_state_possibilities,maxLL_storing);
xlabel('nstates');
ylabel('LL');
subplot(2,1,2);
plot(n_state_possibilities,AIC_storing);
xlabel('nstates');
ylabel('AIC');
saveas(f,fullfile('C:\Users\kirchher\project\tool_learning\output\figures\HMM\betta\stage1_F1_motor_grasp_AIC_maxLL\',['stage1_F1_motor_grasp_right_AIC_maxLL_AICtrheshold_13.03.19' '.png']));
saveas(f,fullfile('C:\Users\kirchher\project\tool_learning\output\figures\HMM\betta\stage1_F1_motor_grasp_AIC_maxLL\',['stage1_F1_motor_grasp_right_AIC_maxLL_AICtrheshold_13.03.19' '.eps']), 'epsc');

%[AIC_min,min_AIC_idx]=min(AIC_storing);
AIC_values=AIC_storing.' ;
delta_AIC=diff(AIC_values);
best_AIC_idx=find(delta_AIC>-3.22,1);


hmm_results=[];
hmm_results.dates=dates;
hmm_results.trials=motor_trials;
hmm_results.SEQ=SEQ;
hmm_results.n_state_possibilities=n_state_possibilities;
hmm_results.n_iter=n_iter;
hmm_results.n_states=n_state_possibilities(min_AIC_idx);
hmm_results.AIC_storing=AIC_storing;
hmm_results.maxLL_idx_storing=maxLL_idx_storing;
hmm_results.maxLL_storing=maxLL_storing;
hmm_results.models=models;
hmm_results.best_model_idx=[min_AIC_idx maxLL_idx_storing(min_AIC_idx)];

%save('C:/Users/kirchher/project/tool_learning/data/HMM/betta/betta_stage1_F1_go_hmm.mat','hmm_results');
save('C:\Users\kirchher\project\tool_learning\data\HMM\betta\motor_grasp_right\betta_stage1_F1_hmm_test_AICtrheshold_13.03.19','hmm_results');

% mult_state_trials=[];
% for i=1:length(SEQ)
%     STATES = hmmviterbi(SEQ{i},hmm_results.ESTTR,hmm_results.ESTEMIT,'Symbols',[0:32]);
%     unique_states=unique(STATES);
%     if length(unique_states)>1
%         disp(sprintf('Trial %d', i));
%         mult_state_trials(end+1)=i;
%     end
% end

