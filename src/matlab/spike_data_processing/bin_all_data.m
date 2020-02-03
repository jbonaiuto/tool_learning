function bin_all_data(exp_info, subject)

event_types={'trial_start', 'fix_on', 'go', 'hand_mvmt_onset',...
    'tool_mvmt_onset', 'obj_contact', 'place', 'reward'};

data_dir=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject);
d=dir(fullfile(data_dir, '*.*.*'));
bin_size=1;

for i = 2:length(d)
    dateexp=d(i).name
    out_dir=fullfile(data_dir,dateexp,'multiunit','binned');
    if exist(out_dir,'dir')~=7
        mkdir(out_dir);
    end
    tic;
    for arr_idx=1:6
        data=load_multiunit_data(exp_info,'betta',{dateexp}, 'arrays', [arr_idx]);
        for evt_idx=1:length(event_types)
            evt=event_types{evt_idx};
            out_file=fullfile(out_dir, sprintf('fr_b_%s_%s_%s.mat', exp_info.array_names{arr_idx}, dateexp, evt));
            
            if exist(out_file,'file')~=2
                data_ali=realign(data,evt);
                data_binned=bin_spikes(data_ali, [-1000 1000], bin_size,...
                    'baseline_evt', 'go','baseline_woi', [-500 0]);
                datafr=compute_firing_rate(data_binned, 'baseline_type', 'condition','win_len', 6);
                save(out_file,'datafr');
            end
        end
        out_file=fullfile(out_dir, sprintf('fr_b_%s_%s_whole_trial.mat', exp_info.array_names{arr_idx}, dateexp));
            
        if exist(out_file,'file')~=2
            data_binned=bin_spikes(data_ali, [-1000 10000], bin_size,...
                'baseline_evt', 'go','baseline_woi', [-500 0]);
            datafr=compute_firing_rate(data_binned, 'baseline_type', 'condition','win_len', 6);
            save(out_file,'datafr');
        end            
    end
    toc
end
