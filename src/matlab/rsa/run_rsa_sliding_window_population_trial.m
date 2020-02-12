function run_rsa_sliding_window_population_trial(exp_info, subject, array_idx)

addpath('../spike_data_processing');

conditions={'motor_grasp_left','motor_grasp_center','motor_grasp_right',...
    'visual_grasp_left','visual_grasp_right','visual_pliers_left','visual_pliers_right',...
    'visual_rake_pull_left','visual_rake_pull_right'};
condition_labels={};
for i=1:length(conditions)
    condition_labels{i}=strrep(conditions{i},'_', ' ');
end

array=exp_info.array_names{array_idx};
align_evts={'go','hand_mvmt_onset','obj_contact','place'};
align_wois=[-250 250;-250 200;-100 250;-250 250];

fname=sprintf('%s_stage1_%s_%s.mat', subject, array, align_evts{1});
load(fullfile('../../../output',fname));
condition_trials={};
t_idx=1;
for c_idx=1:length(conditions)    
    % Find trials for this condition
    condition=conditions{c_idx};
    trials=find(strcmp(data.metadata.condition,condition));
    condition_trials{c_idx}=[t_idx:(t_idx-1)+length(trials)];
    t_idx=t_idx+length(trials);
end
n_trials=t_idx-1;

model_matrices=create_model_matrices_trials(condition_trials, n_trials);
model_labels={};
fig=figure('Position',[1 1 1980 1080],'PaperPosition',[0 0 64 64], 'PaperUnits','inches');
for i=1:length(model_matrices)
    model_mat=model_matrices{i};
     ax=subplot(3,4,i);
     plot_RDM(ax, model_mat.mat, condition_labels, strrep(model_mat.name,'_',' '),...
         [0 1], 'colorbar', true);
    model_labels{i}=strrep(model_mat.name,'_',' ');
end

figure();
color=cbrewer('qual','Paired',12);

for ae_idx=1:length(align_evts)
    align_event=align_evts{ae_idx};
    woi=align_wois(ae_idx,:);

    fname=sprintf('%s_stage1_%s_%s.mat', subject, array, align_event);
    load(fullfile('../../../output',fname));
    data=compute_firing_rate(data,'win_len',120,'baseline_type','condition');
    
    trial_fr=zeros(n_trials,exp_info.ch_per_array,length(data.bins)-1);
    all_t_idx=1;
    % Convolved firing rate for each trial
    conv_fr=zeros(length(trials),exp_info.ch_per_array,length(data.bins)-1);
    for e_idx=1:exp_info.ch_per_array
        for c_idx=1:length(conditions)    
            % Find trials for this condition
            condition=conditions{c_idx};
            trials=find(strcmp(data.metadata.condition,condition));
            for t_idx=1:length(trials)
                trial_rate=squeeze(data.firing_rate(1,e_idx,trials(t_idx),1:end-1));
                if ~any(isinf(trial_rate))
                    trial_fr(all_t_idx,e_idx,:)=conv2(1,ones(1,200)./200,trial_rate','same');
                end
                all_t_idx=all_t_idx+1;
            end        
        end
    end
        
    dat = squeeze(mean(conv_fr,3));
    ok = ~all(dat==0);
    RSAmat=create_RSA_mat(dat(:,ok));
    RSAdat = RSAmat(:);
    
    % mean regressor
    r1 = ones(length(conditions),length(conditions));
    % identity regressor
    r2 = eye(length(conditions));
    %build design matrix:
    design_matrix = [r1(:) r2(:)];
    for i=1:length(model_matrices)
        % add model matrix
        model_mat=model_matrices{i}.mat;
        design_matrix=[design_matrix model_mat(:)];
    end
    % normalize
    design_matrix(:,3:end) = design_matrix(:,3:end) ./ repmat(max(abs(design_matrix(:,3:end))),[size(design_matrix,1) 1]); 
    cmat = eye(size(design_matrix,2));
    
    [c,v,t] = ols(RSAdat,design_matrix,cmat);
    
    nP = 1000; %number of permutations
    cp=[];
    vp=[];
    tp=[];
    for p = 1:nP
        %randomly permute the conditions
        pp = randperm(length(conditions)); 
        dat=squeeze(mean(condition_mean_fr(pp,:,:),3));
        ok = ~all(dat==0);
        dat=dat(:,ok);
        
        %recompute the RSA matrices for each region:
        RSAmatp = create_RSA_mat(dat);
        RSAdatp = RSAmatp(:);
        
        %calculate the test statistics in this permuted RSA matrix:
        [cp(p,:,:),vp(p,:,:),tp(p,:,:)] = ols(RSAdatp,design_matrix,cmat);
        if mod(p,100)==0
            fprintf('%0.0f of %0.0f permutations complete\n',p,nP);
        end
    end
    ebars = squeeze(std(tp,[],1));
    
    %% repeat regression on sliding analysis, and calculate sliding CPD
    time = data.bins(1:end-1);
    
    RSAmatt=[];    
    RSAdatt=[];
    for ttt = 1:length(time)
        dat = squeeze(condition_mean_fr(:,:,ttt));
        ok = ~all(dat==0);
        mat=create_RSA_mat(dat(:,ok));
        RSAmatt(:,:,ttt) = mat;
        RSAdatt(:,ttt) = squash(mat);
    end

    [cpd_out,RX] = cpd(RSAdatt(:,:),design_matrix);
    cpd_out = cpd_out.*100;
    cpds = reshape(cpd_out,size(design_matrix,2),length(data.bins)-1);

    %% recompute with different permutations of the residuals
    cpds_perm=[];
    for p = 1:nP
        pp = randperm(length(conditions)); %randomly permute theconditions
        RSAmattp=[];    
        for ttt = 1:length(time)
            dat = squeeze(condition_mean_fr(pp,:,ttt));
            ok = ~all(dat==0); %exclude any cells that don't spike
            RSAmattp(:,:,ttt) = create_RSA_mat(dat(:,ok));
        end

        RSAdattp=[];
        for j = 1:length(time)
          RSAdattp(:,j) = squash(RSAmattp(:,:,j));
        end
        
        [cpd_out_perm] = cpd(RSAdattp(:,:),design_matrix);
        cpd_out_perm = cpd_out_perm.*100; %re-estimate CPDout
        cpds_perm(:,:,p) = reshape(cpd_out_perm,size(design_matrix,2),length(data.bins)-1);
 
%         %estimate t75s:
%         for i = 3:size(dm,2) %regressor
%             %for r = 1:length(exp_info.array_names) %region
%             [t75max_perm(i,p),tmax_perm(i,p),maxval_perm(i,p)] = calculate_t75max(squeeze(cpds_perm(i,:,p)),timeind);
%             %end
%         end
        if mod(p,100)==0
            fprintf('%0.0f of %0.0f permutations complete\n',p,nP);
        end
    end
    ttt_err= squeeze(std(cpds_perm,[],3));

    ax=subplot(3,length(align_evts),ae_idx);
    lims=[-1 1];
    plot_RDM(ax, RSAmat, condition_labels,...
        sprintf('%s: %s', exp_info.array_names{array_idx}, strrep(align_event,'_',' ')),...
        lims, 'colorbar', true);
    
    ax=subplot(3,length(align_evts),length(align_evts)+ae_idx);
    hold all
    for rr=1:length(model_matrices)
        [hbar errbar]=barwitherr(ebars(2+rr), rr, t(2+rr), 'FaceColor', color(rr,:));
        set(errbar,'HandleVisibility','off');
        hold all
    end
    xlim([0.5 length(model_matrices)+.5]); 
    box off; 
    set(gca,'Box','off','XTickLabel',[]);
    ylabel('T-statistic');
    legend(model_labels);
    
    ax=subplot(3,length(align_evts),2*length(align_evts)+ae_idx);
    hold all
    for rr = 1:length(model_matrices)
        shadedErrorBar(time,cpds(2+rr,:),ttt_err(2+rr,:),'LineProps',{'LineWidth',2,'Color',color(rr,:)});
        %significant_timepoints = cpds(rr,:,i)>cpd_threshold(rr,i);
    end
    plot([0 0],[0 100],'k--');
    legend(model_labels);
    xlabel('Time (ms)');
    ylabel('CPD (%%)');
    %axis square
    ylim([0 100]);
    xlim(woi);
    box off
    
    drawnow;
end    

end