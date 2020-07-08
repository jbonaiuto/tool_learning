%%file align_graphs.m
% prev_models = array of strucutres [model1, model2, model3, ....] with the last being
%               the most recent. All must already be aligned
% new_model = new model to align
% prev_model_dates = cell array of cell arrays - dates for each model. For example:
%                    {{'13.03.19','14.03.19','15.03.19'}, {'19.03.19','21.03.19','22.03.19'}};
% new_model_dates = cell array of cell arrays - dates for new model {'27.03.19','28.03.19','29.03.19'}
function [new_model,bestMetric]=align_multilevel_graphs(exp_info, prev_models, new_model,...
    prev_model_dates, new_model_dates, metric, variable)

if strcmp(variable,'PSTATES')
    % Get the aligned state probabilities
    % 4D vector - trials x states x epochs x time bins
    addpath('..');
    addpath('../../spike_data_processing');
    prev_aligned_p_states={};
    mean_prev_pstates={};
    % Go through each prev model and get the aligned state probabilities
    for i=1:length(prev_models)
        prev_aligned_p_states{i}=plotHMM_aligned(exp_info, 'betta', prev_model_dates{i},...
            'F1', {'motor_grasp_right'}, prev_models(i));
        close(gcf());
        mean_prev_pstates{i}=squeeze(nanmean(prev_aligned_p_states{i},1));
    end
    new_aligned_p_states=plotHMM_aligned(exp_info, 'betta', new_model_dates,...
        'F1', {'motor_grasp_right'}, new_model);
    close(gcf());
    rmpath('..');

    % Average over trials: states x epochs x time bins    
    mean_new_pstates=squeeze(nanmean(new_aligned_p_states,1));

    % Get aligned p_states for last model (i.e. mean_prev_pstates(end,:,:,:,:))
    last_prev_pstates=mean_prev_pstates{end};

    % Go through each model before the last (from i=1:size(prev_aligned_p_states,1)-1 )
    % Find states (using state_labels) that are not in the last model
    missing_states={};
    num_states_added=0;
    for i=1:length(prev_models)-1
        states=prev_models(i).state_labels;
        missing=setdiff(setdiff(states,prev_models(end).state_labels),missing_states);
        missing_states(end+1:end+length(missing))=missing(:);
        
        for j=1:length(missing)
            state_idx=find(strcmp(prev_models(i).state_labels,missing{j}));
            % Append the mean state probabilties for these states to aligned p_states for the last model
            last_prev_pstates(end+1,:,:)=mean_prev_pstates{i}(state_idx,:,:);
            % Add these state labels to the state labels in the last model so that they can be matched
            % to the new model
            prev_models(end).state_labels{end+1}=missing{j};
            num_states_added=num_states_added+1;
        end
    end
    newESTTR=zeros(size(prev_models(end).ESTTR,1)+num_states_added, size(prev_models(end).ESTTR,2)+num_states_added);
    newESTTR(1:size(prev_models(end).ESTTR,1), 1:size(prev_models(end).ESTTR,2))=prev_models(end).ESTTR;
    prev_models(end).ESTTR=newESTTR;
    
    
    % Reshape into state x all time bins
    mean_prev_pstates=reshape(permute(last_prev_pstates,[1 3 2]),...
        size(last_prev_pstates,1),size(last_prev_pstates,2)*size(last_prev_pstates,3));
    % Change these to be the new mean state probabilities for the last model with the states that have
    % been disappeared added
    mean_new_pstates=reshape(permute(mean_new_pstates,[1 3 2]),...
        size(mean_new_pstates,1),size(mean_new_pstates,2)*size(mean_new_pstates,3));

    % Normalize
    for i=1:size(mean_prev_pstates,1)
        mean_prev_pstates(i,:)=mean_prev_pstates(i,:)./max(mean_prev_pstates(i,:));
    end
    for i=1:size(mean_new_pstates,1)
        mean_new_pstates(i,:)=mean_new_pstates(i,:)./max(mean_new_pstates(i,:));
    end
end

% Last previous model
model1=prev_models(end);

% Get number of states, neurons, and days
n_states1=length(model1.state_labels);
n_states2=size(new_model.ESTTR,1);
n_neurons=size(new_model.GLOBAL_ESTEMIT,2);
n_days=size(new_model.DAY_ESTEMIT,1);

% Extra states that were added to new_model
extra_states_added=[];

% If there are fewer states in new_model, add some empty states at the end
if n_states2<n_states1
    extra_states_added=[n_states2+1:n_states1];

    % Create new transition prob matrix, initialize first entries with
    % transition probs from new_model and the rest with zeros
    newESTTR=zeros(n_states1, n_states1);
    newESTTR(1:n_states2, 1:n_states2)=new_model.ESTTR;
    new_model.ESTTR=newESTTR;
    
    % Add zeros to end of emission probability matrices
    new_model.GLOBAL_ESTEMIT(n_states2+1:n_states1, :)=zeros(n_states1-n_states2, n_neurons);
    new_model.DAY_ESTEMIT(:,n_states2+1:n_states1, :)=zeros(n_days,n_states1-n_states2, n_neurons);
    
    % Add extra state labels (blank)
    for i=1:n_states1-n_states2
        new_model.state_labels{end+1}='';
    end
    
    % Add extra states to mean_new_pstates
    if strcmp(variable,'PSTATES')
        mean_new_pstates(n_states2+1:n_states1,:,:)=zeros(n_states1-n_states2,...
            size(mean_prev_pstates,2), size(mean_prev_pstates,3));
    end
    n_states2=n_states1;
end

% Get all possible permutations of new_model states
[M,I]=npermutek([1:n_states2], n_states1);
% Number of permutations
n=size(I,1);

% Value of metric for each permutation
metric_values=zeros(1,n);

% For each permutation
for i=1:n
    % Permute model 2 transition probability and emission probability
    % matrices
    permutedESTTR=new_model.ESTTR(I(i,:),I(i,:));
    % Average over days
    permutedESTEMIT=new_model.GLOBAL_ESTEMIT(I(i,:),:)+squeeze(mean(new_model.DAY_ESTEMIT(:,I(i,:),:)));
    
    % Permuted model 2 PSTATES
    if strcmp(variable,'PSTATES')
        permutedPSTATES=mean_new_pstates(I(i,:),:,:);
        origPSTATES=mean_prev_pstates;
    end
    
    % Model 1 transition probability and emission probability matrices
    origESTR=model1.ESTTR;
    % Average over days
    origESTEMIT=model1.GLOBAL_ESTEMIT+squeeze(mean(model1.DAY_ESTEMIT));

    % Set diagonals of transition probability matrices to 0
    permutedESTTR=permutedESTTR-diag(diag(permutedESTTR));
    origESTR=origESTR-diag(diag(origESTR));
    
    % Compute adjacency matrices
    origA=zeros(size(origESTR));
    permutedA=zeros(size(permutedESTTR));
    % For each state
    for j=1:n_states1
        projections1=model1.ESTTR(j,:);
        projections2=permutedESTTR(j,:);
        k1=find(projections1>1e-6);
        k2=find(projections2>1e-6);
        % Add them to the adjacency matrix
        origA(j,k1)=1;
        permutedA(j,k2)=1;
    end

    %euclidean 
    if strcmp(metric,'euclidean')
        if strcmp(variable,'EMIT')
            metric_values(i)=norm(permutedESTEMIT - origESTEMIT,'fro');
        elseif strcmp(variable,'TR')
            metric_values(i)=norm(permutedESTTR - origESTR,'fro');
        elseif strcmp(variable,'A')
            metric_values(i)=norm(permutedA - origA,'fro');
        elseif strcmp(variable,'PSTATES')
            metric_values(i)=norm(permutedPSTATES - origPSTATES,'fro');
        end
    %manhattan
    elseif strcmp(metric, 'manhattan')
        if strcmp(variable,'EMIT')
            metric_values(i)=norm(permutedESTEMIT-origESTEMIT,1);
        elseif strcmp(variable,'TR')
            metric_values(i)=norm(permutedESTTR-origESTR,1);
        elseif strcmp(variable,'A')
            metric_values(i)=norm(permutedA-origA,1);
        elseif strcmp(variable,'PSTATES')
            metric_values(i)=norm(permutedPSTATES-origPSTATES,1);
        end
    %Pearson correlation
    elseif strcmp(metric, 'pearson')
        if strcmp(variable,'EMIT')
            metric_values(i)=corr(permutedESTEMIT(:),origESTEMIT(:));
        elseif strcmp(variable,'TR')
            metric_values(i)=corr(permutedESTTR(:),origESTR(:));
        elseif strcmp(variable,'A')
            metric_values(i)=corr(permutedA(:),origA(:));
        elseif strcmp(variable,'PSTATES')
            metric_values(i)=corr(permutedPSTATES(:),origPSTATES(:));
        end    
    %Spearman correlation
    elseif strcmp(metric, 'spearman')
        if strcmp(variable,'EMIT')
            metric_values(i)=corr(permutedESTEMIT(:),origESTEMIT(:),'Type', 'Spearman');
        elseif strcmp(variable,'TR')
            metric_values(i)=corr(permutedESTTR(:),origESTR(:), 'Type', 'Spearman');    
        elseif strcmp(variable,'A')
            metric_values(i)=corr(permutedA(:),origA(:), 'Type', 'Spearman');  
        elseif strcmp(variable,'PSTATES')
            metric_values(i)=corr(permutedPSTATES(:),origPSTATES(:), 'Type', 'Spearman');  
        end
    %cosinus similarity
    elseif strcmp(metric, 'cosine')
        if strcmp(variable,'EMIT')
            metric_values(i) = getCosineSimilarity(permutedESTEMIT(:),origESTEMIT(:));
        elseif strcmp(variable,'TR')
            metric_values(i) = getCosineSimilarity(permutedESTTR(:),origESTR(:));
        elseif strcmp(variable,'A')
            metric_values(i) = getCosineSimilarity(permutedA(:),origA(:));
        elseif strcmp(variable,'PSTATES')
            metric_values(i) = getCosineSimilarity(permutedPSTATES(:),origPSTATES(:));
        end    
    %Covariance
    elseif strcmp(metric, 'covar')
        if strcmp(variable,'EMIT')
            m=cov(permutedESTEMIT,origESTEMIT);
            metric_values(i)=m(1,2);
        elseif strcmp(variable,'TR')
            m=cov(permutedESTTR,origESTR);
            metric_values(i)=m(1,2);
        elseif strcmp(variable,'A')
            m=cov(permutedA,origA);
            metric_values(i)=m(1,2);
        elseif strcmp(variable,'PSTATES')
            m=cov(permutedPSTATES,origPSTATES);
            metric_values(i)=m(1,2);
        end
    %jaccard index
    elseif strcmp(metric, 'jaccard')
        if strcmp(variable,'EMIT')
            metric_values(i) = 1 - sum(permutedESTEMIT & origESTEMIT)/sum(permutedESTEMIT | origESTEMIT);
        elseif strcmp(variable,'TR')
            metric_values(i) = 1 - sum(permutedESTTR & origESTR)/sum(permutedESTTR | origESTR);
        elseif strcmp(variable,'A')
            metric_values(i) = 1 - sum(permutedA & origA)/sum(permutedA | origA);
        elseif strcmp(variable,'PSTATES')
            metric_values(i) = 1 - sum(permutedPSTATES & origPSTATES)/sum(permutedPSTATES | origPSTATES);
        end
    end
end

% Get the best metric - minimum if euclidean or manhattan distance, maximum
% otherwise
if strcmp(metric,'euclidean') || strcmp(metric,'manhattan')
    [bestMetric,bestPermIdx]=min(metric_values);
else
    [bestMetric,bestPermIdx]=max(metric_values);
end

% Get the order of states in the best permutation
permutedStates=I(bestPermIdx,:);

old_state_labels=new_model.state_labels;
% Store maximum state label to rename extra states
max_state_label=-Inf;
% Rename states
for i=1:length(new_model.state_labels)
    if length(find(permutedStates==i))
        new_model.state_labels{i}=model1.state_labels{find(permutedStates==i)};
        if str2num(new_model.state_labels{i})>max_state_label
            max_state_label=max([max_state_label str2num(new_model.state_labels{i})]);
        end
    end
end
% If there are more states in new_model - find the ones not used in the
% permutation
for i=1:length(new_model.state_labels)
    if length(find(permutedStates==i))==0
        new_model.state_labels{i}=num2str(max_state_label+1);
        max_state_label=max_state_label+1;
    end
end

% Remove any extra states that were added just to make the algorithm work
if length(extra_states_added)>0
    keep_idx=setdiff([1:n_states2], find(strcmp(old_state_labels,'')));
    new_model.state_labels=new_model.state_labels(keep_idx);
    new_model.ESTTR=new_model.ESTTR(keep_idx,keep_idx);
    new_model.GLOBAL_ESTEMIT=new_model.GLOBAL_ESTEMIT(keep_idx,:);
    new_model.DAY_ESTEMIT=new_model.DAY_ESTEMIT(:,keep_idx,:);    
end
