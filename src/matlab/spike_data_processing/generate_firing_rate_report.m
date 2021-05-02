function generate_firing_rate_report(exp_info, subject)

start_date=datenum('26.02.19','dd.mm.YY');
end_date=datenum(now());

% Read all directories in preprocessed data directory
data_dir=fullfile(exp_info.base_data_dir, 'preprocessed_data', subject);
d=dir(fullfile(data_dir, '*.*.*'));
d=d(2:end);
% Sort by date
d_datetimes=[];
d_names={};
for d_idx=1:length(d)
    dn=datenum(d(d_idx).name,'dd.mm.YY');
    if dn>=start_date && dn<end_date
      d_datetimes(end+1)=dn;
      d_names{end+1}=d(d_idx).name;
    end
end
[~,sorted_idx]=sort(d_datetimes);
d_names=d_names(sorted_idx);

if exist(fullfile(data_dir, 'firing_rate_report'),'dir')~=7
    mkdir(fullfile(data_dir, 'firing_rate_report'));
    mkdir(fullfile(data_dir, 'firing_rate_report','img'));
end
fid=fopen(fullfile(data_dir, 'firing_rate_report', 'index.html'),'w');
fprintf(fid, '<!DOCTYPE html>\n');
fprintf(fid, '<html>\n');
fprintf(fid, '<head>\n');
fprintf(fid, '<title>Firing rate report: %s</title>\n',subject);
fprintf(fid, '<link rel="stylesheet" href="style.css">\n');
fprintf(fid, '</head>\n');
fprintf(fid, '<body>\n');
fprintf(fid, '<h1>%s</h1>\n',subject);
fprintf(fid, '<table width="100%%" border="1">\n');
fprintf(fid, '<tr>\n');
fprintf(fid, '<th>Date</th>\n');
fprintf(fid, '<th>F1 - motor grasp L</th>\n');
fprintf(fid, '<th>F1 - motor grasp C</th>\n');
fprintf(fid, '<th>F1 - motor grasp R</th>\n');
fprintf(fid, '<th>F5hand - visual grasp L</th>\n');         
fprintf(fid, '<th>F5hand - visual grasp R</th>\n');         
fprintf(fid, '</tr>\n');
        
for i = 1:length(d_names)
    dateexp=d_names{i}
    if exist(fullfile(data_dir, dateexp, 'multiunit/binned'),'dir')==7
        fprintf(fid, '<tr>\n');
        fprintf(fid, '<td>%s</td>\n', dateexp);
        fig=plot_multialign_multiunit_array_data(exp_info, subject, {dateexp}, 'F1', {'motor_grasp_left'});
        drawnow;
        if ~isnumeric(fig)
            fname=sprintf('F1_motor_grasp_left_%s.png', dateexp);
            saveas(fig, fullfile(data_dir, 'firing_rate_report', 'img', fname));
            close(fig);
            fprintf(fid, '<td><img class="thumnbail" src="./img/%s"/></td>\n',fname);
        else
            fprintf(fid, '<td></td>\n');
        end        

        fig=plot_multialign_multiunit_array_data(exp_info, subject, {dateexp}, 'F1', {'motor_grasp_center'});
        drawnow;
        if ~isnumeric(fig)
            fname=sprintf('F1_motor_grasp_center_%s.png', dateexp);
            saveas(fig, fullfile(data_dir, 'firing_rate_report', 'img', fname));
            close(fig);
            fprintf(fid, '<td><img class="thumnbail" src="./img/%s"/></td>\n',fname);
        else
            fprintf(fid, '<td></td>\n');
        end        

        fig=plot_multialign_multiunit_array_data(exp_info, subject, {dateexp}, 'F1', {'motor_grasp_right'});
        drawnow;
        if ~isnumeric(fig)
            fname=sprintf('F1_motor_grasp_right_%s.png', dateexp);
            saveas(fig, fullfile(data_dir, 'firing_rate_report', 'img', fname));
            close(fig);
            fprintf(fid, '<td><img class="thumnbail" src="./img/%s"/></td>\n',fname);
        else
            fprintf(fid, '<td></td>\n');
        end        
        
        fig=plot_multialign_multiunit_array_data(exp_info, subject, {dateexp}, 'F5hand', {'visual_grasp_left'});
        drawnow;
        if ~isnumeric(fig)
            fname=sprintf('F5hand_visual_grasp_left_%s.png', dateexp);
            saveas(fig, fullfile(data_dir, 'firing_rate_report', 'img', fname));
            close(fig);
            fprintf(fid, '<td><img class="thumnbail" src="./img/%s"/></td>\n',fname);                
        else
            fprintf(fid, '<td></td>\n');
        end        

        
        fig=plot_multialign_multiunit_array_data(exp_info, subject, {dateexp}, 'F5hand', {'visual_grasp_right'});
        drawnow;
        if ~isnumeric(fig)
            fname=sprintf('F5hand_visual_grasp_right_%s.png', dateexp);
            saveas(fig, fullfile(data_dir, 'firing_rate_report', 'img', fname));
            close(fig);
            fprintf(fid, '<td><img class="thumnbail" src="./img/%s"/></td>\n',fname);                
        else
            fprintf(fid, '<td></td>\n');
        end        
        fprintf(fid, '</tr>\n');
    end
end
fprintf(fid, '</table>\n');
fprintf(fid, '</body>\n');
fprintf(fid, '</html>\n');
fclose(fid);
