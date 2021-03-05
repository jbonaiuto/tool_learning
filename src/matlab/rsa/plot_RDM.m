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
[nr,nc]=size(RDM);
%imagesc([1:length(conditions)],[1:length(conditions)],RDM,'Parent',ax,lims);
pcolor(ax,[1:length(conditions)+1],[1:length(conditions)+1],[RDM nan(nr,1); nan(1,nc+1)]);
caxis(lims);
set(gca,'ydir','reverse');
shading flat;
colormap hot;
axis square;
set(ax,'ytick',[1:length(conditions)]+.5,'yticklabel',conditions);
set(gca,'xtick',[1:length(conditions)]+.5,'xticklabel',conditions,'XTickLabelRotation',45);
title(plt_title);
freezeColors;
if params.colorbar
    orig_pos=get(ax,'Position');
    cb=colorbar();
    cbfreeze(cb);
    set(ax,'Position',orig_pos);
end
