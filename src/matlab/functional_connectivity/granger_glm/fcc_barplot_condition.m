% matrix comparison barplot
%
% FC matrix comparison
% INPUT:    ref:        reference condition for comparison
% OUTPUT:   Plot & dataset
%
% Thomas Quettier
% 09/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fcc_barplot_stage(condition,maxstage,varargin)

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

% data
name = {};
p=zeros(length(condition),6);

if maxstage == 1
    stageend = 1;
elseif maxstage == 2
    stageend = 3;
elseif maxstage == 3
   stageend = 6;
end

for co = 1:stageend
    
 nametemp =   strrep(condition{1},'_left','');

 if co == 1
 fcc_permutated_mean(condition{1},{'1'},'output_path',datadir);
 stage = 'stage 1';
    name{co,1} = stage;
 elseif co == 2
  fcc_permutated_mean(condition{1},{'2'},'output_path',datadir);
    stage = 'stage 2';
    name{co,1} = stage;
    elseif co == 3
  fcc_permutated_mean(condition{1},{'1','2'},'output_path',datadir);
    stage = 'stage 1:2';
    name{co,1} = stage;
    elseif co == 4
  fcc_permutated_mean(condition{1},{'3'},'output_path',datadir);
    stage = 'stage 3';
    name{co,1} = stage;
    elseif co == 5
  fcc_permutated_mean(condition{1},{'2','3'},'output_path',datadir);
    stage = 'stage 2:3';
    name{co,1} = stage;
    elseif co == 6
  fcc_permutated_mean(condition{1},{'1','2','3'},'output_path',datadir);
    stage = 'stage 1:3';
    name{co,1} = stage;
 end
 
 
 
load(fullfile(datadir,sprintf('fcc_%s_permutated_mean.mat',nametemp)));


% extract permutated mean from perm_mean structure (fcc_<reftit>_permutated_mean.mat)
fnames = fieldnames(perm_mean);


for i = 1:9
  p(co,i)=perm_mean.(sprintf('%s',fnames{i})) ;
    fnames(i) = strrep(fnames(i),'_',' ');
    fnames(i) = strrep(fnames(i),'1 32','F1');
    fnames(i) = strrep(fnames(i),'33 64','Ff5hand');
    fnames(i) = strrep(fnames(i),'1 64','F1:Ff5hand');
end
end






stage = 'stage 1:3';





%% plot


% figure
fig=figure();
X = categorical(name);
title(sprintf('PERMUTATED MEAN; %s',stage));
hold on;
bar(X,p)
hold off;
legend(fnames,'Location','southeast')

% save data
barplot.electrodes = fnames;
barplot.val = p;
barplot.condition = name;
X=barplot;
saveas(fig, fullfile(params.output_path, 'barplot.png'));
savefig(fig, fullfile(params.output_path,'barplot.fig'));
save(fullfile(params.output_path,'barplot.mat'),'X');
