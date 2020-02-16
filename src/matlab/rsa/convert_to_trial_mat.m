function trial_mat=convert_to_trial_mat(n_trials, condition_trials, basic_mat)

trial_mat=zeros(n_trials,n_trials);
for i=1:n_trials
    i_cond=0;
    for k=1:length(condition_trials)
        trials=condition_trials{k};
        if length(find(trials==i))
            i_cond=k;
            break;
        end
    end
    for j=1:n_trials
        j_cond=0;
        for k=1:length(condition_trials)
            trials=condition_trials{k};
            if length(find(trials==j))
                j_cond=k;
                break;
            end
        end
        if i_cond>0 && j_cond>0
            trial_mat(i,j)=basic_mat(i_cond,j_cond);
        else
            disp('condition not found!');
        end
    end
end
