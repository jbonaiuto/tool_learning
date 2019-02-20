function smooth_firing_rate=single_cell_firing_rate(data_file, cell_id, trial)

% size of bins in milliseconds
bin_width=20;
% width of the gaussian kernel
kernel_width=6;

data=readtable(data_file);
row_index=find(data.cell==cell_id & data.trial==trial);
spikes=data.time(row_index);
bins=[-1000:bin_width:2000];
bin_counts=histc(spikes,bins);
firing_rate=bin_counts*(1000/bin_width);
kernel=gausswin(kernel_width);
smooth_firing_rate=filter(kernel,1,firing_rate);
figure();
subplot(2,1,1);
bar(bins,firing_rate);
subplot(2,1,2);
plot(bins,smooth_firing_rate);

end