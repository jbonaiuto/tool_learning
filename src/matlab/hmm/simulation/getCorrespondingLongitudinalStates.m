function correspondingStates = getCorrespondingLongitudinalStates(realR,estRGlobal,estRDay)

meanR=[];
meanEstR=[];
for i=1:length(realR)
    meanR(end+1,:,:)=realR{i};
    meanEstR(end+1,:,:)=(estRGlobal+squeeze(estRDay(i,:,:)))';
end
meanR=squeeze(mean(meanR));
meanEstR=squeeze(mean(meanEstR));

M = [meanR meanEstR];
D = dist(M);
nstates = size(realR,2);
correspondingStates=zeros(1,nstates);
C = D(1:nstates,(nstates+1):end);
usedStates=[];
for i=1:nstates
    [~,inds] = sort(C(i,:));
    for j=1:length(inds)
        if (ismember(inds(j),usedStates))
            continue;
        else
            correspondingStates(i) = inds(j);
            usedStates = [usedStates inds(j)];
            break;
        end
    end
end

