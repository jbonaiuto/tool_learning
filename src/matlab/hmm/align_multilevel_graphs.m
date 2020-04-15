%%file align_graphs.m
function model2=align_multilevel_graphs(model1, model2)

n_states1=size(model1.ESTTR,1);
n_states2=size(model2.ESTTR,1);
n_neurons=size(model2.GLOBAL_ESTEMIT,2);
n_days=size(model2.DAY_ESTEMIT,1);

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
correlation=zeros(1,n);
for i=1:n
    permutedESTTR=model2.ESTTR(I(i,:),I(i,:));
    permutedESTEMIT=model2.GLOBAL_ESTEMIT(I(i,:),:)+squeeze(mean(model2.DAY_ESTEMIT(:,I(i,:),:)));
    origESTR=model1.ESTTR;
    origESTEMIT=model1.GLOBAL_ESTEMIT+squeeze(mean(model1.DAY_ESTEMIT));
    %correlation(i)=norm(permutedESTTR - origESTR);
    correlation(i)=norm(permutedESTEMIT - origESTEMIT);
    %correlation(i)=mean([norm(permutedESTTR - origESTR) norm(permutedESTEMIT - origESTEMIT)]);
    %correlation(i)=corr2(permutedESTTR, model1.ESTTR);
    %correlation(i)=corr2(permutedESTEMIT, model1.GLOBAL_ESTEMIT+squeeze(mean(model1.DAY_ESTEMIT)));
    %correlation(i)=mean([corr2(permutedESTTR, model1.ESTTR) corr2(permutedESTEMIT, model1.GLOBAL_ESTEMIT)]);
%     correlation(i)=mean([corr2(permutedESTTR, model1.ESTTR) corr2(permutedESTEMIT, model1.GLOBAL_ESTEMIT+squeeze(mean(model1.DAY_ESTEMIT)))]);
end

%On cherche la permutation avec la plus grande correlation
[maxCorr,bestPermIdx]=max(correlation);

%Appliquer la permutation a la matrice de transition du modele 2 a 10 etats
permutedStates=I(bestPermIdx,:);

%on cherche les deux etats du modele 2 (10 etats) qui ne correspondent pas
%avec les etats du modele 1 (8 etats) afin de modifier le modele 2 en
%permutant ses etats des matrices d'emission et de transition mais en
%ajoutant a la fin les etats restants 
remainingStates=setdiff([1:n_states2],permutedStates);
%model2.ESTTR=model2.ESTTR([permutedStates remainingStates],[permutedStates remainingStates]);
%model2.GLOBAL_ESTEMIT=model2.GLOBAL_ESTEMIT([permutedStates remainingStates],:);
%model2.DAY_ESTEMIT=model2.DAY_ESTEMIT(:,[permutedStates remainingStates],:);
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
