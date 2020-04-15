%% Matrix comparison 02/2020
% 1-mean(abs(A-B)) for two matrices A and B
% result is 1 if they are identical and 0 if they are completely different.
% INPUT        'granger_glm_results.mat'
% X:            Week number
% condition:    'visual' or 'motor' matrix
% OUTPUT:       struct
%
%% Thomas Quettier
function matrix_comp=matrix_comp(Matrix_A,Matrix_B,alignment,varargin)

%'/Users/thomasquettier/Desktop/tool_learning_master/output/functional_connectivity';
defaults=struct('input_path', '/Users/thomasquettier/Desktop/tool_learning_master//output/functional_connectivity',...
    'output_path', '../../../../output/functional_connectivity');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end


 %% Alignment.
% _whole_trial 
% _trial_start 
% _tool_mvmt_onset 
% _reward _place 
% _obj_contact
% _hand_mvmt_onset 
% _go 
% _fix_on
        foldernameA = sprintf('Week_%d_%s', Matrix_A,alignment); 
        foldernameB = sprintf('Week_%d_%s',Matrix_B,alignment);



A= load(fullfile(params.input_path,foldernameA,'granger_glm_results.mat'));
B=load(fullfile(params.input_path,foldernameB,'granger_glm_results.mat'));


APSI1= A.granger_glm_results.causal_results.Psi1;
BPSI1= B.granger_glm_results.causal_results.Psi1;

APSI2= A.granger_glm_results.causal_results.Psi2;
BPSI2= B.granger_glm_results.causal_results.Psi2;


matrix_comp.AB_Psi1= 1-mean(abs(APSI1-BPSI1),'all');
matrix_comp.AB_Psi2= 1-mean(abs(APSI2-BPSI2),'all');
matrix_comp.comparison = sprintf('Week_%d_vs_Week_%d_%s',Matrix_A,Matrix_B,alignment);
 end



