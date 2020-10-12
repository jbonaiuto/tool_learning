% Compute mean from permutation
%
% FC matrix comparison
% INPUT:    ref : single condition
% OUTPUT:    shuffled <ref> mean.mat 
%
% Thomas Quettier 
% 28/09/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fcc_permutated_mean(ref,stage,varargin)

% Parse optional arguments
defaults=struct( 'output_fname', 'shuffled_mean.mat',...
    'output_path', '../../../../output/functional_connectivity');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end
datadir = params.output_path;


% data
load(fullfile(datadir,'fcc_dataset.mat'));
condition = {ref};
reftit = strrep(ref,'_left','');

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

% Stage
st1 = [];
st2 = [];
st3 = [];
if any(strcmp(stage,'1'))
st1 = 1:7;
end
if any(strcmp(stage,'2'))
st2 = 8:32;
end
if any(strcmp(stage,'3'))
st3 = 33:57;
end
stage = [st1 st2 st3];


% permutated matrix comparison
for c = 1:9

    week = weekIncondition(condition);
    week= stage(ismember(stage,week));
    
C= [];

tg= [target(c,1):target(c,2)];
sc= [source(c,1):source(c,2)];


  perm = nchoosek(week,2); 
for i = 1:length(perm(:,1))
  A = X.(sprintf('%s',ref)).(sprintf('W%d', perm(i,1)));
  
  B = X.(sprintf('%s',ref)).(sprintf('W%d', perm(i,2)));
      if isnan( B) | isnan( A) 
            C = [C NaN];
      else
        
  val = 1-mean(abs(A(tg,sc)-B(tg,sc)),'all');
  C = [C val];
      end
  
end

X.(sprintf('%s_perms', reftit)).(sprintf('source_%d_%d_target_%d_%d', source(c,1),source(c,2), target(c,1),target(c,2)))= C';

end



% all source and target mean comparison
for c = 1:9

A = X.(sprintf('%s_perms', reftit)).(sprintf('source_%d_%d_target_%d_%d', source(c,1),source(c,2), target(c,1),target(c,2)));
X.(sprintf('%s_perms', reftit)).shuffled_mean.(sprintf('source_%d_%d_target_%d_%d', source(c,1),source(c,2), target(c,1),target(c,2)))=nanmean(A);

end


% save data
perm_mean = X.(sprintf('%s_perms', reftit)).shuffled_mean;
save(fullfile(params.output_path,sprintf('fcc_%s_permutated_mean.mat', reftit)),'perm_mean');



