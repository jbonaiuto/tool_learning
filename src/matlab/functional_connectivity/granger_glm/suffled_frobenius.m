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
function suffled_frobenius(condition,ref,varargin)

% Parse optional arguments
defaults=struct( 'output_fname', 'granger_glm_results.mat',...
    'output_path', '../../../../output/functional_connectivity',...
    'nb_simulation',1000,...
    'CI_p', .05);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end

load(fullfile(params.output_path,'fcc_dataset.mat'));

dist_metric='euclidean';

%% matrix differences-------------------------

% function for contuting the confident interval
CIFcn = @(x,p)prctile(x,abs([0,100]-(100-p)/2));

n_days=40;
corrected_CI_p=(1-params.CI_p/n_days)*100;
distance = NaN(4,n_days); % col: 'real-frobenuis', 'low_CI', 'high_CI'
low_ci = NaN(4,n_days);
high_ci = NaN(4,n_days);
    
    
psi= 'Psi1';
slcs={'F1F1','F1F5','F5F1','F5F5'};
srcs=[1:32;1:32;33:64;33:64];
tgts=[1:32;33:64;1:32;33:64];

for m = 1:length(slcs)
    slc=slcs{m};
    src=srcs(m,:);
    tgt=tgts(m,:);
    
    slc
    % lm
    mdl = mdl_full(slc,ref);
    % trialnb
   1;
    reftnb = trialnb('fixation');
    
    
    refweek = weekIncondition(ref);
    
    refMat = X.(sprintf('%s',psi)).(sprintf('%s',ref{1})).(sprintf('W%d', refweek(1))); % ref: matrix A
    refMat_sel= refMat(tgt,src);
                 
    
     
         
    for i = 1:n_days
        if strcmp(condition , ref)== true & refweek(1)==i
     else
        
        if isfield(X.(sprintf('%s',psi)).(sprintf('%s',condition{1})),sprintf('W%d', i))
            
            compMat = X.(sprintf('%s',psi)).(sprintf('%s',condition{1})).(sprintf('W%d', i)); % matrix B
          
            if ~isnan(compMat)
                
               
                
                % Get just the portion we are interested in
                compMat_sel=compMat(tgt,src);
                
                % Figure out the max distance
                [rw cl] = size(refMat_sel);
                negMat=-1.*ones(rw,cl);
                posMat=ones(rw,cl);
                maxDist=pdist([negMat(:)'; posMat(:)'],dist_metric);
                
                % Compuate distance as a proportion of max distance
                distance(m,i) = pdist([refMat_sel(:)'; compMat_sel(:)'],dist_metric)/maxDist;
                %correction y-(m*sqrt(trials)+b)
                distance(m,i) =  distance(m,i)-(mdl.Coefficients{2,1} * sqrt(tnb(i))' + mdl.Coefficients{1,1});
                
                shuffled_distance = NaN(params.nb_simulation,1);
                
                
                for j = 1:params.nb_simulation % shuffled B matrix generation loop
                    % Generate random matrix with same proportion of -1, 0, and 1 to reference                   
                    num_neg=length(find(refMat_sel(:)==-1));
                    num_zero=length(find(refMat_sel(:)==0));
                    num_pos=length(find(refMat_sel(:)==1));
                    ratios=[num_neg num_zero num_pos]./(rw*cl);
                    rand_refMat=reshape(randsample([-1 0 1],rw*cl,true,ratios),rw,cl);
                    
                    shuffled_distance(j) = pdist([rand_refMat(:)'; refMat_sel(:)'],dist_metric)/maxDist;
                        
                end
                % lm for ref CI
               nbtref(1:length(shuffled_distance(:,1)),1) = reftnb(6);
               refmdl = fitlm(nbtref,shuffled_distance);
                    shuffled_distance =  shuffled_distance-(refmdl.Coefficients{2,1}*sqrt(reftnb(6))'+refmdl.Coefficients{1,1});
                CI = CIFcn(shuffled_distance,corrected_CI_p); % CI computation (see function
                
                
                low_ci(m,i)= CI(1);
                high_ci(m,i)= CI(2);
            end
        end
        
        end
    end
    %% correction





 
    
end


%% plot

% label for axis
label = {};
for i = 1:n_days
    label{i} = {sprintf('%02d', i)} ;
end

cond = strrep(strrep(condition{1},'_',' '),'left','');

scalemax = max([distance(:); low_ci(:); high_ci(:)])+0.01;
scalemin = min([distance(:); low_ci(:); high_ci(:)])-0.01;

%correction



fig=figure();
set(gcf,'position',[200,200,1400,1000]);

for m = 1:length(slcs)
    slc=slcs{m};
    subplot(length(slcs),1,m);
    extraInputs = {'interpreter','latex','fontsize',12};
    xlabel('week',extraInputs{:});
    ylabel('distance',extraInputs{:})
    xticks([1:n_days])
    xticklabels(string(label));
    title(sprintf('%s %s', cond ,slc),extraInputs{:});
    hold on;
    plot(high_ci(m,:) ,'r:v')
    plot(low_ci(m,:) ,'R:^')
    plot(distance(m,:) ,'k-*')
    ylim([scalemin,scalemax]);
    plot([7.5 7.5],ylim(), 'b')   %stage2
    plot([32.5 32.5],ylim(), 'b') %stage3
    hold off;
    legend({'CI upper bound','CI lower bound'},'Location','northeast',extraInputs{:})
end


saveas(fig, fullfile(params.output_path, sprintf('F_%s_ref_%s.png',strrep(condition{1},'_left',''),ref{1})));
%save(fullfile(params.output_path,sprintf('SFN_%s_src_%s_tgt_%s_ref_%s.mat',cond,source,target,reftit)),'X');

