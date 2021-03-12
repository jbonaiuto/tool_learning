function concat_data=concatenate_data(data, varargin)

% Parse optional arguments
defaults=struct();
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end


% Empty structure to store concatenated data (from all trials)
concat_data=[];
concat_data.dates={};
concat_data.subject=data{1}.subject;
concat_data.ntrials=0;
concat_data.eyedata=[];
concat_data.eyedata.date=[];
concat_data.eyedata.trial=[];
concat_data.eyedata.rel_trial=[];
concat_data.eyedata.x={};
concat_data.eyedata.y={};
concat_data.eyedata.t={};
concat_data.metadata=[];
concat_data.metadata.event_types=data{1}.metadata.event_types;
concat_data.metadata.condition={};
concat_data.metadata.trial_start=[];
concat_data.metadata.fix_on=[];
concat_data.metadata.go=[];
concat_data.metadata.hand_mvmt_onset=[];
concat_data.metadata.tool_mvmt_onset=[];
concat_data.metadata.obj_contact=[];
concat_data.metadata.place=[];
concat_data.metadata.reward=[];

trial_offset=0;

for i=1:length(data)
    curr_data=data{i};
    if curr_data.ntrials>0      
        for j=1:length(curr_data.dates)
            concat_data.dates{end+1}=curr_data.dates{j};
        end
        concat_data.eyedata.date(end+1:end+curr_data.ntrials)=curr_data.eyedata.date;
        concat_data.eyedata.trial(end+1:end+curr_data.ntrials)=curr_data.eyedata.trial+trial_offset;
        trial_offset=trial_offset+curr_data.ntrials;
        concat_data.eyedata.rel_trial(end+1:end+curr_data.ntrials)=curr_data.eyedata.rel_trial;
        for j=1:curr_data.ntrials
            concat_data.eyedata.x{end+1}=curr_data.eyedata.x{j};
            concat_data.eyedata.y{end+1}=curr_data.eyedata.y{j};
            concat_data.eyedata.t{end+1}=curr_data.eyedata.t{j};
        end
    end
    concat_data.metadata.trial_start(end+1:end+curr_data.ntrials)=curr_data.metadata.trial_start;
    concat_data.metadata.fix_on(end+1:end+curr_data.ntrials)=curr_data.metadata.fix_on;
    concat_data.metadata.go(end+1:end+curr_data.ntrials)=curr_data.metadata.go;
    concat_data.metadata.hand_mvmt_onset(end+1:end+curr_data.ntrials)=curr_data.metadata.hand_mvmt_onset;
    concat_data.metadata.tool_mvmt_onset(end+1:end+curr_data.ntrials)=curr_data.metadata.tool_mvmt_onset;
    concat_data.metadata.obj_contact(end+1:end+curr_data.ntrials)=curr_data.metadata.obj_contact;
    concat_data.metadata.place(end+1:end+curr_data.ntrials)=curr_data.metadata.place;
    concat_data.metadata.reward(end+1:end+curr_data.ntrials)=curr_data.metadata.reward;
    concat_data.metadata.condition(end+1:end+curr_data.ntrials)=curr_data.metadata.condition;

end
