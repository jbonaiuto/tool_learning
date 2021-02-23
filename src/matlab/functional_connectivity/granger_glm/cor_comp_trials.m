% Corelation matrix comparison vs trials weigth 
%
% Thomas Quettier
% 02/2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function binomial = cor_comp_trials(condition,ref,varargin)

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

dist_metric='euclidean';
load(fullfile(params.output_path,'fcc_dataset.mat'));

%% matrix differences-------------------------

% function for contuting the confident interval
CIFcn = @(x,p)prctile(x,abs([0,100]-(100-p)/2));

n_days=40;
corrected_CI_p=(1-params.CI_p/n_days)*100;
distance = NaN(4,n_days); % col: 'real-frobenuis', 'low_CI', 'high_CI'
low_ci = NaN(4,n_days);
high_ci = NaN(4,n_days);
    
    
psi= 'Psi2';
slcs={'F1F1','F1F5','F5F1','F5F5'};
srcs=[1:32;1:32;33:64;33:64];
tgts=[1:32;33:64;1:32;33:64];

for m = 1:length(slcs)
    slc=slcs{m};
    src=srcs(m,:);
    tgt=tgts(m,:);
    
    slc
    
    refweek = availableweekIncondition(ref);
    
    refMat = X.(sprintf('%s',psi)).(sprintf('%s',ref{1})).(sprintf('W%d', refweek(1))); % ref: matrix A
    refMat_sel= refMat(tgt,src);
                    
    for i = 1:n_days
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
                CI = CIFcn(shuffled_distance,corrected_CI_p); % CI computation (see function
                low_ci(m,i)= CI(1);
                high_ci(m,i)= CI(2);
            end
        end
        
        
    end
end
%     end

% trials info

if strcmp(condition{1} , 'fixation')== true
    sheet = 3;
elseif strcmp(condition{1} , 'visual_grasp_left')== true
    sheet = 4;
elseif strcmp(condition{1} , 'visual_pliers_left')== true 
    sheet = 5;
elseif strcmp(condition{1} , 'visual_rake_pull_left')== true 
    sheet = 6;
elseif strcmp(condition{1} , 'visual_rake_push_left')== true 
    sheet = 7;
elseif strcmp(condition{1}, 'visual_stick_left')== true 
    sheet = 8;
elseif strcmp(condition{1} , 'motor_grasp_left')== true 
    sheet = 9;
elseif strcmp(condition{1} , 'motor_rake_left')== true 
    sheet = 10;
elseif strcmp(condition{1} , 'motor_rake_center_catch')== true 
    sheet = 11;
elseif strcmp(condition{1} , 'motor_rake_food_left')== true 
    sheet = 12;
end


filename = '/Users/thomasquettier/Documents/GitHub/tool_learning/SummaryBetta.xlsx';
  xlRange = 'J3:N42';
trials = xlsread(filename,sheet,xlRange);




%% plot

% label for axis
label = {};
for i = 1:n_days
    label{i} = {sprintf('%02d', i)} ;
end

cond = strrep(strrep(condition{1},'_',' '),'left','');

scalemax = max([distance(:); low_ci(:); high_ci(:)])+0.01;
scalemin = min([distance(:); low_ci(:); high_ci(:)])-0.01;



fig=figure();
%set(gcf,'position',[200,200,1400,1000]);

for m = 1:length(slcs)
    A = trials(:,5);
    B = distance(m,:)';
     A = A(~isnan(A));
     B = B(~isnan(B));
     if A(1) == 0
         A = A(2:end);
         B = B(2:end);
     else
     end
     
    [r,p] = corr(A,B);
    mdl = fitlm(A,B);
    intercept = mdl.Coefficients{1,1};
    slope = mdl.Coefficients{2,1};
    
   
    
    slc=slcs{m};
    subplot(2,2,m);
    extraInputs = {'interpreter','latex','fontsize',12};
   
   % title(sprintf('%s %s cor = %.2f' , cond ,slc,r),extraInputs{:});

    hold on
    %gscatter(A,B);
    plot(mdl)
           
    title(sprintf('%s %s itpt %.5f slp %.5f' , cond ,slc,intercept,slope),extraInputs{:});

 ylabel('distance',extraInputs{:});
    xlabel('trials',extraInputs{:});
end


saveas(fig, fullfile(params.output_path, sprintf('cor_%s_ref_%s.png',strrep(condition{1},'_left',''),ref{1})));







