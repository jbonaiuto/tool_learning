% Run Granger GLM functional connectivity
% Parameters:
%   data_dir = directory containing the date (string)
%   dates = dates to load data from (cell array)
%   arrays = names of array to analyze (cell array)
%   electrodes = which electrodes to load cells from (vector)
% Optional parameters:
%   mua = multi-unit activity (boolean)
%   output_path = path to save results and figures to
%   output_fname = filename to save results to
% Example
%   func_connectivity('C:\functional_connectivity',{'01.02.19','04.02.19'},...
%       {'F1','F5hand'},[0:31],'mua',true,'output_path','output/f1-f5hand',...
%       'output_fname','granger_result.mat');
function func_connectivity(data_dir, dates, arrays, electrodes, varargin)

% Parse optional arguments
defaults=struct('mua', false, 'output_fname', 'granger_glm_results.mat',...
    'output_path', '../../../../output/functional_connectivity');
params=struct(varargin{:});
for f=fieldnames(defaults)',
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

bin_width=1;                                                        
%Analysis epoch
bins=[-499:bin_width:2000];                                         

granger_glm_results=[];
granger_glm_results.bins=bins;
granger_glm_results.dates=dates;
granger_glm_results.arrays=arrays;
granger_glm_results.electrodes=electrodes;
granger_glm_results.mua=params.mua;

if ~params.mua
    cells_to_use={};
    % Figure out which cells are present in data in all days
    for date_idx=1:length(dates)
        date=dates{date_idx};
        for array_idx=1:length(arrays)
            array=arrays{array_idx};        
            for elec_idx=1:length(electrodes)
                electrode=electrodes(elec_idx);

                spike_data=readtable(fullfile(data_dir,date, 'spikes',sprintf('%s_%d_spikes.csv', array, electrode)));
                cells=unique(spike_data.cell);
                if date_idx==1
                    cells_to_use{array_idx,elec_idx}=cells;
                else
                    cells_to_use{array_idx,elec_idx}=intersect(cells_to_use{array_idx,elec_idx},cells);
                end
            end
        end
    end
    granger_glm_results.cells_to_use=cells_to_use;

    cell_idx={};
    idx=1;
    for array_idx=1:length(arrays)
        array=arrays{array_idx};
        for elec_idx=1:length(electrodes)
            electrode_cells_to_use=cells_to_use{array_idx,elec_idx};
            electrode_cell_idx=[];
            for i=1:length(electrode_cells_to_use)
                electrode_cell_idx(i)=idx;
                idx=idx+1;
            end
            cell_idx{array_idx,elec_idx}=electrode_cell_idx;
        end
    end
    granger_glm_results.cell_idx=cell_idx;
    
    num_units=idx-1;
else
    num_units=length(electrodes)*length(arrays);
end

% Figure out total number of trials (to initialize X with the right size)
num_trials=0;
for date_idx=1:length(dates)
    date=dates{date_idx};
    trial_data=readtable(fullfile(data_dir,date,'trial_info.csv'));  

    idx_good=find(strcmp(trial_data.status,'good'));             %Index of correct trials
    idx_motor=find(strcmp(trial_data.condition,'motor_grasp_right')...  %Index of motor trials
        | strcmp(trial_data.condition,'motor_grasp_left')...
        | strcmp(trial_data.condition,'motor_grasp_center'));
    idx_correct=intersect(idx_motor,idx_good);
    num_trials=num_trials+length(idx_correct);
end

X=zeros(num_units,length(bins),num_trials);
trial_idx=1;
for date_idx=1:length(dates)
    date=dates{date_idx};
    trial_data=readtable(fullfile(data_dir,date,'trial_info.csv'));  

    idx_good=find(strcmp(trial_data.status,'good'));             %Index of correct trials
    idx_motor=find(strcmp(trial_data.condition,'motor_grasp_right')...  %Index of motor trials
        | strcmp(trial_data.condition,'motor_grasp_left')...
        | strcmp(trial_data.condition,'motor_grasp_center'));
    idx_correct=intersect(idx_motor,idx_good);                          %Intersect motor x correct trials

    %For each trial
    for j=1:length(idx_correct)
        for array_idx=1:length(arrays)
            array=arrays{array_idx};
            for elec_idx=1:length(electrodes)
                electrode=electrodes(elec_idx);
                spike_data=readtable(fullfile(data_dir,date,'spikes',sprintf('%s_%d_spikes.csv', array, electrode)));
                
                if ~params.mua
                    electrode_cells_to_use=cells_to_use{array_idx,elec_idx};
                    electrode_cell_idx=cell_idx{array_idx,elec_idx};

                    trial=idx_correct(j);
                    %For each cell
                    for i=1:length(electrode_cells_to_use)
                        cell=electrode_cells_to_use(i);        

                        %Index trial x cell
                        cell_trial_rows=intersect(find(spike_data.trial==trial),find(spike_data.cell==cell));   %Index trial x cell
                        spikes=spike_data.time(cell_trial_rows);        %Index spike times
                        bin_counts=histc(spikes,bins);                  %Create logical spikes matrix 
                        X(electrode_cell_idx(i),:,trial_idx)=bin_counts;                            %Output matrix for GC
                    end          
                else
                    trial=idx_correct(j);
                    trial_rows=find(spike_data.trial==trial);   %Index trial
                    spikes=spike_data.time(trial_rows);        %Index spike times
                    bin_counts=histc(spikes,bins);                  %Create logical spikes matrix 
                    X((array_idx-1)*length(electrodes)+elec_idx,:,trial_idx)=bin_counts;                            %Output matrix for GC
                end
            end
        end
        trial_idx=trial_idx+1;
    end
end

% Dimension of X (# Channels x # Samples x # Trials)
[CHN SMP TRL] = size(X);

granger_glm_results.X=X;
granger_glm_results.num_chan=CHN;
granger_glm_results.num_sample=SMP;
granger_glm_results.num_trial=TRL;

% To fit GLM models with different history orders
for neuron = 1:CHN
    for ht = 3:3:60                             % history, W=3ms
        [bhat{ht,neuron}] = glmtrial(X,neuron,ht,3);
    end
end

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
colorbar();
title('Granger causality matrix');
saveas(fig, fullfile(params.output_path, 'phi.png'));
saveas(fig, fullfile(params.output_path, 'phi.eps'),'epsc');

fig=figure();
colormap(redblue());
imagesc(causal_results.Psi1);
set(gca,'clim',[-1 1]);
xlabel('Source');
ylabel('Target'); 
title('Causal connectivity matrix');
saveas(fig, fullfile(params.output_path, 'psi1.png'));
saveas(fig, fullfile(params.output_path, 'psi1.eps'),'epsc');

fig=figure();
colormap(redblue());
imagesc(causal_results.Psi2);
set(gca,'clim',[-1 1]);
xlabel('Source');
ylabel('Target'); 
title('Causal connectivity matrix (FDR)');
saveas(fig, fullfile(params.output_path, 'psi2.png'));
saveas(fig, fullfile(params.output_path, 'psi2.eps'),'epsc');

save(fullfile(params.output_path, params.output_fname), 'granger_glm_results');