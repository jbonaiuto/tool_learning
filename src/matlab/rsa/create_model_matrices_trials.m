
function model_matrices=create_model_matrices_trials(condition_trials, n_trials)

model_matrices={};
model_matrices{1}.name='visuomotor non-selective';
basic_mat=[ 1 1 1 0 0 0 0 0 0;
            1 1 1 0 0 0 0 0 0;
            1 1 1 0 0 0 0 0 0;
            0 0 0 1 1 1 1 1 1;
            0 0 0 1 1 1 1 1 1;
            0 0 0 1 1 1 1 1 1;
            0 0 0 1 1 1 1 1 1;
            0 0 0 1 1 1 1 1 1;
            0 0 0 1 1 1 1 1 1];
model_matrices{1}.mat=convert_to_trial_mat(n_trials, condition_trials, basic_mat);
               
model_matrices{2}.name='visual - orientation-selective';
basic_mat=[1 0 0 0 0 0 0 0 0;
                       0 1 0 0 0 0 0 0 0;
                       0 0 1 0 0 0 0 0 0;
                       0 0 0 1 0 1 0 1 0;
                       0 0 0 0 1 0 1 0 1;
                       0 0 0 1 0 1 0 1 0;
                       0 0 0 0 1 0 1 0 1;
                       0 0 0 1 0 1 0 1 0;
                       0 0 0 0 1 0 1 0 1];
model_matrices{2}.mat=convert_to_trial_mat(n_trials, condition_trials, basic_mat);
               
model_matrices{3}.name='tool / non-tool';
basic_mat=[1 1 1 1 1 0 0 0 0;    
                       1 1 1 1 1 0 0 0 0;
                       1 1 1 1 1 0 0 0 0;
                       1 1 1 1 1 0 0 0 0;
                       1 1 1 1 1 0 0 0 0;
                       0 0 0 0 0 1 1 1 1;
                       0 0 0 0 0 1 1 1 1;
                       0 0 0 0 0 1 1 1 1;
                       0 0 0 0 0 1 1 1 1];
model_matrices{3}.mat=convert_to_trial_mat(n_trials, condition_trials, basic_mat);
               
model_matrices{4}.name='visuomotor - action-selective';
basic_mat=([1 1 1 1 1 0 0 0 0;   
                        1 1 1 1 1 0 0 0 0;
                        1 1 1 1 1 0 0 0 0;
                        1 1 1 1 1 0 0 0 0;
                        1 1 1 1 1 0 0 0 0;
                        0 0 0 0 0 1 1 0 0;
                        0 0 0 0 0 1 1 0 0;
                        0 0 0 0 0 0 0 1 1;
                        0 0 0 0 0 0 0 1 1]);
model_matrices{4}.mat=convert_to_trial_mat(n_trials, condition_trials, basic_mat);
                    
model_matrices{5}.name='visuomotor - grasp-selective';
basic_mat=([1 1 1 1 1 0 0 0 0;
                        1 1 1 1 1 0 0 0 0;
                        1 1 1 1 1 0 0 0 0;
                        1 1 1 1 1 0 0 0 0;
                        1 1 1 1 1 0 0 0 0;
                        0 0 0 0 0 1 0 0 0;
                        0 0 0 0 0 0 1 0 0;
                        0 0 0 0 0 0 0 1 0;
                        0 0 0 0 0 0 0 0 1]);
model_matrices{5}.mat=convert_to_trial_mat(n_trials, condition_trials, basic_mat);
                    
model_matrices{6}.name='motor - action-selective';
basic_mat=([1 .5 .25 0 0 0 0 0 0;
                        .5 1 .5 0 0 0 0 0 0;
                        .25 .5 1 0 0 0 0 0 0;
                        0 0 0 1 0 0 0 0 0;
                        0 0 0 0 1 0 0 0 0;
                        0 0 0 0 0 1 0 0 0;
                        0 0 0 0 0 0 1 0 0;
                        0 0 0 0 0 0 0 1 0;
                        0 0 0 0 0 0 0 0 1]);   
model_matrices{6}.mat=convert_to_trial_mat(n_trials, condition_trials, basic_mat);

% model_matrices{7}.name='motor - non-selective';
% model_matrices{7}.mat=([1 1 1 0 0 0 0 0 0;
%                         1 1 1 0 0 0 0 0 0;
%                         1 1 1 0 0 0 0 0 0;
%                         0 0 0 1 0 0 0 0 0;
%                         0 0 0 0 1 0 0 0 0;
%                         0 0 0 0 0 1 0 0 0;
%                         0 0 0 0 0 0 1 0 0;
%                         0 0 0 0 0 0 0 1 0;
%                         0 0 0 0 0 0 0 0 1]); 
                    
% model_mats{10}.name='motor specific visual unspecific';
% model_mats{10}.mat=(1-[0 .25 .5 1 1 1 1 1 1;
%                       0.25 0 .25 1 1 1 1 1 1;
%                       0.50 .25 0 1 1 1 1 1 1;
%                       1 1 1 0 0 0 0 0 0;
%                       1 1 1 0 0 0 0 0 0;
%                       1 1 1 0 0 0 0 0 0;
%                       1 1 1 0 0 0 0 0 0;
%                       1 1 1 0 0 0 0 0 0;
%                       1 1 1 0 0 0 0 0 0])*2-1;
% model_mats{11}.name='motor specific visual specific';
% model_mats{11}.mat=(1-[0 .25 .5 1 1 1 1 1 1;
%                       0.25 0 .25 1 1 1 1 1 1;
%                       0.50 .25 0 1 1 1 1 1 1;
%                       1 1 1 0 .5 1 1 1 1;
%                       1 1 1 0.5 0 1 1 1 1;
%                       1 1 1 1 1 0 .5 1 1;
%                       1 1 1 1 1 .5 0 1 1;
%                       1 1 1 1 1 1 1 0 0.5;
%                       1 1 1 1 1 1 1 0.5 0])*2-1;
%                   
% for idx=1:length(model_mats)
%     model_mats{idx}.mat=2*(model_mats{idx}.mat-.5);
% end