% Run Granger GLM functional connectivity
% Parameters:
%   data_dir = directory containing the date (string)
%   dates = dates to load data from (cell array)
%   arrays = names of array to analyze (cell array)
%   electrodes = which electrodes to load cells from (vector)
%   conditions  = which experimental condition you are looking for
% Optional parameters:
%   mua = multi-unit activity (boolean)
%   output_path = path to save results and figures to
%   output_fname = filename to save results to
% Example
%   func_connectivity('C:\functional_connectivity',{'01.02.19','04.02.19'},...
%       'F1',[0:31],{'motor_grasp_left','motor_grasp_center','motor_grasp_right','visual_grasp_left'},'mua',true,'output_path','output/f1-f5hand',...
%       'output_fname','granger_result.mat');
function func_connectivity_within_array(data_dir, dates, array, electrodes, condition,event,varargin)

% Parse optional arguments
defaults=struct('output_fname', 'granger_glm_results.mat',...
    'output_path', '../../../../output/functional_connectivity');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

addpath('../../spike_data_processing'); 



M={};
granger_glm_results=[];


for array_idx=1:length(array)
    
    date_data={};
    for date_idx=1:length(dates)
        date=dates{date_idx};
        load(fullfile(data_dir, sprintf('fr_b_%s_%s_%s.mat', array{array_idx}, date,event)));
        date_data{date_idx}=data;
    end
    data=concatenate_data(date_data, 'spike_times',false);


    %Analysis epoch (0s to reward)
    
    for t=1:data.ntrials
rew_time=data.metadata.reward(t);
data.binned_spikes(:,electrodes,t,find((data.bins<0) | (data.bins>=rew_time)))=NaN;
data.firing_rate(:,electrodes,t,find((data.bins<0) | (data.bins>=rew_time)))=NaN;
data.smoothed_firing_rate(:,electrodes,t,find((data.bins<0) | (data.bins>=rew_time)))=NaN;
    end

bin_idx=find(data.bins>=0);
data.bins=data.bins(bin_idx);
data.binned_spikes=data.binned_spikes(:,electrodes,:,bin_idx);
data.firing_rate=data.firing_rate(:,electrodes,:,bin_idx);
data.smoothed_firing_rate=data.smoothed_firing_rate(:,electrodes,:,bin_idx);

    granger_glm_results.bins=data.bins;

    num_units=length(electrodes);

    % Figure out total number of trials (to initialize X with the right size)
    trials=zeros(1,length(data.metadata.condition));
    for i=1:length(condition)
        trials=trials | strcmp(data.metadata.condition,condition{i});
    end
    trials=find(trials); 
    num_trials=length(trials);

    data.metadata.condition=data.metadata.condition(trials);
    data.metadata.trial_start=data.metadata.trial_start(trials);
    data.metadata.fix_on=data.metadata.fix_on(trials);
    data.metadata.go=data.metadata.go(trials);
    data.metadata.hand_mvmt_onset=data.metadata.hand_mvmt_onset(trials);
    data.metadata.tool_mvmt_onset=data.metadata.tool_mvmt_onset(trials);
    data.metadata.obj_contact=data.metadata.obj_contact(trials);
    data.metadata.place=data.metadata.place(trials);
    data.metadata.reward=data.metadata.reward(trials);

    data.binned_spikes=data.binned_spikes(:,:,trials,:);
    data.firing_rate=data.firing_rate(:,:,trials,:);
    data.smoothed_firing_rate=data.smoothed_firing_rate(:,:,trials,:);

    X=permute(squeeze(data.binned_spikes),[1 3 2]); 
    X(X>1) = 1;

        if array_idx==1
            M=X;
        else
            M( (max(electrodes)*(array_idx-1)+1) : (max(electrodes)*array_idx) ,:,:)=X;
        end
    
end
X=M;

% Dimension of X (# Channels x # Samples x # Trials)
[CHN SMP TRL] = size(X);


granger_glm_results.dates=dates;
granger_glm_results.arrays={array};
granger_glm_results.electrodes=electrodes;
granger_glm_results.X=X;
granger_glm_results.num_chan=CHN;
granger_glm_results.num_sample=SMP;
granger_glm_results.num_trial=TRL;

% To fit GLM models with different history orders
h = waitbar(0,'Please wait...');
s = clock;
for neuron = 1:CHN
    for ht = 3:3:60                             % history, W=3ms
        [bhat{ht,neuron}] = glmtrial(X,neuron,ht,3);
    end
    
      % estimate remaining time
     if neuron ==1
      iteration = etime(clock,s);
      esttime = (iteration * CHN);
     end
     seconde = esttime-etime(clock,s);
     minute = seconde/60;
     h = waitbar(neuron/CHN,h,...
         ['remaining time =',num2str(minute,'%4.1f'),'min' ])
end
close(gcf)


% To select a model order, calculate AIC
for neuron = 1:CHN
    for ht = 3:3:60
        LLK(ht,neuron) = log_likelihood_trial(bhat{ht,neuron},X,ht,neuron);
        aic(ht,neuron) = -2*LLK(ht,neuron) + 2*(CHN*ht/3 + 1);
    end  
end



granger_glm_results.aic=aic;
granger_glm_results.bhat=bhat;
granger_glm_results.LLK=LLK;

% To plot the AIC 
for neuron = 1:CHN
    fig=figure(neuron);
    plot(aic(3:3:60,neuron));
    saveas(fig, fullfile(params.output_path,sprintf('aic_%d.png', neuron)));
    saveas(fig, fullfile(params.output_path,sprintf('aic_%d.eps', neuron)),'epsc');
end

%Identify Granger causality
causal_results=CausalTest(X, aic, bhat, LLK);
granger_glm_results.causal_results=causal_results;

% Plot the results
fig=figure();
colormap('parula');
imagesc(causal_results.Phi);
xlabel('Source');
ylabel('Target');
set(gca,'YDir','reverse')
colorbar();
title('Granger causality matrix');
saveas(fig, fullfile(params.output_path, 'phi.png'));
saveas(fig, fullfile(params.output_path, 'phi.eps'),'epsc');

fig=figure();
colormap(redblue());
imagesc(causal_results.Psi1);
set(gca,'clim',[-1 1]);
set(gca,'YDir','reverse')
xlabel('Source');
ylabel('Target'); 
title('Causal connectivity matrix');
saveas(fig, fullfile(params.output_path, 'psi1.png'));
saveas(fig, fullfile(params.output_path, 'psi1.eps'),'epsc');

fig=figure();
colormap(redblue());
imagesc(causal_results.Psi2);
set(gca,'clim',[-1 1]);
set(gca,'YDir','reverse')
xlabel('Source');
ylabel('Target'); 
title('Causal connectivity matrix (FDR)');
saveas(fig, fullfile(params.output_path, 'psi2.png'));
saveas(fig, fullfile(params.output_path, 'psi2.eps'),'epsc');

save(fullfile(params.output_path, params.output_fname), 'granger_glm_results');