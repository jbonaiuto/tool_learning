function preprocess_data(exp_info, subject)

addpath('../spike_data_processing');

stage1_dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
     '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19','13.03.19',...
     '14.03.19','15.03.19','18.03.19','19.03.19','20.03.19','21.03.19',...
     '22.03.19','25.03.19','26.03.19'};
stage2_dates={'27.03.19','28.03.19','29.03.19','01.04.19','02.04.19',...
    '03.04.19','05.04.19','08.04.19','09.04.19','10.04.19','11.04.19',...
    '12.04.19','15.04.19','16.04.19','17.04.19','18.04.19','19.04.19',...
    '23.04.19','24.04.19','25.04.19','26.04.19','29.04.19','01.05.19',...
    '02.05.19','03.05.19','06.05.19','07.05.19','09.05.19','10.05.19',...
    '13.05.19','14.05.19','15.05.19','16.05.19','17.05.19','20.05.19',...
    '21.05.19','22.05.19','23.05.19','24.05.19','27.05.19','28.05.19',...
    '29.05.19','11.06.19','12.06.19','13.06.19','14.06.19',...%'17.06.19',...
    '18.06.19','19.06.19','20.06.19','21.06.19','24.06.19','25.06.19',...
    '26.06.19','27.06.19','28.06.19','01.07.19','02.07.19','03.07.19',...
    '04.07.19','05.07.19','08.07.19',...%'09.07.19',
    '10.07.19','11.07.19',...
    '12.07.19','15.07.19','16.07.19','17.07.19','18.07.19','19.07.19',...
    '22.07.19','23.07.19','24.07.19','25.07.19','26.07.19','29.07.19',...
    '31.07.19','01.08.19','02.08.19','05.08.19','06.08.19','07.08.19',...
    '09.08.19','20.08.19','21.08.19','22.08.19','23.08.19','26.08.19',...
    '27.08.19','28.08.19','29.08.19','04.09.19','05.09.19','06.09.19',...
    '09.09.19','10.09.19'};
stage3_dates={'11.09.19','12.09.19','13.09.19','16.09.19','17.09.19',...
    '18.09.19','19.09.19','20.09.19','23.09.19','24.09.19','25.09.19',...
    '26.09.19','27.09.19','30.09.19','03.10.19','04.10.19',...
    '07.10.19','08.10.19','09.10.19','10.10.19','11.10.19','14.10.19',...
    '16.10.19','17.10.19','18.10.19','21.10.19','22.10.19','23.10.19',...
    '24.10.19','25.10.19','28.10.19','29.10.19',...%'30.10.19',
    '31.10.19',...
    '04.11.19','05.11.19','06.11.19','14.11.19','20.11.19','21.11.19',...
    '22.11.19','25.11.19',...%'26.11.19','05.12.19',
    '09.12.19','16.12.19',...
    '06.01.20','13.01.20','20.01.20','27.01.20','03.02.20','11.02.20',...
    '20.02.20','28.02.20'};

binwidth=1;

addpath('../spike_data_processing');
    
for array_idx=1:length(exp_info.array_names)
    array=exp_info.array_names{array_idx};
    disp(array);
    
    tic;    
    data=load_multiunit_data(exp_info,subject,stage1_dates, 'arrays', [array_idx]);
    disp(sprintf('loading took %.2fs', toc));

    % Filter data - RTs too fast or slow
    tic
    data=filter_data(exp_info,data,'plot_corrs',true);
    disp(sprintf('filtering took %.2fs', toc));

    align_evts={'go','hand_mvmt_onset','obj_contact','place'};
    align_wois=[-250 250;-250 250;-250 250;-250 250];

    for ae_idx=1:length(align_evts)
        align_event=align_evts{ae_idx};
        disp(align_event);
        tic
        aligned_data=realign(data, align_event);
        disp(sprintf('realignment took %.2fs', toc));

        woi=align_wois(ae_idx,:);
        tic
        aligned_data=bin_spikes(aligned_data, woi, binwidth);
        disp(sprintf('binning took %.2fs', toc));
        
        tic
        data=compute_firing_rate(aligned_data);
        disp(sprintf('computing rate took %.2fs', toc));
        
        fname=sprintf('%s_stage1_%s_%s.mat', subject, array, align_event);
        save(fullfile('../../../output',fname),'data');
    end
    
    tic;
    data=load_multiunit_data(exp_info,subject,stage2_dates, 'arrays', [array_idx]);
    disp(sprintf('loading took %.2fs', toc));

    % Filter data - RTs too fast or slow
    tic
    data=filter_data(exp_info,data,'plot_corrs',true);
    disp(sprintf('filtering took %.2fs', toc));

    align_evts={'go','hand_mvmt_onset','obj_contact','place'};
    align_wois=[-250 250;-250 250;-250 250;-250 250];

    for ae_idx=1:length(align_evts)
        align_event=align_evts{ae_idx};
        disp(align_event);
        tic
        aligned_data=realign(data, align_event);
        disp(sprintf('realignment took %.2fs', toc));

        woi=align_wois(ae_idx,:);
        tic
        aligned_data=bin_spikes(aligned_data, woi, binwidth);
        disp(sprintf('binning took %.2fs', toc));
        
        tic
        data=compute_firing_rate(aligned_data);
        disp(sprintf('computing rate took %.2fs', toc));
        
        fname=sprintf('%s_stage2_%s_%s.mat', subject, array, align_event);
        save(fullfile('../../../output',fname),'data');
    end
    
    tic;
    data=load_multiunit_data(exp_info,subject,stage3_dates, 'arrays', [array_idx]);
    disp(sprintf('loading took %.2fs', toc));

    % Filter data - RTs too fast or slow
    tic
    data=filter_data(exp_info,data,'plot_corrs',true);
    disp(sprintf('filtering took %.2fs', toc));

    align_evts={'go','hand_mvmt_onset','obj_contact','place'};
    align_wois=[-250 250;-250 250;-250 250;-250 250];

    for ae_idx=1:length(align_evts)
        align_event=align_evts{ae_idx};
        disp(align_event);
        tic
        aligned_data=realign(data, align_event);
        disp(sprintf('realignment took %.2fs', toc));

        woi=align_wois(ae_idx,:);
        tic
        aligned_data=bin_spikes(aligned_data, woi, binwidth);
        disp(sprintf('binning took %.2fs', toc));
        
        tic
        data=compute_firing_rate(aligned_data);
        disp(sprintf('computing rate took %.2fs', toc));
        
        fname=sprintf('%s_stage3_%s_%s.mat', subject, array, align_event);
        save(fullfile('../../../output',fname),'data');
    end
end

