function run_rsa_sliding_window_electrode(exp_info, subject, array_idx)

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

model_matrices=create_model_matrices();
model_labels={};
model_cpds={};
model_ttt_errs={};
for i=1:length(model_matrices)
    model_mat=model_matrices{i};
    model_labels{i}=strrep(model_mat.name,'_',' ');
    for j=1:length(align_evts)
        model_cpds{i,j}=[];
        model_ttt_errs{i,j}=[];
    end
end
model_colors=cbrewer('qual','Paired',12);
condition_colors=[179,226,205; 102,194,165; 27,158,119; 252,141,98;
    217,95,2; 141,160,203; 117,112,179; 231,138,195; 231,41,138]./255.0;

for e_idx=1:exp_info.ch_per_array
    all_RSAmats={};
    all_ebars={};
    all_t={};
    all_cpds={};
    all_ttt_errs={};
    all_times={};
    
    condition_mean_fr={};

    for ae_idx=1:length(align_evts)
        align_event=align_evts{ae_idx};
        woi=align_wois(ae_idx,:);

        fname=sprintf('%s_stage1_%s_%s.mat', subject, array, align_event);
        load(fullfile('../../../output',fname));
        data=compute_firing_rate(data,'win_len',120,'baseline_type','condition');

        ae_condition_mean_fr=zeros(length(conditions),length(data.bins)-1);
        for c_idx=1:length(conditions)    
            % Find trials for this condition
            condition=conditions{c_idx};
            trials=find(strcmp(data.metadata.condition,condition));

            % Convolved firing rate for each trial
            ae_condition_mean_fr(c_idx,:)=squeeze(mean(data.firing_rate(1,e_idx,trials,1:end-1),3));        
        end
        condition_mean_fr{ae_idx}=ae_condition_mean_fr;

        dat = squeeze(ae_condition_mean_fr(:, :));
        RSAmat=create_RSA_mat(dat);
        RSAdat = RSAmat(:);        
        all_RSAmats{ae_idx}=RSAmat;
    
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
        all_t{ae_idx}=t(3:end);

        nP = 1000; %number of permutations
        cp=[];
        vp=[];
        tp=[];
        for p = 1:nP
            %randomly permute the conditions
            pp = randperm(length(conditions)); 
            dat=ae_condition_mean_fr(pp,:);
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
        all_ebars{ae_idx}=ebars(3:end);

        %% repeat regression on sliding analysis, and calculate sliding CPD
        time = data.bins(1:end-1);
        all_times{ae_idx}=time;
        
        win_size=200;
        RSAmatt=[];    
        RSAdatt=[];
        for ttt = 1:length(time)
            dat = ae_condition_mean_fr(:,max([1 ttt-win_size/2]):min([length(time) ttt+win_size/2-1]));
            mat=create_RSA_mat(dat);
            RSAmatt(:,:,ttt) = mat;
            RSAdatt(:,ttt) = squash(mat);
        end

        [cpd_out,RX] = cpd(RSAdatt(:,:),design_matrix);
        cpd_out = cpd_out.*100;
        cpds = reshape(cpd_out,size(design_matrix,2),length(data.bins)-1);
        all_cpds{ae_idx}=cpds(3:end,:);
        for i=1:length(model_matrices)
            x=model_cpds{i,ae_idx};
            x(e_idx,:)=cpds(2+i,:);
            model_cpds{i,ae_idx}=x;
        end

        %% recompute with different permutations of the residuals
        cpds_perm=[];
        for p = 1:nP
            pp = randperm(length(conditions)); %randomly permute theconditions
            RSAmattp=[];    
            RSAdattp=[];
            for ttt = 1:length(time)
                dat = ae_condition_mean_fr(pp,max([1 ttt-win_size/2]):min([length(time) ttt+win_size/2-1]));
                RSAmattp(:,:,ttt) = create_RSA_mat(dat);
                RSAdattp(:,ttt) = squash(RSAmattp(:,:,ttt));
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
        all_ttt_errs{ae_idx}=ttt_err(3:end,:);
        for i=1:length(model_matrices)
            x=model_ttt_errs{i,ae_idx};
            x(e_idx,:)=ttt_err(2+i,:);
            model_ttt_errs{i,ae_idx}=x;
        end
    end
    
    figure();    
    
    squashed_frs=cell2mat(condition_mean_fr);
    ylims=[min(squashed_frs(:))-2 max(squashed_frs(:))+2];
    
    squashed_RSAmats=cell2mat(all_RSAmats);
    clims=[-max(abs(squashed_RSAmats(squashed_RSAmats(:)<1))) max(abs(squashed_RSAmats(squashed_RSAmats(:)<1)))];
    
    squashed_ebars=cell2mat(all_ebars);
    squashed_ts=cell2mat(all_t);
    tlims=[-max(abs(squashed_ts(:)+squashed_ebars(:))+1) max(abs(squashed_ts(:)+squashed_ebars(:))+1)];
    
    squashed_cpds=cell2mat(all_cpds);
    squashed_ttt_errs=cell2mat(all_ttt_errs);
    tc=squashed_cpds+squashed_ttt_errs;
    cpdlims=[0 max(tc(:)+5)];
    
    for ae_idx=1:length(align_evts)
        align_event=align_evts{ae_idx};
        woi=align_wois(ae_idx,:);
        
        ax=subplot(3,length(align_evts),ae_idx);
        hold all
        ae_condition_mean_fr=condition_mean_fr{ae_idx};
        ae_times=all_times{ae_idx};
        labels={};
        for c_idx=1:length(conditions)    
            labels{end+1}=strrep(conditions{c_idx},'_',' ');
            plot(ae_times, ae_condition_mean_fr(c_idx,:),'color',condition_colors(c_idx,:));
        end
        xlim([ae_times(1) ae_times(end)]);
        ylim(ylims);
        xlabel('Time (ms)');
        ylabel('Firing Rate (Hz)');
        if ae_idx==1
            legend(labels);
        end
        
        %ax=subplot(3,length(align_evts),ae_idx);
        ax=subplot(3,length(align_evts),length(align_evts)+ae_idx);
        RSAmat=all_RSAmats{ae_idx};
        plot_RDM(ax, RSAmat, condition_labels,...
            sprintf('%s: %s', exp_info.array_names{array_idx}, strrep(align_event,'_',' ')),...
            clims, 'colorbar', true);
        
%         ax=subplot(3,length(align_evts),length(align_evts)+ae_idx);
%         ebars=all_ebars{ae_idx};
%         t=all_t{ae_idx};
%         hold all
%         for rr=1:length(model_matrices)
%             [hbar errbar]=barwitherr(ebars(rr), rr, t(rr), 'FaceColor', model_colors(rr,:));
%             set(errbar,'HandleVisibility','off');
%             hold all
%         end
%         xlim([0.5 length(model_matrices)+.5]); 
%         ylim(tlims);
%         box off; 
%         set(gca,'Box','off','XTickLabel',[]);
%         ylabel('T-statistic');
%         legend(model_labels);
        
        ax=subplot(3,length(align_evts),2*length(align_evts)+ae_idx);
        cpds=all_cpds{ae_idx};
        ttt_err=all_ttt_errs{ae_idx};
        time=all_times{ae_idx};
        hold all
        for rr = 1:length(model_matrices)
            shadedErrorBar(time,cpds(rr,:),ttt_err(rr,:),'LineProps',{'LineWidth',2,'Color',model_colors(rr,:)});
            %significant_timepoints = cpds(rr,:,i)>cpd_threshold(rr,i);
        end
        yl=ylim();
        plot([0 0],yl,'k--');
        if ae_idx==1
            legend(model_labels);
        end
        xlabel('Time (ms)');
        ylabel('CPD (%%)');
        %axis square
        ylim(cpdlims);
        xlim(woi);
        box off
    end    
end

figure();
    
for i=1:length(model_matrices)
    
    for ae_idx=1:length(align_evts)
        align_event=align_evts{ae_idx};
        woi=align_wois(ae_idx,:);
        
        ax=subplot(length(model_matrices),length(align_evts),(i-1)*length(align_evts)+ae_idx);
        cpds=model_cpds{i,ae_idx};
        ttt_err=model_ttt_errs{i,ae_idx};
        
        time=all_times{ae_idx};
        
        hold all
        for e_idx = 1:exp_info.ch_per_array
            shadedErrorBar(time,cpds(e_idx,:),ttt_err(e_idx,:),'LineProps',{'LineWidth',2});
        end
        plot([0 0],[0 100],'k--');
        if i==1
            title(sprintf('%s: %s', exp_info.array_names{array_idx}, strrep(align_event,'_',' ')));
        end
        xlabel('Time (ms)');
        if ae_idx==1
            ylabel(model_labels{i});
        end
        %axis square
        ylim([0 100]);
        xlim(woi);
        box off
    end
end
