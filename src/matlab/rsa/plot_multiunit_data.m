function plot_multiunit_data(data, array_idx, e_idx, conditions, tlims, varargin)

defaults = struct('baseline_woi',[-500 0],'baseline_evt','go');  %define default values
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end
event_types=data.metadata.event_types;

binwidth=20;
bins=[tlims(1):binwidth:tlims(2)];

data_idx=data.spikedata.array==array_idx & data.spikedata.electrode==e_idx;
if length(conditions)==0
    conditions=unique(data.metadata.condition);
end

condition_labels={};
for c_idx=1:length(conditions)
    condition_labels{c_idx}=strrep(conditions{c_idx},'_',' ');
end
evt_color=cbrewer('qual','Paired',length(event_types));
cond_color=cbrewer('qual','Set1',length(conditions));

figure();
subplot(2,1,1);
hold all
overall_t_idx=1;
for c_idx=1:length(conditions)
    condition=conditions{c_idx};
    condition_trials=find(strcmp(data.metadata.condition,condition));
    
    for t_idx=1:length(condition_trials)
        trial_spikes=data.spikedata.time(data_idx & data.spikedata.trial==condition_trials(t_idx));
        plot(trial_spikes,overall_t_idx*ones(1,length(trial_spikes)),'.k');
    
        for evt_idx=1:length(event_types)
            event_type=event_types{evt_idx};
            event_data=data.metadata.(event_type);
            if ~isnan(event_data(condition_trials(t_idx)))
                plot(event_data(condition_trials(t_idx)),overall_t_idx,'.','Color',evt_color(evt_idx,:));
            end
        end
        overall_t_idx=overall_t_idx+1;
    end    
    if c_idx<length(conditions)
        plot(tlims,[overall_t_idx overall_t_idx],'r','LineWidth',2);
        overall_t_idx=overall_t_idx+1;
    end
end
xlim(tlims);
ylim([0 overall_t_idx]);
    

subplot(2,1,2);
hold all
for c_idx=1:length(conditions)
    condition=conditions{c_idx};
    
    condition_trials=find(strcmp(data.metadata.condition,condition));
    
    baseline_evt_times=data.metadata.(params.baseline_evt);
    trial_binned_rate=zeros(length(condition_trials),length(bins));
    trial_baseline_rate=zeros(1,length(condition_trials));
    for t_idx=1:length(condition_trials)
        baseline_evt_time=baseline_evt_times(condition_trials(t_idx));
        trial_spikes=data.spikedata.time(data_idx & data.spikedata.trial==condition_trials(t_idx));
        baseline_spikes=length(intersect(find(trial_spikes-baseline_evt_time>=params.baseline_woi(1)),...
            find(trial_spikes-baseline_evt_time<=params.baseline_woi(2))));
        trial_baseline_rate(t_idx)=baseline_spikes./((params.baseline_woi(2)-params.baseline_woi(1))/1000);
        binned_rate=histc(trial_spikes,bins)./(binwidth/1000);
        trial_binned_rate(t_idx,:)=binned_rate;
    end
    bc_binned_rate=(trial_binned_rate-mean(trial_baseline_rate))/mean(trial_baseline_rate);                                
        
    trial_smoothed_rate=zeros(size(bc_binned_rate));
    w=gausswin(6);
    for t_idx=1:size(bc_binned_rate)
        trial_smoothed_rate(t_idx,:)=filter(w,1,bc_binned_rate(t_idx,:));
    end
    mean_smoothed_rate=mean(trial_smoothed_rate);
    stderr_smoothed_rate=std(trial_smoothed_rate)./sqrt(size(trial_smoothed_rate,1));
    shadedErrorBar(bins,mean_smoothed_rate,stderr_smoothed_rate,'lineprops',{'Color',cond_color(c_idx,:)},'transparent',1);
end
legend(condition_labels);
yl=ylim();
for evt_idx=1:length(event_types)
    event_type=event_types{evt_idx};
    event_data=data.metadata.(event_type);
    mean_time=nanmean(event_data(:));
    std_time=nanstd(event_data(:));
    if ~isnan(mean_time)
        plot([mean_time mean_time],yl,'Color',evt_color(evt_idx,:));
        rectangle('Position',[mean_time-.5*std_time yl(1) std_time yl(2)-yl(1)],'FaceColor',[evt_color(evt_idx,:) .5],'EdgeColor','none');
    end
end
ylim(yl);
xlim(tlims);
xlabel('Time (ms)');

