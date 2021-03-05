function rsa_population_single_trial(array_idx, data, conditions, align_evt, woi)

aligned_data=realign(data, align_evt);
filtered_data=filter_data(aligned_data);

binwidth=20;
bins=[woi(1):binwidth:woi(2)];
trial_resp=[];

for e_idx=1:32
    overall_trial_idx=1;
    for cond_idx=1:length(conditions)
        condition=conditions{cond_idx};
        condition_data_idx=find(strcmp(filtered_data.conditions,condition) & filtered_data.arrays==array_idx & filtered_data.electrodes==e_idx);
    
        condition_trials=filtered_data.trials(condition_data_idx);
        condition_spikes=filtered_data.spiketimes(condition_data_idx);
    
        unique_trials=unique(condition_trials);
        for t_idx=1:length(unique_trials)
            trial_spikes=condition_spikes(find(condition_trials==unique_trials(t_idx)));
            trial_hist=histc(trial_spikes,bins);
            trial_resp(overall_trial_idx,(e_idx-1)*length(bins)+1:e_idx*length(bins))=trial_hist;
            overall_trial_idx=overall_trial_idx+1;
        end
    end            
end

RDM=zeros(size(trial_resp,1),size(trial_resp,1));
for i=1:size(trial_resp,1)
   for j=1:size(trial_resp,1)
      % 1-correlation between condition i and condition j
      RDM(i,j)=1-corr(trial_resp(i,:)',trial_resp(j,:)','type','spearman');
   end
end

