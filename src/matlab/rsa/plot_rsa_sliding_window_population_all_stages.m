function plot_rsa_sliding_window_population_all_stages(exp_info, subject, stages, array_idx)

addpath('../spike_data_processing');

conditions={'motor_rake_left','motor_rake_center','motor_rake_right',...
    'motor_grasp_left','motor_grasp_center','motor_grasp_right',...
    'visual_grasp_left','visual_grasp_right',...
    'visual_pliers_left','visual_pliers_right',...
    'visual_rake_pull_left','visual_rake_pull_right',...
    'visual_rake_push_left','visual_rake_push_right',...
    'visual_stick_left','visual_stick_right'};
condition_labels={};
for i=1:length(conditions)
    condition_labels{i}=strrep(conditions{i},'_', ' ');
end

array=exp_info.array_names{array_idx};
align_evts={'go','hand_mvmt_onset','obj_contact','place'};
align_wois=[-250 250;-250 250;-250 250;-250 250];

figure();

for ae_idx=1:length(align_evts)
    align_event=align_evts{ae_idx};
    for stage_idx=1:length(stages)
        stage=stages{stage_idx};
        fname=sprintf('%s_stage%s_%s_%s.mat', subject, stage, array, align_event);
        load(fullfile('../../../output',fname));
        data=compute_firing_rate(data,'win_len',120,'baseline_type','condition');
    
        ae_condition_mean_fr=zeros(length(conditions),exp_info.ch_per_array,length(data.bins)-1);
    
        for c_idx=1:length(conditions)    
            % Find trials for this condition
            condition=conditions{c_idx};
            trials=find(strcmp(data.metadata.condition,condition));

            if length(trials)>0
                % Convolved firing rate for each trial
                conv_fr=zeros(exp_info.ch_per_array,length(trials),length(data.bins)-1);
                for e_idx=1:exp_info.ch_per_array
                    k=1;
                    for t_idx=1:length(trials)
                        trial_rate=squeeze(data.firing_rate(1,e_idx,trials(t_idx),1:end-1));
                        if ~any(isinf(trial_rate))
                            conv_fr(e_idx,k,:)=conv2(1,ones(1,200)./200,trial_rate','same');
                            k=k+1;
                        end
                    end
                end        
                ae_condition_mean_fr(c_idx,:,:)=squeeze(nanmean(conv_fr,2));
            else
                ae_condition_mean_fr(c_idx,:,:)=NaN;
            end
        end
        condition_mean_fr{ae_idx}=ae_condition_mean_fr;    

        dat = squeeze(mean(ae_condition_mean_fr,3));
        ok = ~all(dat==0);
        RSAmat=create_RSA_mat(dat(:,ok));
        
        ax=subplot(length(stages),length(align_evts),(stage_idx-1)*length(align_evts)+ae_idx);
        lims=[-1 1];
        plot_RDM(ax, RSAmat, condition_labels,...
            sprintf('%s: %s', exp_info.array_names{array_idx}, strrep(align_event,'_',' ')),...
            lims, 'colorbar', true);
        drawnow;
    end
end    
    
end