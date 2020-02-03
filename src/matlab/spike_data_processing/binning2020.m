tic;
load(['D:\Data\tool_learning\src\matlab\spike_data_processing\exp_info']);

% event_types: {'trial_start'  'fix_on'  'go'  'hand_mvmt_onset'  'tool_mvmt_onset'  'obj_contact'  'place'  'reward'}

evt='fix_on';

d=dir(['D:\Data\Tooltask\preprocessed_data\betta_todo\' '*.19'])
for i = 1:length(d)
    dateexp=d(i).name
    data=load_multiunit_data(exp_info, 'betta', {dateexp}, 'arrays', [1 2 3 4 5 6 ], 'electrodes',[1:32]);    
    evt_data=data.metadata.(evt);
    data_ali=realign(data,evt)
   % datamaxk(i,1:10)=maxk(data_ali.spikedata.time,10);    
     data_binned=bin_spikes(data_ali, [-1000 1000], 1, 'baseline_evt', 'go','baseline_woi', [-500 0]);
     datafr=compute_firing_rate(data_binned, 'baseline_type', 'condition','win_len', 6);
     save(['D:\Data\Tooltask\MultiUnit_new\fr_b_all_arrays_' dateexp '_' evt '.mat'],'datafr');
 end
toc;
%++++++++++++++++++++++++++++++++++++++++
% tic;
% load(['D:\Data\tool_learning\src\matlab\spike_data_processing\exp_info']);
% 
% % event_types: {'trial_start'  'fix_on'  'go'  'hand_mvmt_onset'  'tool_mvmt_onset'  'obj_contact'  'place'  'reward'}
% 
% evt='trial_start';
% arraysname={'F1'  'F5hand'  'F5mouth'  '46v-12r'  '45A'  'F2'};
% 
% 
% d=dir(['D:\Data\Tooltask\preprocessed_data\betta_todo\' '*.19']);
% for i = 1:length(d)
%     for j=1:6
%     dateexp=d(i).name
%     data=load_multiunit_data(exp_info, 'betta', {dateexp}, 'arrays', j, 'electrodes',[1:32]);    
%     evt_data=data.metadata.(evt);
%     data_ali=realign(data,evt)
%    % datamaxk(i,1:10)=maxk(data_ali.spikedata.time,10);    
%      data_binned=bin_spikes(data_ali, [-1000 10000], 1, 'baseline_evt', 'go','baseline_woi', [-500 0]);
%      datafr=compute_firing_rate(data_binned, 'baseline_type', 'condition','win_len', 6);
%      save(['D:\Data\Tooltask\MultiUnit_new\fr_b_' arraysname{j} '_' dateexp '_' evt '.mat'],'datafr');
%     end
% end
% toc;