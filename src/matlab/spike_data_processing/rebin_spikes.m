function data=rebin_spikes(data, newbinwidth)
% REBIN_SPIKES Re-bin already binned spike data using a new bin width
%
% Syntax: data=rebin_spikes(data, newbinwidth)
%
% Inputs:
%    data - data object containing binned spike data
%    newbinwidth - new bin width to use
%
% Outputs:
%    data - data structure containing re-binned data
% 
% Example:
%     data=rebin_spikes(data, 10);

% Check if already binned
if ~isfield(data,'bins') || ~isfield(data,'baseline_bins') || ~isfield(data,'binned_spikes') || ~isfield(data,'binned_baseline_spikes')
    error('Data must already be binned!');
end

oldbinwidth=data.bins(2)-data.bins(1);

if mod(newbinwidth,oldbinwidth)~=0
    error('New bin width must be a multiple of old bin width - if not, rebin from scratch!');
end

bin_factor=round(newbinwidth/oldbinwidth);

new_bins=data.bins(1:bin_factor:end);
new_baseline_bins=data.baseline_bins(1:bin_factor:end);

n_arrays=size(data.binned_spikes,1);
n_chans=size(data.binned_spikes,2);
n_trials=size(data.binned_spikes,3);

new_binned_spikes=reshape(data.binned_spikes(:,:,:,1:end-1), n_arrays,...
    n_chans, n_trials, bin_factor, length(new_bins)-1);
new_binned_spikes=reshape(sum(new_binned_spikes,4), n_arrays, n_chans,...
    n_trials, size(new_binned_spikes,5));
new_binned_spikes(:,:,:,end+1)=data.binned_spikes(:,:,:,end);

new_binned_baseline_spikes=reshape(data.binned_baseline_spikes(:,:,:,1:end-1),...
    n_arrays, n_chans, n_trials, bin_factor, length(new_baseline_bins)-1);
new_binned_baseline_spikes=reshape(sum(new_binned_baseline_spikes,4), n_arrays, n_chans,...
    n_trials, size(new_binned_baseline_spikes,5));
new_binned_baseline_spikes(:,:,:,end+1)=data.binned_baseline_spikes(:,:,:,end);

data.binwidth=newbinwidth;
data.bins=new_bins;
data.baseline_bins=new_baseline_bins;
data.binned_spikes=new_binned_spikes;
data.binned_baseline_spikes=new_binned_baseline_spikes;


