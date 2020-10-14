% suffled frobenius norm comparison
%
% FC matrix comparison by using frobenius norm. 
% INPUT:    condition:  condition for comparison
%           ref:        reference condition for comparison
%           source : array(s) from FC matrix
%           target : array(s) from FC matrix
%
%           optional: 
%           nb_simulation: number of simulation (default 100)
%           CI_p:          Confident interval probability (default 95%)
%
% OUTPUT:    Plot & dataset
%
% Thomas Quettier
% 09/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function suffled_frobenius(condition,ref,source,target,varargin)

% Parse optional arguments
defaults=struct( 'output_fname', 'granger_glm_results.mat',...
    'output_path', '../../../../output/functional_connectivity',...
    'nb_simulation',1000,...
    'CI_p', 95);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

% data
if exist(fullfile(params.output_path,'fcc_dataset.mat'))
else
fcc_dataset('output_path',params.output_path);
end
load(fullfile(params.output_path,'fcc_dataset.mat'));

%source selection
scr = NaN(1,64);
if any(strcmp(source,'F1'))
scr(1,1:32) = [1:32];
end
if any(strcmp(source,'F5hand'))
scr(1,33:64) = [33:64];
end
scr = scr(~isnan(scr));

%Target selection
tgt = NaN(1,64);
if any(strcmp(target,'F1'))
tgt(1,1:32) = [1:32];
end
if any(strcmp(target,'F5hand'))
tgt(1,33:64) = [33:64];
end
tgt = tgt(~isnan(tgt));


%% matrix differences-------------------------

% function for contuting the confident interval
%CIFcn = @(x,p)std(x(:),'omitnan')/sqrt(sum(~isnan(x(:)))) * tinv(abs([0,1]-(1-p/100)/2),sum(~isnan(x(:)))-1) + mean(x(:),'omitnan'); 
CIFcn = @(x,p)prctile(x,abs([0,100]-(100-p)/2));


week = weekIncondition(condition);
refweek = weekIncondition(ref);
Shuffled_val = NaN(57,params.nb_simulation);
table_val = NaN(57,3); % col: 'real-frobenuis', 'low_CI', 'high_CI'

for i = 1:57
  A = X.(sprintf('%s',ref{1})).(sprintf('W%d', refweek(1))); % ref: matrix A

  if week(find(week==i))==i
  B = X.(sprintf('%s',condition{1})).(sprintf('W%d', week(find(week==i)))); % matrix B
      if isnan(B) 
      else
  table_val(i,1) = norm(A(tgt,scr)-B(tgt,scr),'fro'); % frobenius norm difference
        for j = 1:params.nb_simulation % shuffled B matrix generation loop
            Shuffled_A = A(tgt,scr);
            [rw cl] = size(Shuffled_A);
            Shuffled_A =reshape(Shuffled_A(randperm(rw*cl)),rw,cl);% shuffled A matrix generation 
            Shuffled_B = B(tgt,scr);
            Shuffled_B =reshape(Shuffled_B(randperm(rw*cl)),rw,cl);% shuffled B matrix generation 

           % Shuffled_val(i,j) = norm(A(tgt,scr)-Shuffled_B,'fro'); % frobenius norm difference for shuffled matrix
      
            Shuffled_val(i,j) = norm(Shuffled_A-Shuffled_B,'fro'); % frobenius norm difference for shuffled matrix

        end
                x = Shuffled_val(i,1:params.nb_simulation); % CI computation by week
            p=params.CI_p; % alfa
            CI = CIFcn(x,p); % CI computation (see function 
            table_val(i,2:3)= CI;
            
  end
  else 
  end
      

 end



reftit = strrep(ref,'_left','');
reftit = strrep(ref{1},'_',' ');
reftit = strrep(reftit,'left','');
condtit = strrep(condition{1},'left','');
X.comparison.(sprintf('%s_W%d',reftit, refweek(1))).(sprintf('%s',condtit))=  table_val;





%% plot

% label for axis
label = {};
for i = 1:57
  label{i} = {sprintf('%02d', i)} ;
end
X.label=label';
source = [source{:}];
target = [target{:}];
cond = strrep(strrep(condition{1},'_',' '),'left','');

scalemax = max(table_val(:,3))+1;
scalemmin = min(table_val(:,2))-1;

% figure
fig=figure();
set(gcf,'position',[200,200,1400,500]);
extraInputs = {'interpreter','latex','fontsize',16};
xlabel('weeks',extraInputs{:});
ylabel(sprintf('matrix difference (ref:X.%s.W%d)',reftit, refweek(1)),extraInputs{:})
xticks([1:57])
xticklabels(string(label));
title(sprintf('Frobenius Norm comparison %s source %s, target %s', cond ,source, target),extraInputs{:});
hold on;
%plot(Shuffled_val ,'r-+')
plot(table_val(:,3) ,'r:v')
plot(table_val(:,2) ,'R:^')
plot(table_val(:,1) ,'k-*')
plot([7.5 7.5],[scalemmin scalemax], 'k:')   %stage2
plot([32.5 32.5],[scalemmin scalemax], 'k:') %stage3
plot(57,scalemmin, 'w:') % all weeks
hold off;
legend({sprintf('CI %d upper bound (%d simulations)',params.CI_p,params.nb_simulation),sprintf('CI %d lower bound (%d simulations) ',params.CI_p,params.nb_simulation),sprintf('%s source %s, target %s', cond ,source, target)},'Location','northeast',extraInputs{:})

% save data
X=X.comparison.(sprintf('%s_W%d',reftit, refweek(1)));
saveas(fig, fullfile(params.output_path, sprintf('SFN_%s_src_%s_tgt_%s_ref_%s.png',condtit,source,target,reftit)));
savefig(fig, fullfile(params.output_path,sprintf('SFN_%s_src_%s_tgt_%s_ref_%s.fig',condtit,source,target,reftit)));
save(fullfile(params.output_path,sprintf('SFN_%s_src_%s_tgt_%s_ref_%s.mat',condtit,source,target,reftit)),'X');

%END

