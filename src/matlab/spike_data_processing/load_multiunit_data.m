function data=load_multiunit_data(exp_info, subject, dates, varargin)
% LOAD_MULTIUNIT_DATA Load multiunit data from a range of dates for a given
% subject
%
% Syntax: data=load_multiunit_data(exp_info, subject, dates, 'arrays',
%              [1:6], 'electrodes', [1:32])
%
% Inputs:
%    exp_info - experimental info data structure (created with
%               init_exp_info.m)
%    subject - subject name
%    dates - cell array of date strings to load data from
%
% Optional inputs:
%    arrays - list of array indices to load data for (all by default)
%    electrodes - list of electrode indices to load data for (all by
%                 default)
%    eyedata - load eytracking data (true or false, default=false)
%
% Outputs:
%    data - structure containing the following fields:
%           dates - cell array of date strings the data is from
%           subject - subject name
%           arrays - list of array indices data is from
%           electrodes - list of electrode indices data is from
%           ntrials - total number of trials loaded
%           spikedata - spike data structure containing the following
%                       fields:
%                       date - list of date index (from cell array of date
%                              strings above) each spike belongs to
%                       trial - list of trial indices each spike belongs to
%                              (absolute - over all dates in this file)
%                       rel_trial - list of trial indices each spike
%                                   belongs to (relative - within this day)
%                       time - list of time of each spike
%                       array - list of array index each spike belongs to
%                       electrode - list of electrode index each spike
%                                   belongs to
%           metadata - meta-data structure containing the following fields:
%                      event_types - cell array of all possible event types
%                      condition - cell array containing the condition for
%                                  each trial
%                      For each event type, the metadata structure contains a
%                      field named after it, containing a list of the time
%                      that event occurs in each trial or NaN if it does not
%                      occur (i.e. data.metadata.obj_contact)
% 
% Example:
%     data=load_multiunit_data(exp_info, 'betta', {'26.02.19','27.02.19',...
%                              '28.02.19'}, 'arrays', [1 2], 'electrodes',
%                              [1:32]);

%define default values
defaults = struct('arrays',[1:length(exp_info.array_names)],...
    'electrodes',[1:exp_info.ch_per_array],'eyedata',false);  
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

% Create data structure
data=[];
data.dates=dates;
data.subject=subject;
data.arrays=params.arrays;
data.electrodes=params.electrodes;
data.ntrials=0;
data.trial_date=[];

% Create spikedata structure
data.spikedata=[];
data.spikedata.date=[];
data.spikedata.trial=[];
data.spikedata.rel_trial=[];
data.spikedata.time=[];
data.spikedata.array=[];
data.spikedata.electrode=[];

if params.eyedata
    data.eyedata=[];
    data.eyedata.date=[];
    data.eyedata.trial=[];
    data.eyedata.rel_trial=[];
    data.eyedata.x={};
    data.eyedata.y={};
    data.eyedata.t={};
end

% Create metadata structure
event_types={'trial_start','fix_on','go','hand_mvmt_onset','tool_mvmt_onset',...
    'obj_contact','place','reward'};
data.metadata=[];
data.metadata.event_types=event_types;
for evt_idx=1:length(event_types)
    data.metadata.(event_types{evt_idx})=[];
end
data.metadata.condition={};

% Load metadata
for d_idx=1:length(dates)
    evt_file=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dates{d_idx}, 'trial_events.csv');
    evts=readtable(evt_file);

    info_file=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
        dates{d_idx}, 'trial_info.csv');
    info=readtable(info_file,'Delimiter',',');
    
    good_trial_idx=info.overall_trial(find(strcmp(info.status,'good')));
    
    for i=1:length(good_trial_idx)
        condition=info.condition{find(info.overall_trial==good_trial_idx(i))};
        for evt_idx=1:length(event_types)
            event_type=event_types{evt_idx};
            if (strcmp(condition,'motor_rake_left') || strcmp(condition,'motor_rake_food_left')) && strcmp(event_type,'obj_contact')
                left_evt_times=evts.time(intersect(find(evts.trial==good_trial_idx(i)),...
                    find(strcmp(evts.event,'monkey_tool_left'))));
                mid_left_evt_times=evts.time(intersect(find(evts.trial==good_trial_idx(i)),...
                    find(strcmp(evts.event,'monkey_tool_mid_left'))));
                if length(left_evt_times) && length(mid_left_evt_times)
                    data.metadata.(event_type)=[data.metadata.(event_type) max([left_evt_times(1) mid_left_evt_times(1)])];
                elseif length(left_evt_times)
                    data.metadata.(event_type)=[data.metadata.(event_type) left_evt_times(1)];
                elseif length(mid_left_evt_times)
                    data.metadata.(event_type)=[data.metadata.(event_type) mid_left_evt_times(1)];
                else
                    data.metadata.(event_type)=[data.metadata.(event_type) NaN];
                end
            elseif (strcmp(condition,'motor_rake_right') || strcmp(condition,'motor_rake_food_right')) && strcmp(event_type,'obj_contact')
                right_evt_times=evts.time(intersect(find(evts.trial==good_trial_idx(i)),...
                    find(strcmp(evts.event,'monkey_tool_right'))));
                mid_right_evt_times=evts.time(intersect(find(evts.trial==good_trial_idx(i)),...
                    find(strcmp(evts.event,'monkey_tool_mid_right'))));
                if length(right_evt_times) && length(mid_right_evt_times)
                    data.metadata.(event_type)=[data.metadata.(event_type) max([right_evt_times(1) mid_right_evt_times(1)])];
                elseif length(right_evt_times)
                    data.metadata.(event_type)=[data.metadata.(event_type) right_evt_times(1)];
                elseif length(mid_right_evt_times)
                    data.metadata.(event_type)=[data.metadata.(event_type) mid_right_evt_times(1)];
                else
                    data.metadata.(event_type)=[data.metadata.(event_type) NaN];
                end
            else
                mapped_event_type=map_event_type(condition, event_type);
                if length(mapped_event_type)
                    evt_times=evts.time(intersect(find(evts.trial==good_trial_idx(i)),...
                        find(strcmp(evts.event,mapped_event_type))));
                    if length(evt_times)
                        data.metadata.(event_type)=[data.metadata.(event_type) evt_times(1)];
                    else
                        data.metadata.(event_type)=[data.metadata.(event_type) NaN];
                    end
                else
                    data.metadata.(event_type)=[data.metadata.(event_type) NaN];
                end
            end
        end
        data.metadata.condition{end+1}=condition;
    end
end

for a_idx=1:length(params.arrays)
    array_idx=params.arrays(a_idx);
    array_name=exp_info.array_names{array_idx};          
            
    for e_idx=1:length(params.electrodes)
        electrode_idx=params.electrodes(e_idx);
        
        overall_trial_idx=1;

        for d_idx=1:length(dates)
            info_file=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
                dates{d_idx}, 'trial_info.csv');
            info=readtable(info_file,'Delimiter',',');
            good_trial_idx=info.overall_trial(find(strcmp(info.status,'good')));

            spike_file=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject,...
                dates{d_idx}, 'spikes', sprintf('%s_%d_spikes.csv', array_name, (e_idx-1)));
            if exist(spike_file,'file')==2
                spike_data=readtable(spike_file);

                
                for i=1:length(good_trial_idx)
                    spikes=spike_data.time(spike_data.trial==good_trial_idx(i) & spike_data.electrode==(electrode_idx-1));
                    n_spikes=length(spikes);
                    data.spikedata.date(end+1:end+n_spikes)=d_idx.*ones(1,n_spikes);
                    data.spikedata.trial(end+1:end+n_spikes)=overall_trial_idx.*ones(1,n_spikes);
                    data.spikedata.rel_trial(end+1:end+n_spikes)=i.*ones(1,n_spikes);
                    data.spikedata.time(end+1:end+n_spikes)=spikes.*1000.0;
                    data.spikedata.array(end+1:end+n_spikes)=array_idx.*ones(1,n_spikes);
                    data.spikedata.electrode(end+1:end+n_spikes)=e_idx.*ones(1,n_spikes);
                    overall_trial_idx=overall_trial_idx+1;
                end               
            else
                overall_trial_idx=overall_trial_idx+length(good_trial_idx);
            end
            if a_idx==1 && e_idx==1
                data.trial_date(end+1:end+length(good_trial_idx))=d_idx;
            end
        end 
        if data.ntrials==0
            data.ntrials=overall_trial_idx-1;
        end
    end    
end

if params.eyedata
    trial_offset=0;
    for d_idx=1:length(dates)
        curr_data=load(fullfile(exp_info.base_data_dir,'preprocessed_data', subject, dates{d_idx},...
            'eyetracking', sprintf('%s_%s_eyedata.mat', subject, dates{d_idx})));
        curr_data=curr_data.data;
        if curr_data.ntrials>0      
            data.eyedata.date(end+1:end+curr_data.ntrials)=curr_data.eyedata.date;
            data.eyedata.trial(end+1:end+curr_data.ntrials)=curr_data.eyedata.trial+trial_offset;
            trial_offset=trial_offset+curr_data.ntrials;
            data.eyedata.rel_trial(end+1:end+curr_data.ntrials)=curr_data.eyedata.rel_trial;
            for j=1:curr_data.ntrials
                data.eyedata.x{end+1}=curr_data.eyedata.x{j};
                data.eyedata.y{end+1}=curr_data.eyedata.y{j};
                data.eyedata.t{end+1}=curr_data.eyedata.t{j};
            end
        end
    end
end
