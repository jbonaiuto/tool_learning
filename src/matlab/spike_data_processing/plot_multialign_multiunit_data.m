function plot_multialign_multiunit_data(exp_info, data, array_idx, e_idx, conditions, varargin)

defaults = struct('baseline_woi',[-500 0],'baseline_evt','go');  %define default values
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end
event_types={'go','hand_mvmt_onset','obj_contact','place'};
binwidth=20;
data_idx=data.spikedata.array==array_idx & data.spikedata.electrode==e_idx;
if length(conditions)==0
    conditions=unique(data.metadata.condition);
end
evt_color=cbrewer('qual','Paired',length(event_types));
cond_color=cbrewer('qual','Set1',length(conditions));

align_evts={'go','hand_mvmt_onset','obj_contact','place'};
tlims=[-250 250;-250 200;-100 250;-250 250];

figure();

for ae_idx=1:length(align_evts)
    align_evt=align_evts{ae_idx};
    %bins=[tlims(ae_idx,1)-50:binwidth:tlims(ae_idx,2)+50];
    aligned_data=realign(data, align_evt);
    aligned_data=bin_spikes(exp_info, aligned_data, [tlims(ae_idx,1)-50 tlims(ae_idx,2)+50], binwidth);
    aligned_data=compute_firing_rate(aligned_data);
    
    subplot(2,length(align_evts),ae_idx);
    hold all
    overall_t_idx=1;
    for c_idx=1:length(conditions)
        condition=conditions{c_idx};
        condition_trials=find(strcmp(aligned_data.metadata.condition,condition));
    
        for t_idx=1:length(condition_trials)
            trial_spikes=aligned_data.spikedata.time(data_idx & aligned_data.spikedata.trial==condition_trials(t_idx));
            
            if ~strcmp(align_evt,'tool_mvmt_onset') || (strcmp(align_evt,'tool_mvmt_onset') && (strcmp(condition,'visual_pliers_left') || strcmp(condition,'visual_pliers_right') || strcmp(condition,'visual_rake_pull_left') || strcmp(condition,'visual_rake_pull_right')))
                plot(trial_spikes,overall_t_idx*ones(1,length(trial_spikes)),'.k');

                for evt_idx=1:length(event_types)
                    event_type=event_types{evt_idx};
                    event_data=aligned_data.metadata.(event_type);
                    if ~isnan(event_data(condition_trials(t_idx)))
                        plot(event_data(condition_trials(t_idx)),overall_t_idx,'.','Color',evt_color(evt_idx,:));
                    end
                end
            end
            overall_t_idx=overall_t_idx+1;
        end    
        if c_idx<length(conditions)
            plot(tlims(ae_idx,:),[overall_t_idx overall_t_idx],'r','LineWidth',2);
            overall_t_idx=overall_t_idx+1;
        end
    end
    xlim(tlims(ae_idx,:));
    ylim([0 overall_t_idx]);  
    if ae_idx>1
        set(gca,'YTickLabel','');
    else
        ylabel('Trial');
    end
    title(strrep(align_evt,'_',' '));
    drawnow;
    
    subplot(2,length(align_evts),length(align_evts)+ae_idx);
    hold all
    condition_labels={};
    for c_idx=1:length(conditions)
        condition=conditions{c_idx};
    
        if ~strcmp(align_evt,'tool_mvmt_onset') || (strcmp(align_evt,'tool_mvmt_onset') && (strcmp(condition,'visual_pliers_left') || strcmp(condition,'visual_pliers_right') || strcmp(condition,'visual_rake_pull_left') || strcmp(condition,'visual_rake_pull_right')))
            condition_trials=find(strcmp(aligned_data.metadata.condition,condition));
            condition_labels{end+1}=strrep(conditions{c_idx},'_',' ');
            
            mean_smoothed_rate=squeeze(nanmean(aligned_data.smoothed_firing_rate(array_idx,e_idx,condition_trials,:),3));
            stderr_smoothed_rate=nanstd(aligned_data.smoothed_firing_rate(array_idx,e_idx,condition_trials,:),[],3)./sqrt(length(condition_trials));
            shadedErrorBar(aligned_data.bins,mean_smoothed_rate,stderr_smoothed_rate,'lineprops',{'Color',cond_color(c_idx,:)},'transparent',1);
        end
    end
    if ae_idx==1
        legend(condition_labels,'Location','NorthEast');
    end
    ylim([-1 25]);
    yl=ylim();
    for evt_idx=1:length(event_types)
        event_type=event_types{evt_idx};
        event_data=aligned_data.metadata.(event_type);
        mean_time=nanmean(event_data(:));
        std_time=nanstd(event_data(:));
        if ~isnan(mean_time)
            plot([mean_time mean_time],yl,'Color',evt_color(evt_idx,:));
            rectangle('Position',[mean_time-.5*std_time yl(1) std_time yl(2)-yl(1)],'FaceColor',[evt_color(evt_idx,:) .5],'EdgeColor','none');
        end
    end
    ylim(yl);
    xlim(tlims(ae_idx,:));
    if ae_idx>1
        set(gca,'YTickLabel','');
    end
    xlabel('Time (ms)');
    drawnow;
end
