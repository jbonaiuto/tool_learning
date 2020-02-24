function bin_all_data(exp_info, subject, varargin)

%define default values
defaults = struct('parallel_mode',false);
params = struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

% Read all directories in preprocessed data directory
data_dir=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject);
d=dir(fullfile(data_dir, '*.*.*'));
d=d(2:end);
% Sort by date
d_datetimes=[];
for d_idx=1:length(d)
    d_datetimes(d_idx)=datenum(d(d_idx).name,'dd.mm.YY');
end
[~,sorted_idx]=sort(d_datetimes);
d=d(sorted_idx);

for i = 1:length(d)
    dateexp=d(i).name
    out_dir=fullfile(data_dir,dateexp,'multiunit','binned');
    
    % If this date has already been binned or is currently being binned
    if params.parallel_mode && exist(out_dir,'dir')==7
        continue
    end
    
    bin_day_data(exp_info, subject, dateexp);
end
