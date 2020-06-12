function analyze_num_neurons_simulation()

load('num_neurons_simulation_results.mat');
load('analyze_num_neurons_simulation_results.mat');

%plot spikes co-occuring / level of noise
f1=figure(1);
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(num_neurons_simulation_results.n_neurons, analyze_num_neurons_simulation_results.mean_co_occuring, analyze_num_neurons_simulation_results.stderr_co_occuring,'LineProps',{'Color',colors(1,:)});
xlabel('Number neurons');
ylabel('mean spikes co-occuring');

%plot multi-spike / level of noise
f2=figure(2);
colors=get(gca,'ColorOrder');
hold all;
shadedErrorBar(num_neurons_simulation_results.n_neurons, analyze_num_neurons_simulation_results.mean_multi_spikes, analyze_num_neurons_simulation_results.stderr_multi_spikes,'LineProps',{'Color',colors(1,:)});
xlabel('Number of neurons');
ylabel('mean multi-spike');
