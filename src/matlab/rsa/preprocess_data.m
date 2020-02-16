function preprocess_data(exp_info, subject)

addpath('../spike_data_processing');

stage1_dates={'26.02.19','27.02.19','28.02.19','01.03.19','04.03.19',...
    '05.03.19','07.03.19','08.03.19','11.03.19','12.03.19','13.03.19',...
    '14.03.19','15.03.19','18.03.19','19.03.19','20.03.19','21.03.19',...
    '22.03.19','25.03.19','26.03.19'};

binwidth=1;

for array_idx=1:length(exp_info.array_names)
    array=exp_info.array_names{array_idx};
    disp(array);
    tic
    data=load_multiunit_data(exp_info,subject,stage1_dates, 'arrays', [array_idx]);
    disp(sprintf('loading took %.2fs', toc));

    tic
    data=filter_data(data);
    disp(sprintf('filtering took %.2fs', toc));

    align_evts={'go','hand_mvmt_onset','obj_contact','place'};
    align_wois=[-250 250;-250 200;-100 250;-250 250];

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
end