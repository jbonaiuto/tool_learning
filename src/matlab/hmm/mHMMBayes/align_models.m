function model2=align_models(model1, model2, metric, variable)

% Get number of states
n_states1=model1.n_states;
n_states2=model2.n_states;

% Extra states that were added to new_model
extra_states_added=[];

% If there are fewer states in new_model, add some empty states at the end
if n_states2<n_states1
    extra_states_added=[n_states2+1:n_states1];

    % Create new transition prob matrix, initialize first entries with
    % transition probs from new_model and the rest with zeros
    new_model2_trans_mat=zeros(n_states1, n_states1);
    new_model2_trans_mat(1:n_states2, 1:n_states2)=model2.trans_mat;
    model2.trans_mat=new_model2_trans_mat;
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
    permuted_model2_trans_mat=model2.trans_mat(I(i,:),I(i,:));
        
    % Model 1 transition probability and emission probability matrices
    orig_trans_mat=model1.trans_mat;
    
%     % Set diagonals of transition probability matrices to 0
%     permutedESTTR=permutedESTTR-diag(diag(permutedESTTR));
%     origESTR=origESTR-diag(diag(origESTR));
    
    % Compute adjacency matrices
    origA=zeros(size(orig_trans_mat));
    permutedA=zeros(size(permuted_model2_trans_mat));
    % For each state
    for j=1:n_states1
        projections1=orig_trans_mat(j,:);
        projections2=permuted_model2_trans_mat(j,:);
        k1=find(projections1>1e-6);
        k2=find(projections2>1e-6);
        % Add them to the adjacency matrix
        origA(j,k1)=1;
        permutedA(j,k2)=1;
    end

    %euclidean 
    if strcmp(metric,'euclidean')
        if strcmp(variable,'TR')
            metric_values(i)=norm(permuted_model2_trans_mat - orig_trans_mat,'fro');
        elseif strcmp(variable,'A')
            metric_values(i)=norm(permutedA - origA,'fro');
        end
    %manhattan
    elseif strcmp(metric, 'manhattan')
        if strcmp(variable,'TR')
            metric_values(i)=norm(permuted_model2_trans_mat-orig_trans_mat,1);
        elseif strcmp(variable,'A')
            metric_values(i)=norm(permutedA-origA,1);
        end
    %Pearson correlation
    elseif strcmp(metric, 'pearson')
        if strcmp(variable,'TR')
            metric_values(i)=corr(permuted_model2_trans_mat(:),orig_trans_mat(:));
        elseif strcmp(variable,'A')
            metric_values(i)=corr(permutedA(:),origA(:));
        end    
    %Spearman correlation
    elseif strcmp(metric, 'spearman')
        if strcmp(variable,'TR')
            metric_values(i)=corr(permuted_model2_trans_mat(:),orig_trans_mat(:), 'Type', 'Spearman');    
        elseif strcmp(variable,'A')
            metric_values(i)=corr(permutedA(:),origA(:), 'Type', 'Spearman');  
        end
    %cosinus similarity
    elseif strcmp(metric, 'cosine')
        if strcmp(variable,'TR')
            metric_values(i) = getCosineSimilarity(permuted_model2_trans_mat(:),orig_trans_mat(:));
        elseif strcmp(variable,'A')
            metric_values(i) = getCosineSimilarity(permutedA(:),origA(:));
        end    
    %Covariance
    elseif strcmp(metric, 'covar')
        if strcmp(variable,'TR')
            m=cov(permuted_model2_trans_mat,orig_trans_mat);
            metric_values(i)=m(1,2);
        elseif strcmp(variable,'A')
            m=cov(permutedA,origA);
            metric_values(i)=m(1,2);
        end
    %jaccard index
    elseif strcmp(metric, 'jaccard')
        if strcmp(variable,'TR')
            metric_values(i) = 1 - sum(permuted_model2_trans_mat & orig_trans_mat)/sum(permuted_model2_trans_mat | orig_trans_mat);
        elseif strcmp(variable,'A')
            metric_values(i) = 1 - sum(permutedA & origA)/sum(permutedA | origA);
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

old_state_labels=model2.metadata.state_labels;
% Store maximum state label to rename extra states
max_state_label=-Inf;
% Rename states
for i=1:length(model2.metadata.state_labels)
    if length(find(permutedStates==i))
        model2.metadata.state_labels{i}=model1.metadata.state_labels{find(permutedStates==i)};
        if str2num(model2.metadata.state_labels{i})>max_state_label
            max_state_label=max([max_state_label str2num(model2.metadata.state_labels{i})]);
        end
    end
end
% If there are more states in new_model - find the ones not used in the
% permutation
for i=1:length(model2.metadata.state_labels)
    if length(find(permutedStates==i))==0
        model2.metadata.state_labels{i}=num2str(max_state_label+1);
        max_state_label=max_state_label+1;
    end
end

% Remove any extra states that were added just to make the algorithm work
if length(extra_states_added)>0
    keep_idx=setdiff([1:n_states2], find(strcmp(old_state_labels,'')));
    model2.metadata.state_labels=model2.metadata.state_labels(keep_idx);
    model2.trans_mat=model2.trans_mat(keep_idx,keep_idx);
end
