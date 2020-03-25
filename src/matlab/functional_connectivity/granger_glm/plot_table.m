%% trial plot 02/2020
%
% Inter-weeks plots table CSV
%
%% Thomas Quettier
function plot_table=plot_table(week,condition,varargin)

%'/Users/thomasquettier/Desktop/tool_learning_master/output/functional_connectivity';

defaults=struct('output_path', '../../../../output/functional_connectivity',...
    'input_path', '../../../../output/functional_connectivity');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end


%load data
X= {};
X.psi={};
X.phi={};
for idx_week =1:length(week)
        foldername = sprintf('Week_%d_%s', week(idx_week),condition); 
  

load(fullfile(params.input_path,foldername,'granger_glm_results.mat'));

X.phi{idx_week}= granger_glm_results.causal_results.Phi;  
X.psi{idx_week}= granger_glm_results.causal_results.Psi2; 
end

% axis size
phi=X.phi{1};
[target source] = size(phi);
Yaxis = {};

idx= 1;
for Y_idx = 1:(target/2) % electrodes name generation
    for X_idx = 1:(source/2)
      Yaxis{idx,1} = sprintf('F%02d_to_F%02d', Y_idx,X_idx);

      idx=idx+ 1;
    end
end
Yaxis = cell2mat(Yaxis);


%% masking
for i = 1:length(week)
    bin_idx=find(X.psi{i} == 0);
    X.masked{i}= X.phi{i};
    X.masked{i}(bin_idx)= NaN;
end

% 4 matrices
for i = 1:length(week)
X.F1F1{i} = X.masked{i}(1:(target/2),1:(source/2));
X.F1F5{i} = X.masked{i}(1:(target/2),(source/2)+1:source);
X.F5F5{i} = X.masked{i}((target/2)+1:target,1:(source/2));
X.F5F1{i} = X.masked{i}((target/2)+1:target,(source/2)+1:source);
end


%test
data = [];
weeks = [];
for i = 1:length(week)
F1F1  = reshape(X.F1F1{1,i},[],1);
F1F5  = reshape(X.F1F5{1,i},[],1);
F5F5  = reshape(X.F5F5{1,i},[],1);
F5F1  = reshape(X.F5F1{1,i},[],1);
weeks = repmat(i,[size(F1F1),1]);
table = [weeks,F1F1, F1F5, F5F5, F5F1];
data = vertcat(data, table);
end



csvwrite(fullfile(params.output_path,sprintf('%s_plot.csv',condition)),data)
end


%     end


