function concat_data=concatenate_data(exp_info, data, varargin)

% Parse optional arguments
defaults=struct();
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end


spm('defaults','eeg');

% Empty structure to store concatenated data (from all trials)
concat_data.label={};
for a=1:length(exp_info.array_names)
    for c=1:32
        concat_data.label{end+1}=sprintf('%s_%d',exp_info.array_names{a},c);
    end
end
concat_data.fsample=data{1}.fsample;
concat_data.time={};
concat_data.trial={};
concat_data.trialinfo=[];

for i=1:length(data)
    curr_data=data{i};
    ntrials=length(curr_data.time);
    if ntrials>0
        concat_data.time(end+1:end+ntrials)=curr_data.time;
        concat_data.trial(end+1:end+ntrials)=curr_data.trial;
        concat_data.trialinfo(end+1:end+ntrials,:)=curr_data.trialinfo;
    end
end