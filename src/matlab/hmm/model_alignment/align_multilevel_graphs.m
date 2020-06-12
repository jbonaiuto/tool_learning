%%file align_graphs.m
function [model2,bestMetric]=align_multilevel_graphs(exp_info, model1, model2,...
    model1_dates, model2_dates, metric, variable)

if strcmp(variable,'PSTATES')
    % Get the aligned state probabilities
    % 4D vector - trials x states x epochs x time bins
    addpath('..');
    aligned_p_states1=plotHMM_aligned(exp_info, 'betta', model1_dates,...
        'F1', {'motor_grasp_right'}, model1);
    close(gcf());
    aligned_p_states2=plotHMM_aligned(exp_info, 'betta', model2_dates,...
        'F1', {'motor_grasp_right'}, model2);
    close(gcf());
    rmpath('..');

    % Average over trials: states x epochs x time bins
    mean_pstates1=squeeze(nanmean(aligned_p_states1));
    mean_pstates2=squeeze(nanmean(aligned_p_states2));

    % Reshape into state x all time bins
    mean_pstates1=reshape(permute(mean_pstates1,[1 3 2]),...
        size(mean_pstates1,1),size(mean_pstates1,2)*size(mean_pstates1,3));
    mean_pstates2=reshape(permute(mean_pstates2,[1 3 2]),...
        size(mean_pstates2,1),size(mean_pstates2,2)*size(mean_pstates2,3));

    % Normalize
    for i=1:size(mean_pstates1,1)
        mean_pstates1(i,:)=mean_pstates1(i,:)./max(mean_pstates1(i,:));
    end
    for i=1:size(mean_pstates2,1)
        mean_pstates2(i,:)=mean_pstates2(i,:)./max(mean_pstates2(i,:));
    end
end

% Get number of states, neurons, and days
n_states1=size(model1.ESTTR,1);
n_states2=size(model2.ESTTR,1);
n_neurons=size(model2.GLOBAL_ESTEMIT,2);
n_days=size(model2.DAY_ESTEMIT,1);

% Extra states that were added to model2
extra_states_added=[];

% If there are fewer states in model2, add some empty states at the end
if n_states2<n_states1
    extra_states_added=[n_states2+1:n_states1];

    % Create new transition prob matrix, initialize first entries with
    % transition probs from model2 and the rest with zeros
    newESTTR=zeros(n_states1, n_states1);
    newESTTR(1:n_states2, 1:n_states2)=model2.ESTTR;
    model2.ESTTR=newESTTR;
    
    % Add zeros to end of emission probability matrices
    model2.GLOBAL_ESTEMIT(n_states2+1:n_states1, :)=zeros(n_states1-n_states2, n_neurons);
    model2.DAY_ESTEMIT(:,n_states2+1:n_states1, :)=zeros(n_days,n_states1-n_states2, n_neurons);
    
    % Add extra state labels (blank)
    for i=1:1<n_states1-n_states2
        model2.state_labels{end+1}='';
    end
    
    % Add extra states to mean_pstates2
    if strcmp(variable,'PSTATES')
        mean_pstates2(n_states2+1:n_states1,:,:)=zeros(n_states1-n_states2,...
            size(mean_pstates1,2), size(mean_pstates1,3));
    end
    n_states2=n_states1;
end

% Get all possible permutations of model2 states
[M,I]=npermutek([1:n_states2], n_states1);
% Number of permutations
n=size(I,1);

% Value of metric for each permutation
metric_values=zeros(1,n);

% For each permutation
for i=1:n
    % Permute model 2 transition probability and emission probability
    % matrices
    permutedESTTR=model2.ESTTR(I(i,:),I(i,:));
    % Average over days
    permutedESTEMIT=model2.GLOBAL_ESTEMIT(I(i,:),:)+squeeze(mean(model2.DAY_ESTEMIT(:,I(i,:),:)));
    
    % Permuted model 2 PSTATES
    if strcmp(variable,'PSTATES')
        permutedPSTATES=mean_pstates2(I(i,:),:,:);
        origPSTATES=mean_pstates1;
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

old_state_labels=model2.state_labels;
% Store maximum state label to rename extra states
max_state_label=-Inf;
% Rename states
for i=1:length(model2.state_labels)
    if length(find(permutedStates==i))
        model2.state_labels{i}=model1.state_labels{find(permutedStates==i)};
        if str2num(model2.state_labels{i})>max_state_label
            max_state_label=max([max_state_label str2num(model2.state_labels{i})]);
        end
    end
end
% If there are more states in model2 - find the ones not used in the
% permutation
for i=1:length(model2.state_labels)
    if length(find(permutedStates==i))==0
        model2.state_labels{i}=num2str(max_state_label+1);
        max_state_label=max_state_label+1;
    end
end

% Remove any extra states that were added just to make the algorithm work
if length(extra_states_added)>0
    keep_idx=setdiff([1:n_states2], find(strcmp(old_state_labels,'')));
    model2.state_labels=model2.state_labels(keep_idx);
    model2.ESTTR=model2.ESTTR(keep_idx,keep_idx);
    model2.GLOBAL_ESTEMIT=model2.GLOBAL_ESTEMIT(keep_idx,:);
    model2.DAY_ESTEMIT=model2.DAY_ESTEMIT(:,keep_idx,:);    
end