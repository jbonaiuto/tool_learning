function model2=align_models(model1, model2)


% Get number of states and electrodes
n_states1=model1.n_states;
n_states2=model2.n_states;
ndeps=size(model1.emiss_alpha_mat,2);


% Initialize new state labels
new_state_labels=model2.metadata.state_labels;

% States that have already been matched
m1_matched=[];
m2_matched=[];

% Match until can't go any further
matched=true;

while matched

    % Distance between each combination of model1/model2
    % states
    state_distance=[];
    
    % States that have not already been matched
    s1_left=setdiff([1:n_states1],m1_matched);
    s2_left=setdiff([1:n_states2],m2_matched);
    
    % Go through each combination of model1 and model2
    % states that haven't yet been matched
    if length(s1_left)>0 && length(s2_left)>0
        for i=1:length(s1_left)
            s1=s1_left(i);
            for j=1:length(s2_left)
                s2=s2_left(j);
            
                % Compute KL divergence for each electrode
                kl_divs=[];
                for e=1:ndeps
                    % Gamma distribution parameters from model1
                    % and model2
                    alpha1=model1.emiss_alpha_mat(s1,e);
                    beta1=model1.emiss_beta_mat(s1,e);
                    alpha2=model2.emiss_alpha_mat(s2,e);
                    beta2=model2.emiss_beta_mat(s2,e);
                
                    % Compute KL divergence
                    kl_divs(e)=kl_gamma(1/beta1,alpha1,1/beta2,alpha2);
                
                end
                % Add sum of KL divergence across electrodes to list
                state_distance(end+1,:)=[s1 s2 mean(kl_divs)];
            end
        end
    
        % Sort by distance
        [~,sorted_idx]=sort(state_distance(:,3));
        state_distance=state_distance(sorted_idx,:);
        
        %  Update new state labels
        s1=state_distance(1,1);
        s2=state_distance(1,2);
        
        new_state_labels{s2}=model1.metadata.state_labels{s1};
        
        % Add to list of matched states
        m1_matched(end+1)=s1;
        m2_matched(end+1)=s2;
    else
        matched=false;
    end
end

% Find any states in model2 that haven't been matched
s2_left=setdiff([1:n_states2],m2_matched);
if length(s2_left)>0
    % Max state label
    max_lbl=max(cellfun(@str2num,cat(2,model1.metadata.state_labels,new_state_labels(m2_matched))));
    
    % Relabel remaining states and increment max state
    % label
    for i=1:length(s2_left)
        new_state_labels{s2_left(i)}=num2str(max_lbl+1);
        max_lbl=max_lbl+1;
    end
end

% Update state labels
model2.metadata.state_labels=new_state_labels;
