function plot_eyedata(exp_info, data, varargin)

% Parse optional arguments
defaults=struct('type','scatter');
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end


addpath('..');

conditions=[];
conditions(1).name='fixation';
conditions(1).sub_conditions={'fixation'};
conditions(1).event_pairs={{'fix_on','reward'}};
conditions(2).name='motor grasp';
conditions(2).sub_conditions={'motor_grasp_left','motor_grasp_center','motor_grasp_right'};
conditions(2).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','obj_contact'},{'obj_contact','place'},{'place','reward'}};
conditions(3).name='motor rake';
conditions(3).sub_conditions={'motor_rake_left','motor_rake_center','motor_rake_right'};
conditions(3).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','obj_contact'},{'obj_contact','place'},{'place','reward'}};
conditions(4).name='visual grasp';
conditions(4).sub_conditions={'visual_grasp_left','visual_grasp_right'};
conditions(4).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','obj_contact'},{'obj_contact','place'},{'place','reward'}};
conditions(5).name='visual pliers';
conditions(5).sub_conditions={'visual_pliers_left','visual_pliers_right'};
conditions(5).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','tool_mvmt_onset'},{'tool_mvmt_onset','obj_contact'},...
    {'obj_contact','place'},{'place','reward'}};
conditions(6).name='visual rake pull';
conditions(6).sub_conditions={'visual_rake_pull_left','visual_rake_pull_right'};
conditions(6).event_pairs={{'fix_on','go'},{'go','hand_mvmt_onset'},...
    {'hand_mvmt_onset','tool_mvmt_onset'},{'tool_mvmt_onset','obj_contact'},...
    {'obj_contact','place'},{'place','reward'}};

for c_idx=1:length(conditions)
    figure();
    condition=conditions(c_idx);
    
    for cs_idx=1:length(condition.sub_conditions)
        sub_condition=condition.sub_conditions{cs_idx};
        
        trials=find(strcmp(data.metadata.condition,sub_condition));
        
        for ep_idx=1:length(condition.event_pairs)
            evt_pair=condition.event_pairs{ep_idx};
            
            ax=subplot(length(condition.sub_conditions),length(condition.event_pairs),...
                (cs_idx-1)*length(condition.event_pairs)+ep_idx);
            hold all
    
            evt1_times=data.metadata.(evt_pair{1});
            evt2_times=data.metadata.(evt_pair{2});
            all_x=[];
            all_y=[];
            for k = 1:length(trials)
                t_idx=trials(k);
                if length(data.eyedata.x{t_idx})>0
                    transformed_gaze=[data.eyedata.x{t_idx} data.eyedata.y{t_idx}];
                    in_table_bounds=(transformed_gaze(:,1)>=exp_info.table_corner_1(1)) & (transformed_gaze(:,1)<=exp_info.table_corner_2(1)) & (transformed_gaze(:,2)>=exp_info.table_corner_3(3)) & (transformed_gaze(:,2)<=exp_info.table_corner_1(3));
                    in_bounds=in_table_bounds & (data.eyedata.t{t_idx}>=evt1_times(t_idx)) & (data.eyedata.t{t_idx}<=evt2_times(t_idx));
                    trial_x=transformed_gaze(in_bounds,1);
                    trial_y=transformed_gaze(in_bounds,2);
                    all_x(end+1:end+length(trial_x))=trial_x;
                    all_y(end+1:end+length(trial_y))=trial_y;
                end
            end
            table_col='k';
            if strcmp(params.type,'scatter')
                plot(all_x,all_y,'.','Color',[.5 .5 .5]);
            elseif strcmp(params.type,'density') && length(all_x)>0
                [N,Xbins,Ybins] = hist2d(all_x',all_y',...
                    linspace(exp_info.table_corner_1(1),exp_info.table_corner_2(1),200),...
                    linspace(exp_info.table_corner_3(3),exp_info.table_corner_1(3),200),...
                    'probability');
                imagesc(Xbins,Ybins,N);
                set(gca,'ydir','normal');
                table_col=[.65 .65 .65];
            end
            plot_table(exp_info, ax, 'color', table_col);
            title(sprintf('%s: %s-%s',strrep(sub_condition,'_',' '),...
                strrep(evt_pair{1},'_',' '),strrep(evt_pair{2},'_',' ')));
        end
    end    
end

rmpath('..');