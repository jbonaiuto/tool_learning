function cluster_coords=cluster_within_region(x, y, n_clusters)

% K-means cluster
[IDX,C] = kmeans([x,y],n_clusters);
% Find size of each cluster
cluster_sizes=[];
for i=1:n_clusters
    cluster_sizes(i)=length(find(IDX==i));
end
% Find max cluster size
[max_cluster_size,max_cluster_idx]=max(cluster_sizes);
% Get x,y data in max cluster
max_cluster_x=x(IDX==max_cluster_idx);
max_cluster_y=y(IDX==max_cluster_idx);
% Exclude outliers
orig_cluster_coords=filter_gaze_data_outliers(max_cluster_x, max_cluster_y);
% Get 30 data points closest to centroid
dists=sqrt((orig_cluster_coords(:,1)-C(max_cluster_idx,1)).^2+(orig_cluster_coords(:,2)-C(max_cluster_idx,2)).^2);
[sorted_dists,sorted_idx]=sort(dists);
cluster_coords=orig_cluster_coords(sorted_idx,:);