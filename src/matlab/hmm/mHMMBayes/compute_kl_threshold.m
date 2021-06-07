function threshold=compute_kl_threshold(models)

kl_divs=[];
ndeps=size(models(1).emiss_alpha_mat,2);

for i=1:length(models)
    model=models(i);
    for s1=1:model.n_states
        for s2=1:model.n_states
            if s1~=s2
                e_kl_divs=[];
                for e=1:ndeps
                    alpha1=model.emiss_alpha_mat(s1,e);
                    beta1=model.emiss_beta_mat(s1,e);
                    alpha2=model.emiss_alpha_mat(s2,e);
                    beta2=model.emiss_beta_mat(s2,e);
                
                    % Compute KL divergence
                    e_kl_divs(end+1)=.5*(kl_gamma(1/beta1,alpha1,1/beta2,alpha2)+kl_gamma(1/beta2,alpha2,1/beta1,alpha1));
                end
                kl_divs(end+1)=sum(e_kl_divs);
            end
        end
    end
end
threshold=2*min(kl_divs);