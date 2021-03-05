function clean_array_data=clean_jumps(array_data)

%[jumps,residual] = findchangepts(chan_data,'Statistic','linear','MinThreshold',50000,'MinDistance',50);
[jumps,residual] = findchangepts(mean(array_data),'Statistic','linear','MinThreshold',7000);

clean_array_data=array_data;
if length(jumps)>0
    for ch_idx=1:size(clean_array_data,1)
        chan_data=clean_array_data(ch_idx,:);
        
        % Mean of signal 100 time steps before first jump
        last_seg_mean = mean(chan_data(max(1,jumps(1)-100):jumps(1)));
        for i = 1 : length(jumps)-1
            % Mean of signal 100 time steps after current jump
            curr_seg_mean=mean(chan_data(jumps(i):min(jumps(i)+100,length(chan_data))));
            chan_data(jumps(i):jumps(i+1)) = chan_data(jumps(i):jumps(i+1)) - (curr_seg_mean-last_seg_mean);
            last_seg_mean=mean(chan_data(max(1,jumps(i+1)-100):jumps(i+1)));
        end
        curr_seg_mean=mean(chan_data(jumps(end):min(jumps(end)+100,length(chan_data))));
        chan_data(jumps(end):end) = chan_data(jumps(end):end) - (curr_seg_mean-last_seg_mean);

        % Get rid of jump removal artifact
        for i=1:length(jumps)
            chan_data(jumps(i)-1:min(length(chan_data),jumps(i)+1))=NaN;
        end
        nanx = isnan(chan_data);
        t    = 1:numel(chan_data);
        chan_data(nanx) = interp1(t(~nanx), chan_data(~nanx), t(nanx));
        clean_array_data(ch_idx,:)=chan_data;
    end
end


% If there are any jumps
figure();
subplot(3,1,1);
plot(mean(array_data));
hold on;
for j=1:length(jumps)
    plot([jumps(j) jumps(j)],ylim(),'r');
end
subplot(3,1,2);
plot(array_data');
hold on;
for j=1:length(jumps)
    plot([jumps(j) jumps(j)],ylim(),'r');
end
subplot(3,1,3);
plot(clean_array_data');
hold on;
for j=1:length(jumps)
    plot([jumps(j) jumps(j)],ylim(),'r');
end
disp('');