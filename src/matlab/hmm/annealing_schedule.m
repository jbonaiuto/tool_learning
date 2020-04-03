iteration=[1:500];
deltaLL=[-1000:1:1000];
inv_temp=1./iteration;

accept_prob=zeros(length(iteration),length(deltaLL));
for i=1:length(iteration)
    for j=1:length(deltaLL)
        accept_prob(i,j)=min([1,inv_temp(i).*exp(-.003*deltaLL(j))]);
    end
end
figure();
subplot(3,1,1);
plot(iteration,inv_temp);
xlabel('Iteration');
ylabel('Inverse temperature');
ax=subplot(3,1,2);
imagesc(iteration,deltaLL,accept_prob');
orig_pos=get(ax,'Pos');
set(gca,'clim',[0 1]);
set(gca,'ydir','normal');
h=colorbar();
title(h,'probability');
set(ax,'Pos',orig_pos);
xlabel('Iteration');
ylabel('\Delta LL');
ax=subplot(3,1,3);
imagesc(iteration,deltaLL,log(accept_prob)');
orig_pos=get(ax,'Pos');
set(gca,'ydir','normal');
h=colorbar();
title(h,'log(probability)');
set(ax,'Pos',orig_pos);
xlabel('Iteration');
ylabel('\Delta LL');