% matrix comparison plot
%
% FC matrix comparison
% INPUT:    FC matric
% OUTPUT:    Plot & dataset
%
% Thomas Quettier 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fcc(varargin)

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
  X.(sprintf('%s',condition{1})).(sprintf('M%d', week(i))) = temp.granger_glm_results.causal_results.Psi2;
  else
  X.(sprintf('%s',condition{1})).(sprintf('M%d', week(i))) =  NaN;
  end
end
end

% matrix differences-------------------------
for c = 1:length(conditionref)
    condition = conditionref(c);
    week = weekIncondition(condition);
C= [];
CC= [];
for i = 1:57
  A = X.fixation.M6;
  AA = X.(sprintf('%s',condition{1})).(sprintf('M%d', week(1)));
  if week(find(week==i))==i
  B = X.(sprintf('%s',condition{1})).(sprintf('M%d', week(find(week==i))));
  val = 1-mean(abs(A-B),'all');
  val2 = 1-mean(abs(AA-B),'all');
  CC = [CC val2];
  C = [C val];
  else 
      C = [C NaN];
      CC = [CC NaN];
  end
  
end
X.comparison.ref_fixation.(sprintf('%s',condition{1}))= C';
X.comparison.ref_week1.(sprintf('%s',condition{1}))= CC';

end

% plot
label = {};
for i = 1:57
  label{i} = {sprintf('%02d', i)} ;
end
X.label=label';

fig=figure();
xlabel('weeks');
ylabel('matrix difference (ref:X.fixation.week6)');
xticks([1:57])
xticklabels(string(label));
title('fc matrix comparison');
hold on;
plot(X.comparison.ref_fixation.fixation ,'k-+')
plot(X.comparison.ref_fixation.visual_grasp_left ,'r-*')
%plot(X.comparison.ref_fixation.visual_rake_pull_left ,'b-*')
plot(X.comparison.ref_fixation.visual_rake_push_left ,'c-*') %complete
plot(X.comparison.ref_fixation.visual_pliers_left ,'g-*')
plot(X.comparison.ref_fixation.visual_stick_left ,'y-*') %complete
plot(X.comparison.ref_fixation.motor_grasp_left ,'r-o')
plot(X.comparison.ref_fixation.motor_rake_left ,'b-o')
plot(X.comparison.ref_fixation.motor_rake_center_catch ,'k-o') %complete
plot(X.comparison.ref_fixation.motor_rake_food_left ,'m-o') %complete
plot([7.5 7.5],[0 1], 'k:')   %stage2
plot([32.5 32.5],[0 1], 'k:') %stage3
hold off;
legend({'fixation','visual grasp','visual rake push','visual pliers','visual stick','motor grasp','motor rake','motor rake center catch','motor rake food'},'Location','southeast')

fig2=figure();
xlabel('weeks');
ylabel('matrix difference (ref:X.fixation.ref.week1)');
xticks([1:57])
xticklabels(string(label));
title('fc matrix comparison');
hold on;
plot(X.comparison.ref_week1.fixation ,'k-+')
plot(X.comparison.ref_week1.visual_grasp_left ,'r-*')
%plot(X.comparison.ref_week1.visual_rake_pull_left ,'b-*')
plot(X.comparison.ref_week1.visual_rake_push_left ,'c-*') %complete
plot(X.comparison.ref_week1.visual_pliers_left ,'g-*')
plot(X.comparison.ref_week1.visual_stick_left ,'y-*') %complete
plot(X.comparison.ref_week1.motor_grasp_left ,'r-o')
plot(X.comparison.ref_week1.motor_rake_left ,'b-o')
plot(X.comparison.ref_week1.motor_rake_center_catch ,'k-o') %complete
plot(X.comparison.ref_week1.motor_rake_food_left ,'m-o') %complete
plot([7.5 7.5],[0 1], 'k:')   %stage2
plot([32.5 32.5],[0 1], 'k:') %stage3
hold off;
legend({'fixation','visual grasp','visual rake push','visual pliers','visual stick','motor grasp','motor rake','motor rake center catch','motor rake food'},'Location','southeast')

% save data
saveas(fig, fullfile(params.output_path, 'fc_matrix_comparison_fixation_week6.png'));
saveas(fig, fullfile(params.output_path, 'fc_matrix_comparison_fixation_week6.eps'),'epsc');
saveas(fig2, fullfile(params.output_path, 'fc_matrix_comparison_ref_week1.png'));
saveas(fig2, fullfile(params.output_path, 'fc_matrix_comparison_ref_week1.eps'),'epsc');
save(fullfile(params.output_path, 'fc_matrix_comparison.mat'),'X');
