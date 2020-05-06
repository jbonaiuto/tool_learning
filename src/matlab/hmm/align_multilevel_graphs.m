%%file align_graphs.m
function model2=align_multilevel_graphs(model1, model2, metric, variable)

n_states1=size(model1.ESTTR,1);
n_states2=size(model2.ESTTR,1);
n_neurons=size(model2.GLOBAL_ESTEMIT,2);
n_days=size(model2.DAY_ESTEMIT,1);
remove_extra=[];
% If there are fewer states in model2, add some empty states at the end
if n_states2<n_states1
    remove_extra=[n_states2+1:n_states1];

    newESTTR=zeros(n_states1, n_states1);
    newESTTR(1:n_states2, 1:n_states2)=model2.ESTTR;
    model2.ESTTR=newESTTR;
    model2.GLOBAL_ESTEMIT(n_states2+1:n_states1, :)=zeros(n_states1-n_states2, n_neurons);
    model2.DAY_ESTEMIT(:,n_states2+1:n_states1, :)=zeros(n_days,n_states1-n_states2, n_neurons);
    for i=1:1<n_states1-n_states2
        model2.state_labels{end+1}='';
    end
    n_states2=n_states1;
end

[M,I]=npermutek([1:n_states2], n_states1);
n=size(I,1);

metric_values=zeros(1,n);

for i=1:n
    permutedESTTR=model2.ESTTR(I(i,:),I(i,:));
    permutedESTEMIT=model2.GLOBAL_ESTEMIT(I(i,:),:)+squeeze(mean(model2.DAY_ESTEMIT(:,I(i,:),:)));
    origESTR=model1.ESTTR;
    origESTEMIT=model1.GLOBAL_ESTEMIT+squeeze(mean(model1.DAY_ESTEMIT));

    % Set diagonals to 0
    permutedESTTR=permutedESTTR-diag(diag(permutedESTTR));
    origESTR=origESTR-diag(diag(origESTR));
    
    % Compute adjacency matrices
    origA=zeros(size(origESTR));
    permutedA=zeros(size(permutedESTTR));
    % For each state
    for j=1:n_states1
        projections1=model1.ESTTR(j,:);
        projections2=permutedESTTR(j,:);
        k1=find(projections1>0.000001);
        k2=find(projections2>0.000001);
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
        end
    %manhattan
    elseif strcmp(metric, 'manhattan')
        if strcmp(variable,'EMIT')
            metric_values(i)=norm(permutedESTEMIT-origESTEMIT,1);
        elseif strcmp(variable,'TR')
            metric_values(i)=norm(permutedESTTR-origESTR,1);
        elseif strcmp(variable,'A')
            metric_values(i)=norm(permutedA-origA,1);
        end
    %Pearson correlation
    elseif strcmp(metric, 'pearson')
        if strcmp(variable,'EMIT')
            metric_values(i)=corr(permutedESTEMIT(:),origESTEMIT(:));
        elseif strcmp(variable,'TR')
            metric_values(i)=corr(permutedESTTR(:),origESTR(:));
        elseif strcmp(variable,'A')
            metric_values(i)=corr(permutedA(:),origA(:));
        end    
    %Spearman correlation
    elseif strcmp(metric, 'spearman')
        if strcmp(variable,'EMIT')
            metric_values(i)=corr(permutedESTEMIT(:),origESTEMIT(:),'Type', 'Spearman');
        elseif strcmp(variable,'TR')
            metric_values(i)=corr(permutedESTTR(:),origESTR(:), 'Type', 'Spearman');    
        elseif strcmp(variable,'A')
            metric_values(i)=corr(permutedA(:),origA(:), 'Type', 'Spearman');    
        end
    %cosinus similarity
    elseif strcmp(metric, 'cosine')
        if strcmp(variable,'EMIT')
            metric_values(i) = getCosineSimilarity(permutedESTEMIT(:),origESTEMIT(:));
        elseif strcmp(variable,'TR')
            metric_values(i) = getCosineSimilarity(permutedESTTR(:),origESTR(:));
        elseif strcmp(variable,'A')
            metric_values(i) = getCosineSimilarity(permutedA(:),origA(:));
        end    
    %Covariance
    elseif strcmp(metric, 'cosine')
        if strcmp(variable,'EMIT')
            m=cov(permutedESTEMIT,origESTEMIT);
            metric_values(i)=m(1,2);
        elseif strcmp(variable,'TR')
            m=cov(permutedESTTR,origESTR);
            metric_values(i)=m(1,2);
        elseif strcmp(variable,'A')
            m=cov(permutedA,origA);
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
        end
    end
end

%On cherche la permutation avec la plus grande/petite distance
if strcmp(metric,'euclidean') || strcmp(metric,'manhattan')
    [bestMetric,bestPermIdx]=min(metric_values);
else
    [bestMetric,bestPermIdx]=max(metric_values);
end

%Appliquer la permutation a la matrice de transition du modele 2 a 10 etats
permutedStates=I(bestPermIdx,:);

%on cherche les deux etats du modele 2 (10 etats) qui ne correspondent pas
%avec les etats du modele 1 (8 etats) afin de modifier le modele 2 en
%permutant ses etats des matrices d'emission et de transition mais en
%ajoutant a la fin les etats restants 
remainingStates=setdiff([1:n_states2],permutedStates);
old_state_labels=model2.state_labels;
model2.state_labels=model1.state_labels([permutedStates remainingStates]);

% Remove any extra states that were added just to make the algorithm work
if length(remove_extra)>0
    keep_idx=setdiff([1:n_states2], find(strcmp(old_state_labels,'')));
    model2.ESTTR=model2.ESTTR(keep_idx,keep_idx);
    model2.GLOBAL_ESTEMIT=model2.GLOBAL_ESTEMIT(keep_idx,:);
    model2.DAY_ESTEMIT=model2.DAY_ESTEMIT(:,keep_idx,:);
    model2.state_labels=model2.state_labels(keep_idx);
end