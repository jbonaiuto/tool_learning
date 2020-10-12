% matrix comparison plot by condition
%
% FC matrix comparison
% INPUT:    condition : single condition
%           ref:        refeerence condition for comparison
% OUTPUT:    Plot & dataset
%
% Thomas Quettier
% 09/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fcc_full_electrodes(condition,ref,stage,varargin)

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
reftit = strrep(ref,'_left','');

% data
fcc_permutated_mean(ref,stage,'output_path',datadir);
load(fullfile(datadir,'fcc_dataset.mat'));
load(fullfile(datadir,sprintf('fcc_%s_permutated_mean.mat',reftit)));

% extract permutated mean from perm_mean structure (fcc_<reftit>_permutated_mean.mat)
fnames = fieldnames(perm_mean);
p=[];

for i = 1:length(fnames)
   val=perm_mean.(sprintf('%s',fnames{i})) ;
     p = [p val];
end
fixmax = max(p); % min, max, full electrodes mean for plot
fixmin = min(p);
fixall = perm_mean.source_1_64_target_1_64; 

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

% matrix differences
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
        
  val = norm(A(tg,sc)-B(tg,sc),'fro');
  %1-mean(abs(A(tg,sc)-B(tg,sc)),'all'); x = reshape(randperm([B]))
  C = [C val];
  end
  else 
      C = [C NaN];
  end
  
end

X.comparison.(sprintf('%s_W%d',reftit, refweek)).(sprintf('source_%d_%d_target_%d_%d', source(c,1),source(c,2), target(c,1),target(c,2)))= C';

end

%% plot

% label for axis
label = {};
for i = 1:57
  label{i} = {sprintf('%02d', i)} ;
end
X.label=label';

% ref name for legend
tit = strrep(cond,'_',' ');
tit = strrep(tit,'left','');
fixmaxname = strrep(char(fnames{find(p==fixmax)}),'_',' ');
fixmaxname = strrep(fixmaxname,'1 32','F1');
fixmaxname = strrep(fixmaxname,'33 64','F5hand');
fixmaxname = strrep(fixmaxname,'1 64','F1 Ff5hand ');
fixminname = strrep(char(fnames{find(p==fixmin)}),'_',' ');
fixminname = strrep(fixminname,'1 32','F1');
fixminname = strrep(fixminname,'33 64','Ff5hand');
fixminname = strrep(fixminname,'1 64','F1 Ff5hand');


% find scale value for axis
scl = min([min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_1_64),...
    min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_1_32),...
    min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_33_64),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_1_64),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_1_32),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_33_64),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_1_64),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_1_32),...
min(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_33_64)]) - 0.05;

% figure
fig=figure();
axis([0 57 round(scl,1) 1]);
xlabel('weeks');
ylabel(sprintf('matrix difference (ref:X.%s W%d)',strrep(reftit,'_',' '), refweek));
xticks([1:57])
xticklabels(string(label));
title(sprintf('fc matrix comparison %s', tit));
hold on;
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_1_64 ,'g--^')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_1_32 ,'g:*')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_64_target_33_64 ,'g-o')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_1_64 ,'r--^')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_1_32 ,'r:*')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_1_32_target_33_64 ,'r-o')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_1_64 ,'b--^')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_1_32 ,'b:*')
plot(X.comparison.(sprintf('%s_W%d',reftit, refweek)).source_33_64_target_33_64 ,'b-o')
plot([1 57],[fixall fixall], 'k-') %max mean
plot([1 57],[fixmax fixmax], 'k--') %max mean
plot([1 57],[fixmin fixmin], 'k-.') %min mean
plot([7.5 7.5],[scl 1], 'k:')   %stage2
plot([32.5 32.5],[scl 1], 'k:') %stage3
%plot([1 45],[0.0037 0.0037], 'r:') %empty matrix
hold off;
legend('source F1 F5hand target F1 F5hand','source F1 F5hand target F1','source F1 F5hand target F5hand'...
    ,'source F1 target F1 F5hand','source F1 target F1','source F1 target F5hand'...
    ,'source F5hand target F1 F5hand','source F5hand target F1','source F5hand target F5hand'...
    ,sprintf('%s full matrix mean',strrep(reftit,'_',' ')),sprintf('ref max mean %s',fixmaxname),sprintf('ref min mean %s',fixminname),'Location','southeast')

% save data
cond = strrep(cond,'_left','');
X=X.comparison.(sprintf('%s_W%d',reftit, refweek));
saveas(fig, fullfile(params.output_path, sprintf('fcc_%s_ref_%s.png',cond,reftit)));
savefig(fig, fullfile(params.output_path,sprintf( 'fcc_%s_ref_%s.fig',cond,reftit)));
save(fullfile(params.output_path,sprintf( 'fcc_%s_ref_%s.mat',cond,reftit)),'X');
