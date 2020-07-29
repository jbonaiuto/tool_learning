% matrix comparison plot
%
% FC matrix comparison
% INPUT:    FC matric
% OUTPUT:    Plot & dataset
%
% Thomas Quettier 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fcc(condition,varargin)

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
condition = {condition};
week = weekIncondition(condition);

% matrix dataset
for i = 1:length(week)
    source = fullfile(datadir,sprintf('Week_%d_%s_whole_trial',week(i),condition{1}));
  if exist(source, 'dir')
  temp = load(fullfile(source,'granger_glm_results.mat'));
  X.(sprintf('M%d', week(i))) = temp.granger_glm_results.causal_results.Psi2;
  else
  X.(sprintf('M%d', week(i))) =  NaN;
  end
end

% matrix differences
C= [];
for i = 1:length(week)
  A = X.(sprintf('M%d', week(1)));
  B = X.(sprintf('M%d', week(i)));
  val = 1-mean(abs(A-B),'all');
  C = [C val];
  label{i} = {sprintf('%02d', week(i))} ;
end
X.comparison = C';

% plot
label = {};
for i = 1:length(week)
  label{i} = {sprintf('%02d', week(i))} ;
end
X.label=label';

fig=figure();
xlabel('weeks');
ylabel(sprintf('matrix difference (ref:%02d)',week(1)));
xticks([1:length(week)])
xticklabels(string(label));
title(sprintf('%s fc matrix comparison',condition{1}));
hold on;
plot(C,'-o')
plot([2.5 2.5],[0 1], 'k:')   %stage2
plot([25.5 25.5],[0 1], 'k:') %stage3

% save data
saveas(fig, fullfile(params.output_path, sprintf('%s_fc_matrix_comparison.png',condition{1})));
saveas(fig, fullfile(params.output_path, sprintf('%s_fc_matrix_comparison.eps',condition{1})),'epsc');
save(fullfile(params.output_path, sprintf('%s_fc_matrix_comparison.mat',condition{1})),'X');

