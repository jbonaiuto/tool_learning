function filtered_xy=filter_gaze_data_outliers(x, y)

filtered_xy(:,1)=x;
filtered_xy(:,2)=y;
removed=true;
while removed
    x_nonoutliers=(abs(filtered_xy(:,1)-median(filtered_xy(:,1)))<=2*std(filtered_xy(:,1)));
    y_nonoutliers=(abs(filtered_xy(:,2)-median(filtered_xy(:,2)))<=2*std(filtered_xy(:,2)));
    nonoutliers=x_nonoutliers & y_nonoutliers;
    if length(find(nonoutliers))<size(filtered_xy,1)
        filtered_xy=filtered_xy(nonoutliers,:);
    else
        removed=false;
    end
end