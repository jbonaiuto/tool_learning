function plot_RDM(ax, RDM, conditions, plt_title, lims, varargin)
defaults = struct('colorbar',false);  %define default values
params = struct(varargin{:});
for f = fieldnames(defaults)',  
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

if length(lims)==0
    lims=[-max(abs(RDM(RDM(:)<1))) max(abs(RDM(RDM(:)<1)))];
end
imagesc([1:length(conditions)],[1:length(conditions)],RDM,'Parent',ax,lims);
colormap hot;
axis square;
set(ax,'ytick',[1:length(conditions)],'yticklabel',conditions);
set(gca,'xtick',[1:length(conditions)],'xticklabel',conditions,'XTickLabelRotation',45);
title(plt_title);
freezeColors;
if params.colorbar
    orig_pos=get(ax,'Position');
    cb=colorbar();
    cbfreeze(cb);
    set(ax,'Position',orig_pos);
end
