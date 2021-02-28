% lm matrix comparison vs trials weigth 
%
% Thomas Quettier
% 02/2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mdl = mdl_full(slcs,ref)


dir = '/Users/thomasquettier/Documents/GitHub/tool_learning/output/functional_connectivity/';

dist_metric='euclidean';
load(fullfile(dir,'fcc_dataset.mat'));

%% matrix differences-------------------------

n_days=40;
distance = NaN(4,n_days); % col: 'real-frobenuis', 'low_CI', 'high_CI'

    
    
psi= 'Psi2';
conditions = {'fixation' 'visual_grasp_left' 'visual_pliers_left' 'visual_rake_pull_left' 'visual_rake_push_left' 'visual_stick_left' 'motor_grasp_left' 'motor_rake_left' 'motor_rake_food_left'};



for m = 1:length(conditions)
  condition = conditions{m};
  slc=slcs;
  if strcmp(slcs, 'F1F1')== true
    src=[1:32];
    tgt=[1:32];
  elseif strcmp(slcs , 'F1F5')== true
    src=[1:32];
    tgt=[33:64];
  elseif strcmp(slcs, 'F5F1')== true
    src=[33:64];
    tgt=[1:32];     
  elseif strcmp(slcs , 'F5F5')== true
    src=[33:64];
    tgt=[33:64];
  end
    
    
    refweek = availableweekIncondition(ref);
    refMat = X.(sprintf('%s',psi)).(sprintf('%s',ref{1})).(sprintf('W%d', refweek(1))); % ref: matrix A
    refMat_sel= refMat(tgt,src);
    

                    
    for i = 1:n_days
        if isfield(X.(sprintf('%s',psi)).(sprintf('%s',condition)),sprintf('W%d', i))
            compMat = X.(sprintf('%s',psi)).(sprintf('%s',condition)).(sprintf('W%d', i)); % matrix B
     
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

            end
        end
    end
    
    



% trials info

trialsTable(:,1) = trialnb('fixation');
trialsTable(:,2) = trialnb('visual_grasp_left');
trialsTable(:,3) = trialnb('visual_pliers_left'); 
trialsTable(:,4) = trialnb('visual_rake_pull_left'); 
trialsTable(:,5) = trialnb('visual_rake_push_left'); 
trialsTable(:,6) = trialnb('visual_stick_left'); 
trialsTable(:,7) = trialnb('motor_grasp_left'); 
trialsTable(:,8) = trialnb('motor_rake_left');
trialsTable(:,9) = trialnb('motor_rake_food_left');

end

trialsTable(6,1) = NaN;
trialsTable(26,4) = NaN;
trialsTable(27,4) = NaN;
trialsTable(29,4) = NaN;
trialsTable(30,4) = NaN;
trialsTable(31,4) = NaN;
trialsTable(32,4) = NaN;



%%

    cond = strrep(strrep(conditions{m},'_',' '),'left','');
    
    
    A = [trialsTable(:,1); 
         trialsTable(:,2); 
         trialsTable(:,3);
         trialsTable(:,4);
         trialsTable(:,5);
         trialsTable(:,6);
         trialsTable(:,7);
         trialsTable(:,8);
         trialsTable(:,9)];
    B = [distance(1,:)'; 
         distance(2,:)'
         distance(3,:)';
         distance(4,:)';
         distance(5,:)';
         distance(6,:)';
         distance(7,:)';
         distance(8,:)';
         distance(9,:)'];
    B(B==0) = NaN;
     A = A(~isnan(A));
     B = B(~isnan(B));
     if A(1) == 0
         A = A(2:end);
         B = B(2:end);
     else
     end
     
     
    A = sqrt(A);
    mdl = fitlm(A,B);
    intercept = mdl.Coefficients{1,1};
    slope = mdl.Coefficients{2,1};
    
   


      
    %plot(mdl)     
    %title(sprintf('%s itpt %.5f slp %.5f' , slcs{1},intercept,slope),extraInputs{:});
    %ylabel('distance',extraInputs{:});
    %xlabel('trials',extraInputs{:});










