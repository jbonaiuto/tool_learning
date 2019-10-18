function concat_data=concatenate_data(data, varargin)

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
concat_data.label=data{1}.label;
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