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
function fcc_barplot_stage(condition,stage,varargin)

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
p=zeros(length(condition),9);

for co = 1:length(condition)
    
 nametemp =   strrep(condition{co},'_left','');
 name{co,1} = strrep(nametemp,'_',' ');
 fcc_permutated_mean(condition{co},stage,'output_path',datadir);

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


% Stage
st1 = 0;
st2 = 0;
st3 = 0;
if any(strcmp(stage,'1'))
st1 = 1;
end
if any(strcmp(stage,'2'))
st2 = 3;
end
if any(strcmp(stage,'3'))
st3 = 5;
end


if st1+st2+st3 ==1
stage = 'stage 1';
elseif st1+st2+st3 ==3
stage = 'stage 2';
elseif st1+st2+st3 ==5
stage = 'stage 3';
elseif st1+st2+st3 == 4
stage = 'stage 1:2';
elseif st1+st2+st3 == 9
stage = 'stage 1:3';
elseif st1+st2+st3 ==8
stage = 'stage 2:3';
end


%d=p(1,:)-p;
%d(1,:)=p(1,:);
%p=d;
%% plot


% figure
fig=figure();
if length(name)==1
X = categorical(fnames);
title(sprintf('PERMUTATED MEAN; %s %s',name{1},stage));
else
X = categorical(name);
title(sprintf('PERMUTATED MEAN; %s',stage));
end
hold on;
bar(X,p)
hold off;
if length(name)==1
else
legend(fnames,'Location','southeast')
end
% save data
barplot.electrodes = fnames;
barplot.val = p;
barplot.condition = name;
X=barplot;
saveas(fig, fullfile(params.output_path, 'barplot.png'));
savefig(fig, fullfile(params.output_path,'barplot.fig'));
save(fullfile(params.output_path,'barplot.mat'),'X');
