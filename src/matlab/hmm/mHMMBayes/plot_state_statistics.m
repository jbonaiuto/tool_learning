function plot_state_statistics(stats, lbls, varargin)

%called by run_state_trial_stats.m

% Parse optional arguments
defaults=struct('density_type','ks', 'zero_bounded', false, 'ax',-1);
params=struct(varargin{:});
for f=fieldnames(defaults)'
    if ~isfield(params, f{1})
        params.(f{1})=defaults.(f{1});
    end
end


[cb] = cbrewer('qual','Dark2',10,'pchip');

if params.ax<0
    figure();
end
hs={};
leg_hs=[];
lg={};
max_y=0;
for i = 1:length(lbls)
    lg{i}=sprintf('s%d',i);
    h = raincloud_plot(stats{i}, ...
        'box_on', 1, 'color', cb(i,:), 'alpha', 0.05,...
        'cloud_edge_col', cb(i,:), 'box_col_match',1, 'density_type',params.density_type);
    s_max_y=max(h{1}.YData(~isinf(h{1}.YData)));
    if s_max_y>max_y
        max_y=s_max_y;
    end
    hs{i}=h;
end
dot_height=max_y/length(lbls)*1.5;
box_height=max_y/length(lbls)*.75;
upper_gap=max_y/length(lbls)*.15;
lower_gap=max_y/length(lbls)*.6;
jitter_width=.1*(max(max([stats{:}]))-min(min([stats{:}])));
for i = 1:length(lbls)
    h=hs{i};
    % Jitter dots    
    if params.zero_bounded
        h{2}.XData(h{2}.XData>0)=h{2}.XData(h{2}.XData>0)+jitter_width*randn(size(h{2}.XData((h{2}.XData>0))));
        h{2}.XData(h{2}.XData<0)=0;
    else
        h{2}.XData=h{2}.XData+jitter_width*randn(size(h{2}.XData));    
    end
    dot_lims=-[(i-1)*(dot_height+upper_gap+box_height+lower_gap) (i-1)*(dot_height+upper_gap+box_height+lower_gap)+dot_height];
    h{2}.YData=dot_lims(1)+(dot_lims(2)-dot_lims(1))*rand(size(h{2}.YData));
    % Rectangle - bottom y coord
    h{3}.Position(2)=-((i-1)*(dot_height+upper_gap+box_height+lower_gap)+dot_height+upper_gap+box_height);
    % Rectangle - height
    h{3}.Position(4)=box_height;
    % Mean line
    h{4}.YData=[-((i-1)*(dot_height+upper_gap+box_height+lower_gap)+dot_height+upper_gap+box_height); -((i-1)*(dot_height+upper_gap+box_height+lower_gap)+dot_height)];
    % Whiskers
    h{5}.YData=[-((i-1)*(dot_height+upper_gap+box_height+lower_gap)+dot_height+upper_gap+.5*box_height); -((i-1)*(dot_height+upper_gap+box_height+lower_gap)+dot_height+upper_gap+.5*box_height);];
    h{6}.YData=[-((i-1)*(dot_height+upper_gap+box_height+lower_gap)+dot_height+upper_gap+.5*box_height); -((i-1)*(dot_height+upper_gap+box_height+lower_gap)+dot_height+upper_gap+.5*box_height);];
    box off
    leg_hs(i)=h{1};
end
ylim([-length(lbls)*(dot_height+upper_gap+box_height+lower_gap) max_y]);
%xlim([-10 1000]);
yticks=get(gca,'Ytick');
idx=yticks>0;
yticks=yticks(idx);
yticklabels=get(gca,'YtickLabel');
yticklabels=yticklabels(idx);
set(gca,'YTick',[-([length(lbls):-1:1]-1)*(dot_height+upper_gap+box_height+lower_gap)-dot_height yticks]);
new_lbls={};
for i=length(lbls):-1:1
    new_lbls{end+1}=lbls{i};
end
for i=1:length(yticklabels)
    new_lbls{end+1}=yticklabels{i};
end
set(gca,'YTickLabel',new_lbls);
legend(leg_hs, lg);
