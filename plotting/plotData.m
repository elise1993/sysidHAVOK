function h = plotData(tTrain,xTrain,tVal,xVal)

arguments
    tTrain (:,1) {miscFunctions.mustBeMonotonic(tTrain)}
    xTrain (:,:) {miscFunctions.mustBeEqualLength(tTrain,xTrain)}
    tVal (:,1) {miscFunctions.mustBeMonotonic(tVal)}
    xVal (:,:) {miscFunctions.mustBeEqualLength(tVal,xVal)}
end

x = [xTrain;xVal];
t = [tTrain;tVal];
nVars = size(x,2);
Ratio = length(xVal)/length(xTrain);

h = figure;
for i=1:nVars
    subplot(nVars,1,i); hold on
    
    % shaded areas
    range = [min(x(:,i))-std(x(:,i)),max(x(:,i))+std(x(:,i))];
    areaRangeTrain = {[t(1),tVal(1),tVal(1),t(1)],[range(1),range(1),range(2),range(2)]};
    areaRangeVal = {[tVal(1),tVal(end),tVal(end),tVal(1)],[range(1),range(1),range(2),range(2)]};
    patch(areaRangeTrain{1},areaRangeTrain{2},'g','FaceAlpha',0.03,'EdgeColor','none')
    patch(areaRangeVal{1},areaRangeVal{2},'r','FaceAlpha',0.03,'EdgeColor','none')

    gcaPos = gca().Position;
    text(gcaPos(3)-Ratio*2,.92,"Training",'Units','normalized','fontsize',16);
    text(gcaPos(3)+Ratio*.5,.92,"Validation",'Units','normalized','fontsize',16)

    % plots
    plot([tTrain;tVal],[xTrain(:,i);xVal(:,i)],linewidth=2,color="#0072BD")
    ylim(range)
    grid on
    scatter(t(1),xTrain(1,i),'ow',linewidth=2)
    scatter(tVal(1),xVal(1,i),'ow',linewidth=2)
    set(gca,'fontsize',20,'linewidth',2)

    ylabel("x_"+num2str(i))
    if i<nVars
        xticklabels('')
    else
        xlabel('time (t)')
    end
end

leg = legend('','','Data','Initial Condition','');
leg.Orientation = "horizontal";
leg.Position = [.74,0,.1,.05];

end