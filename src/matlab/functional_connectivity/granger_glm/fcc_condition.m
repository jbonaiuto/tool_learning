% matrix comparison plot
%
% FC matrix comparison
% INPUT:    FC matric
% OUTPUT:    Plot & dataset
%
% Thomas Quettier 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fcc(condition,ref,varargin)

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

condition = {condition};

load(fullfile(datadir,'data_fcc.mat'));

%source selection
source = [1,64;
    1,64;
    1,64;
    1,32;
    1,32;
    1,32;
    33,64;
    33,64;
    33,64;];
%Target selection
target = [1,64;
    1,32
    33,64;
    1,64;
    1,32
    33,64;
    1,64;
    1,32
    33,64];



reftit = strrep(ref,'_left','');
% matrix differences-------------------------
for c = 1:9

    week = weekIncondition(condition);
C= [];
cond=condition{1};
tg= [target(c,1):target(c,2)];
sc= [source(c,1):source(c,2)];
refweek = weekIncondition({ref});
    refweek = refweek(1);

for i = 1:57
  A = X.(sprintf('%s',ref)).(sprintf('W%d', refweek));
  if week(find(week==i))==i
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

X.comparison.(sprintf('%s_W%d',reftit, refweek)).(sprintf('source_%d_%d_target_%d_%d', source(c,1),source(c,2), target(c,1),target(c,2)))= C';

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

tit = strrep(cond,'_',' ');
tit = strrep(tit,'left','');

scl = min([min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_1_64),...
    min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_1_32),...
    min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_33_64),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_1_64),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_1_32),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_33_64),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_1_64),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_1_32),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_33_64)]) - 0.05;


fig=figure();
axis([0 57 round(scl,1) 1]);
xlabel('weeks');
ylabel(sprintf('matrix difference (ref:X.%s W%d)',strrep(reftit,'_',' '), refweek));
xticks([1:57])
xticklabels(string(label));
title(sprintf('fc matrix comparison %s', tit));
hold on;
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_1_64 ,'k-+')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_1_32 ,'k-*')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_33_64 ,'k-o')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_1_64 ,'r-+')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_1_32 ,'r-*')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_33_64 ,'r-o')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_1_64 ,'b-+')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_1_32 ,'b-*')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_33_64 ,'b-o')
plot([1 57],[val val], 'g-') %empty matrix
plot([7.5 7.5],[scl 1], 'r:')   %stage2
plot([32.5 32.5],[scl 1], 'r:') %stage3
%plot([1 45],[0.0037 0.0037], 'r:') %empty matrix
hold off;
legend({'source F1 F5hand target F1 F5hand','source F1 F5hand target F1','source F1 F5hand target F5hand'...
    ,'source F1 target F1 F5hand','source F1 target F1','source F1 target F5hand'...
    ,'source F5hand target F1 F5hand','source F5hand target F1','source F5hand target F5hand','no FC matrix'},'Location','southeast')

% save data
cond = strrep(cond,'_left','');
X=X.comparison.(sprintf('%s_W%d',reftit, refweek));
saveas(fig, fullfile(params.output_path, sprintf('fc_matrix_comparison_%s_ref_%s.png',cond,reftit)));
savefig(fig, fullfile(params.output_path,sprintf( 'fc_matrix_comparison_%s_ref_%s.fig',cond,reftit)));
save(fullfile(params.output_path,sprintf( 'fc_matrix_comparison_%s_ref_%s.mat',cond,reftit)),'X');
