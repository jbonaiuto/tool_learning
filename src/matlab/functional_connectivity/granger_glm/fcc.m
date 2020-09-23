% matrix comparison plot
%
% FC matrix comparison
% INPUT:    FC matric
% OUTPUT:    Plot & dataset
%
% Thomas Quettier 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fcc(source,target,ref,varargin)

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

%condition list
conditionref={'fixation' 'visual_grasp_left' 'visual_pliers_left'  'visual_rake_push_left'...
'visual_stick_left' 'motor_grasp_left' 'motor_rake_left' %'visual_rake_pull_left''motor_rake_center_catch' 'motor_rake_food_left'
};


% 'data_fcc.mat' is obtained by data_fcc()
load(fullfile(datadir,'data_fcc.mat'));

%source selection
sc1 = [];
sc2 = [];
if any(strcmp(source,'F1'))
sc1 = [1:32];
end
if any(strcmp(source,'F5hand'))
sc2 = [33:64];
end
sc = [sc1 sc2];

%Target selection
tg1 = [];
tg2 = [];
if any(strcmp(target,'F1'))
tg1 = [1:32];
end
if any(strcmp(target,'F5hand'))
tg2 = [33:64];
end
tg = [tg1 tg2];


reftit = strrep(ref,'_left','');
% matrix differences-------------------------
for c = 1:length(conditionref)
    condition = conditionref(c);
    week = weekIncondition(condition);
C= [];
    refweek = weekIncondition({ref});
    refweek = refweek(1);

for i = 1:57
  A = X.(sprintf('%s',ref)).(sprintf('W%d', refweek));
  if week(find(week==i))==i
      cond = condition{1};
  B = X.(sprintf('%s',cond)).(sprintf('W%d', week(find(week==i))));
      if isnan( B ) 
            C = [C NaN];
      else
  val = 1-mean(abs(A(tg,sc)-B(tg,sc)),'all');
  C = [C val];
  end
  else 
      C = [C NaN];
  end
  
end


X.comparison.(sprintf('%s_W%d',reftit, refweek)).(sprintf('%s',condition{1}))= C';

end

% null diff for plot
B=A;
B(B~=0)=0;
val = 1-mean(abs(A(tg,sc)-B(tg,sc)),'all');

% plot
label = {};
for i = 1:57
  label{i} = {sprintf('%02d', i)} ;
end
X.label=label';

source = [source{:}];
target = [target{:}];
tit = strrep(ref,'_',' ');
tit = strrep(tit,'left','');

scl = min([min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).fixation), min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).visual_grasp_left),min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).visual_rake_push_left),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).visual_pliers_left),min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).visual_stick_left),min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).motor_grasp_left),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).motor_rake_left)]) - 0.05;

fig=figure();
axis([0 57 round(scl,1) 1]);
xlabel('weeks');
ylabel(sprintf('matrix difference (ref:X.%s.W%d)',tit, refweek))
xticks([1:57])
xticklabels(string(label));
title(sprintf('fc matrix comparison source %s, target %s', source, target));
hold on;
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).fixation ,'k-+')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).visual_grasp_left ,'r-*')
%plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).visual_rake_pull_left ,'b-*')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).visual_rake_push_left ,'c-*') %complete
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).visual_pliers_left ,'g-*')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).visual_stick_left ,'y-*') %complete
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).motor_grasp_left ,'r-o')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).motor_rake_left ,'b-o')
%plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).motor_rake_center_catch ,'k-o') %complete
%plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).motor_rake_food_left ,'m-o') %complete
plot([1 57],[val val], 'g-') %empty matrix
plot([7.5 7.5],[scl 1], 'r:')   %stage2
plot([32.5 32.5],[scl 1], 'r:') %stage3

%plot([1 45],[0.0037 0.0037], 'r:') %empty matrix
hold off;
legend({'fixation','visual grasp','visual rake push','visual pliers','visual stick','motor grasp','motor rake','no FC matrix'},'Location','southeast')

% save data
X=X.comparison.(sprintf('%s_W%d',reftit, refweek));

saveas(fig, fullfile(params.output_path, sprintf('fc_matrix_comparison_source_%s_target_%s_ref_fixation.png',source,target)));
savefig(fig, fullfile(params.output_path,sprintf( 'fc_matrix_comparison_source_%s_target_%s_ref_fixation.fig',source,target)));
save(fullfile(params.output_path,sprintf( 'fc_matrix_comparison_source_%s_target_%s_ref_%s.mat',source,target,reftit)),'X');

