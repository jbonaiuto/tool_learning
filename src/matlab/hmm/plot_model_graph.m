%%file graph_model.m
function S=plot_model_graph(model)

n_states=size(model.ESTTR,1);

% Initialize adjacency matrix to be zeros
A=zeros(n_states, n_states);
% For each state
for i=1:n_states
    % find the projections from that state
    projections=model.ESTTR(i,:);
    % Find the two strongest projections
    j=find(projections>1e-6);
    % Add them to the adjacency matrix
    A(i,j)=1;
end

% State the node labels
NodeLabels=model.state_labels;

cols=cbrewer('qual','Paired',12);
NodeColors=zeros(n_states,3);
for i=1:n_states
    NodeColors(i,:)=cols(str2num(model.state_labels{i}),:);
end

n_edges=length(find(A(:)>0));

cmap = jet();
cmin=min(log(model.ESTTR(model.ESTTR>1e-6)));
cmax = 0;
EdgeColors=cell(n_edges,3);
idx=1;
for i=1:n_states
    for j=1:n_states
        if A(i,j)>0
            prob=log(model.ESTTR(i,j));
            index = fix((prob-cmin)/(cmax-cmin)*length(cmap))+1;
            RGB = cmap(index,:);
            EdgeColors(idx,:)={model.state_labels{i}, model.state_labels{j}, RGB};
            idx=idx+1;
        end
    end
end


S=graphViz4Matlab('-adjMat',A,'-nodeLabels',NodeLabels,'-layout',Circularlayout,...
    '-nodeColors',NodeColors,'-edgeColors', EdgeColors );
colormap('jet');
colorbar();
