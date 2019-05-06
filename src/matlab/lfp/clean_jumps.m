function clean_chan_data=clean_jumps(chan_data)

chan_diff=diff(chan_data);
[jumps,residual] = findchangepts(chan_data,'Statistic','mean','MinThreshold',50000,'MinDistance',100);

clean_chan_data=chan_data;
if length(jumps)>0
    % Mean of signal 100 time steps before first jump
    last_seg_mean = mean(clean_chan_data(max(1,jumps(1)-100):jumps(1)));
    for i = 1 : length(jumps)-1
        % Mean of signal 100 time steps after current jump
        curr_seg_mean=mean(clean_chan_data(jumps(i):min(jumps(i)+100,length(clean_chan_data))));
        clean_chan_data(jumps(i):jumps(i+1)) = clean_chan_data(jumps(i):jumps(i+1)) - (curr_seg_mean-last_seg_mean);
        last_seg_mean=mean(clean_chan_data(max(1,jumps(i+1)-100):jumps(i+1)));
    end
    curr_seg_mean=mean(clean_chan_data(jumps(end):min(jumps(end)+100,length(clean_chan_data))));
    clean_chan_data(jumps(end):end) = clean_chan_data(jumps(end):end) - (curr_seg_mean-last_seg_mean);
end


% If there are any jumps
% if length(jumps)>0
%     figure();
%     subplot(2,1,1);
%     plot(chan_data);
%     hold on;
%     for j=1:length(jumps)
%         plot([jumps(j) jumps(j)],ylim(),'r');
%     end
%     subplot(2,1,2);
%     plot(clean_chan_data);
%     disp('');
% else
%     figure();
%     subplot(2,1,1);
%     plot(chan_data);
% end          
% disp('');