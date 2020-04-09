function analyze_noise_simulation()

load('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation','noise_simulation_results_15levels_100trials_2.mat'));

noise_levels=[1:15];
loaded_nTrials=noise_simulation_results.params.nTrials;
loaded_nNeurons=noise_simulation_results.params.nNeurons;
overall_co_neuroing={};
overall_co_occuring={};

analyze_noise_simulation_results.mean_co_occuring={};
analyze_noise_simulation_results.stderr_co_occuring={};
analyze_noise_simulation_results.mean_multi_spikes={};
analyze_noise_simulation_results.stderr_multi_spikes={};
analyze_noise_simulation_results.mean_max_max_spikes={};
analyze_noise_simulation_results.overall_co_neuroing={};

for i=1:length(noise_simulation_results.trial_data)
    
    co_occuring=zeros(1,loaded_nTrials);
    co_neuroing={};
    co_occuring_extd={};
    
    multi_spikes=zeros(1,loaded_nTrials);
    max_spikes=zeros(loaded_nNeurons,loaded_nTrials);
    
    for t=1:loaded_nTrials
    
    trial_spikes=noise_simulation_results.trial_data{i}{t};
    nBins=size(trial_spikes,2);
    
        %find how many spikes occur simultaneously for each time bin.
        for j=1:nBins
            if length(find(trial_spikes(:,j)>0))>1
               co_occuring(t)=co_occuring(t)+ length(find(trial_spikes(:,j)>0));
            end
            co_occuring_extd{t,j}=length(find(trial_spikes(:,j)>0));
        end
        
        %find how many neurons fire multiple times in a time bin.
        for j=1:nBins
            multi_spikes_neurons=find(trial_spikes(:,j)>1);
            multi_spikes(t)=multi_spikes(t)+ length(multi_spikes_neurons);
        end
        
        %gives the maximum number of spike in a trial for each neuron  
        for n=1:loaded_nNeurons
            max_spikes(n,t)=max([max_spikes(t) trial_spikes(n,:)]);        
        end
        
        %gives the max spikes of the trial over all neurons
        max_max_spikes=max(max_spikes,[],1);

        %find how many neurons spike simultaneously for each time bin.
        for j=1:nBins
            neurons_who_spiked=find(trial_spikes(:,j)>0);
            co_neuroing{t,j}=length(neurons_who_spiked);
        end
   
    end
    
    mean_co_occuring(i) = mean(co_occuring);
    %mean_co_neuroing(i) = mean(co_neuroing);
    mean_multi_spikes(i)= mean(multi_spikes);
    mean_max_max_spikes{i}= mean(max_max_spikes);
    stderr_co_occuring(i)= std(co_occuring)./sqrt(length(co_occuring));
    %stderr_co_neuroing(i)= std(co_neuroing)./sqrt(length(co_neuroing));
    stderr_multi_spikes(i)= std(multi_spikes)./sqrt(length(multi_spikes));
    
    overall_co_neuroing{i}=co_neuroing;
    overall_co_occuring{i}=co_occuring_extd;
    
end

%plot spikes co-occuring / level of noise
f1=figure(1);
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(noise_levels, mean_co_occuring, stderr_co_occuring,'LineProps',{'Color',colors(1,:)});
xlabel('Noise level');
ylabel('mean spikes co-occuring');

saveas(f1, fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation\figures', 'co_occuring_noiselevel_15levels_100trials_2.png'));
saveas(f1, fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation\figures', 'co_occuring_noiselevel_15levels_100trials_2.eps'));

%plot multi-spike / level of noise
f2=figure(2);
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(noise_levels, mean_multi_spikes, stderr_multi_spikes,'LineProps',{'Color',colors(1,:)});
xlabel('Noise level');
ylabel('mean multi-spike');

saveas(f2, fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation\figures', 'multispike_noiselevel_15levels_100trials_2.png'));
saveas(f2, fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation\figures', 'multispike_noiselevel_15levels_100trials_2.eps'));

%plot co_neuroing / level of noise
% f3=figure(3);
% colors=get(gca,'ColorOrder');
% hold all;
% shadedErrorBar(noise_levels, mean_co_neuroing, stderr_co_neuroing,'LineProps',{'Color',colors(1,:)});
% xlabel('Noise level');
% ylabel('mean co_neuroing');
% 
% saveas(f3, fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation\figures', 'co_neuroing_noiselevel_15levels_100trials_2.png'));
% saveas(f3, fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation\figures', 'co_neuroing_noiselevel_15levels_100trials_2.eps'));


analyze_noise_simulation_results.mean_co_occuring=mean_co_occuring;
analyze_noise_simulation_results.stderr_co_occurinanalyze_noise_simulation_results.multi_spikes={};
analyze_noise_simulation_results.mean_multi_spikes=mean_multi_spikes;
analyze_noise_simulation_results.stderr_multi_spikes=stderr_multi_spikes;
analyze_noise_simulation_results.mean_max_max_spikes=mean_max_max_spikes;
analyze_noise_simulation_results.overall_co_neuroing=overall_co_neuroing;

save(fullfile('C:\Users\Seb\Documents\RESULTS\hmm_noise_simulation\','analyze_noise_simulation_results.mat'), 'analyze_noise_simulation_results');
