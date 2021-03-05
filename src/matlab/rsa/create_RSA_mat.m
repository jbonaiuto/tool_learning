function RSAmat=create_RSA_mat(condition_vec)

%load(fname);
% condition_vec=normalise(condition_vec,1);
% RSAmat=zeros(size(condition_vec,1),size(condition_vec,1));
% for i=1:size(condition_vec,1)
%    for j=1:size(condition_vec,1)
%       % 1-correlation between condition i and condition j
%       RSAmat(i,j)=corr(condition_vec(i,:)',condition_vec(j,:)','type','spearman');
%    end
% end


RSAmat = corrcoef(normalise(condition_vec,1)'); %this line of code calculates the RSA matrix