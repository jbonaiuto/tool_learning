% matrix comparison plot
%
% FC matrix comparison
% INPUT:    FC matric
% OUTPUT:    Plot & dataset
%
% Thomas Quettier 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data_fcc(varargin)

% Parse optional arguments
defaults=struct( 'output_fname', 'granger_glm_results.mat',...
    'output_path', '../../../../output/functional_connectivity');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end
datadir = params.output_path;

% datadir = '/Users/thomasquettier/Documents/GitHub/tool_learning/output/functional_connectivity/';
conditionref={'fixation' 'visual_grasp_left' 'visual_pliers_left'  'visual_rake_push_left'...
'visual_stick_left' 'motor_grasp_left' 'motor_rake_left' 'motor_rake_center_catch' 'motor_rake_food_left'};
%'visual_rake_pull_left'

for c = 1:length(conditionref)
    condition = conditionref(c);
    week = weekIncondition(condition);
% matrix dataset
for i = 1:length(week)
    source = fullfile(datadir,sprintf('Week_%d_%s_whole_trial',week(i),condition{1}));
  if exist(source, 'dir')
  temp = load(fullfile(source,'granger_glm_results.mat'));
  X.(sprintf('%s',condition{1})).(sprintf('W%d', week(i))) = temp.granger_glm_results.causal_results.Psi2;
  else
  X.(sprintf('%s',condition{1})).(sprintf('W%d', week(i))) =  NaN;
  end
end
end

% save data
save(fullfile(params.output_path, 'data_fcc.mat'),'X');
