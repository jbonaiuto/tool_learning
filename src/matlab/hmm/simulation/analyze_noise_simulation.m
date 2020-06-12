function analyze_noise_simulation()

load('noise_simulation_results.mat');

loaded_nTrials=noise_simulation_results.params.nTrials;
loaded_nNeurons=noise_simulation_results.params.nNeurons;

analyze_noise_simulation_results.mean_co_occuring=zeros(1,length(noise_simulation_results.trial_data));
analyze_noise_simulation_results.stderr_co_occuring=zeros(1,length(noise_simulation_results.trial_data));
analyze_noise_simulation_results.mean_multi_spikes=zeros(1,length(noise_simulation_results.trial_data));
analyze_noise_simulation_results.stderr_multi_spikes=zeros(1,length(noise_simulation_results.trial_data));
%analyze_noise_simulation_results.mean_max_max_spikes={};

for i=1:length(noise_simulation_results.trial_data)
    
    % Number of simultaneously occuring spikes from different neurons
    co_occuring=zeros(1,loaded_nTrials);
    % Number of spikes from the same neuron in same time bin
    multi_spikes=zeros(1,loaded_nTrials);
    %max_spikes=zeros(loaded_nNeurons,loaded_nTrials);
    
    for t=1:loaded_nTrials
        
        trial_spikes=noise_simulation_results.trial_data{i}{t};
        nBins=size(trial_spikes,2);
        
        %find how many spikes occur simultaneously for each time bin.
        for j=1:nBins
            if length(find(trial_spikes(:,j)>0))>1
                co_occuring(t)=co_occuring(t)+ length(find(trial_spikes(:,j)>0));
            end
        end
        
        %find how many neurons fire multiple times in a time bin.
        for j=1:nBins
            multi_spikes_neurons=find(trial_spikes(:,j)>1);
            multi_spikes(t)=multi_spikes(t)+ length(multi_spikes_neurons);
        end
        
        %gives the maximum number of spike in a trial for each neuron
        %for n=1:loaded_nNeurons
        %    max_spikes(n,t)=max([max_spikes(t) trial_spikes(n,:)]);
        %end
        
        %gives the max spikes of the trial over all neurons
        %max_max_spikes=max(max_spikes,[],1);
    end
    
    analyze_noise_simulation_results.mean_co_occuring(i) = mean(co_occuring);
    analyze_noise_simulation_results.stderr_co_occuring(i)= std(co_occuring)./sqrt(length(co_occuring));
    analyze_noise_simulation_results.mean_multi_spikes(i)= mean(multi_spikes);
    analyze_noise_simulation_results.stderr_multi_spikes(i)= std(multi_spikes)./sqrt(length(multi_spikes));
    %mean_max_max_spikes{i}= mean(max_max_spikes);    
end

%plot spikes co-occuring / level of noise
f1=figure(1);
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(noise_simulation_results.noise_levels,...
    analyze_noise_simulation_results.mean_co_occuring,...
    analyze_noise_simulation_results.stderr_co_occuring,...
    'LineProps',{'Color',colors(1,:)});
xlabel('Noise level');
ylabel('mean spikes co-occuring');

%plot multi-spike / level of noise
f2=figure(2);
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(noise_simulation_results.noise_levels,...
    analyze_noise_simulation_results.mean_multi_spikes,...
    analyze_noise_simulation_results.stderr_multi_spikes,...
    'LineProps',{'Color',colors(1,:)});
xlabel('Noise level');
ylabel('mean multi-spike');
