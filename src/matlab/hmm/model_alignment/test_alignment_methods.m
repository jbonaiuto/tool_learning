dbstop if error

subject='betta';

% Load models
load('13-22.03.19.models.mat');
model1_dates={'13.03.19','14.03.19','15.03.19'};
model2_dates={'19.03.19','21.03.19','22.03.19'};

addpath('..');
addpath('../../spike_data_processing');
addpath(genpath('../../graphviz4matlab'));


% Plot state probabilities for model 1
plotHMM_aligned(exp_info, 'betta', model1_dates, 'F1', {'motor_grasp_right'}, model1);
f=gcf();
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', 'model1_average.png'))
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', 'model1_average.eps'), 'epsc');

% Plot model graph for model 1
S=plot_model_graph(model1);
drawnow;
pause(.5);
X=S.getNodePositions();
f=gcf();
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', 'model1_graph.png'))
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', 'model1_graph.eps'), 'epsc');


% Plot state probabilities for model 2
plotHMM_aligned(exp_info, 'betta', model2_dates, 'F1', {'motor_grasp_right'}, model2);
f=gcf();
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', 'model2_average.png'))
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', 'model2_average.eps'), 'epsc');

% Plot model graph for model 2
S=plot_model_graph(model2);
drawnow;
pause(.5);
set_node_positions(S, X, model1, model2);
f=gcf();
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', 'model2_graph.png'))
saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', 'model2_graph.eps'), 'epsc');


metric = {'euclidean', 'manhattan', 'pearson', 'spearman', 'cosine', 'covar', 'jaccard'}; 
variable = {'A','EMIT','TR','PSTATES'}; 

score=[];
metric_val=[];
new_state_labels={};

n_states1=size(model1.ESTTR,1);
row_names={};

for m=1:length(metric)
    for v=1:length(variable) 
        row_names{end+1}=sprintf('%s - %s', metric{m}, variable{v});
        [new_model2,metric_val(end+1)]=align_multilevel_graphs(exp_info, model1, model2, model1_dates, model2_dates, metric{m}, variable{v});
        
        addpath('..');
        addpath('../../spike_data_processing');
        plotHMM_aligned(exp_info, 'betta', model2_dates, 'F1', {'motor_grasp_right'}, new_model2);
        f=gcf();
        saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', [metric{m} variable{v} '_average.png']))
        saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', [metric{m} variable{v} '_average.eps']), 'epsc');
         
        S=plot_model_graph(new_model2);
        drawnow;
        pause(.5);
        set_node_positions(S, X, model1, new_model2);
        f=gcf();
        saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', [metric{m} variable{v} '_graph.png']))
        saveas(f,fullfile(exp_info.base_output_dir, 'figures','HMM', subject, 'test_alignment', [metric{m} variable{v} '_graph.eps']), 'epsc');
        
        new_state_labels{end+1}=strjoin(new_model2.state_labels,'-');
        total_score=0;
        
        for i=1:n_states1
            % Get the state label
            state1_label=model1.state_labels{i};
    
            % Find which state in new_model2 has the same label
            model2_state1_idx=find(strcmp(new_model2.state_labels,state1_label));
    
            % If state 1 exists in new_model2
            if length(model2_state1_idx)>0
                % Find all projections from this state in model1 (exclude
                % self-connections
                projs=setdiff(find(model1.ESTTR(i,:)>1e-6),[i]);
            
                for j=1:length(projs)
                    % Get state label for the state that is projected to
                    state2_label=model1.state_labels{projs(j)};
        
                    % Find which state in new_model2 has the same label
                    model2_state2_idx=find(strcmp(new_model2.state_labels,state2_label));
            
                    % If state2 exists in new_model_2
                    if length(model2_state2_idx)>0
                        % Update score if this connection exists in new_model2
                        if new_model2.ESTTR(model2_state1_idx,model2_state2_idx)>0.000001
                           total_score=total_score+1;
                        end
                    end
                end
            end 
        end
        score(end+1)=total_score;
        
    end 
end 
 
t = table(score', metric_val', new_state_labels',...
    'VariableNames', {'score','metric','state_labels'}, 'RowNames',row_names);
writetable(t,'metric_scores.csv','WriteRowNames',true);

