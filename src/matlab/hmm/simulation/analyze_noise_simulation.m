function analyze_noise_simulation()

load(fullfile('C:\Users\kirchher\project\tool_learning\output\HMM\betta\noise_simulation','noise_simulation_results_15levels_100trials_2.mat'));

noise_levels=[1:15];
loaded_nTrials=noise_simulation_results.params.nTrials;
nTrials=[1:loaded_nTrials];

for i=1:length(noise_simulation_results.trial_data)
    
    co_occuring=zeros(1,length(nTrials));
    multi_spikes=zeros(1,length(nTrials));
    
    for t=1:length(nTrials)
    
    trial_spikes=noise_simulation_results.trial_data{i}{t};
    nBins=size(trial_spikes,2);
    
        %find how many spikes occur simultaneously for each time bin.
        for j=1:nBins
            co_occuring(t)=co_occuring(t)+max([0, length(find(trial_spikes(:,j)>0))-1]);
        end
        
        %find how many neurons fire multiple times in a time bin.
        for j=1:nBins
            multi_spikes_neurons=find(trial_spikes(:,j)>1);
%            multi_spikes(t,j)=length(multi_spikes_neurons);
            multi_spikes(t)=multi_spikes(t)+ length(multi_spikes_neurons);
        end
        
        %gives the maximum number of spike in a bin for each neuron over the trial    
%       max_spikes=zeros(length(noise_simulation_results.trial_data),1);
%       for t=1:length(noise_simulation_results.params.nTrials)})
%           trial_spikes=noise_simulation_results.trial_data{i}{t};
%               for j=1:noise_simulation_results.params.nNeurons
%                 max_spikes(t)=max([max_spikes(t) trial_spikes(j,:)]);        
%               end
%       end
%       
%       for t=1:length(noise_simulation_results.params.nTrials)
%         trial_spikes=noise_simulation_results.trial_data{i}{t};
%         nBins=size(trial_spikes,2);
%         for j=1:nBins
%             neurons_who_spiked=find(trial_spikes(:,j)>0);
%             co_occuring(t,j)=length(neurons_who_spiked);
%         end
%      end
   
    
    %gives the max spikes in a timebin over the trial
    %max_max_spikes=max(max_spikes,[],2);
    
    end
    
    mean_co_occuring(i) = mean(co_occuring);
    mean_multi_spikes(i)=mean(multi_spikes);
    %mean_max_max_spikes{i}=mean(max_max_spikes);
    stderr_co_occuring(i)=std(co_occuring)./sqrt(length(co_occuring));
    stderr_multi_spikes(i)=std(multi_spikes)./sqrt(length(multi_spikes));
      
end

%plot spikes co-occuring / level of noise
f1=figure(1);
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(noise_levels, mean_co_occuring, stderr_co_occuring,'LineProps',{'Color',colors(1,:)});
xlabel('Noise level');
ylabel('mean spikes co-occuring');

saveas(f1, fullfile('C:\Users\kirchher\project\tool_learning\output\figures\HMM\betta\noise_simulation', 'co-occuring_noiselevel_15levels_100trials_2.png'));
saveas(f1, fullfile('C:\Users\kirchher\project\tool_learning\output\figures\HMM\betta\noise_simulation', 'co-occuring_noiselevel_15levels_100trials_2.eps'));

%plot multi-spike / level of noise
f2=figure(2);
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(noise_levels, mean_multi_spikes, stderr_multi_spikes,'LineProps',{'Color',colors(1,:)});
xlabel('Noise level');
ylabel('mean multi-spike');

saveas(f2, fullfile('C:\Users\kirchher\project\tool_learning\output\figures\HMM\betta\noise_simulation', 'multispike_noiselevel_15levels_100trials_2.png'));
saveas(f2, fullfile('C:\Users\kirchher\project\tool_learning\output\figures\HMM\betta\noise_simulation', 'multispike_noiselevel_15levels_100trials_2.eps'));
