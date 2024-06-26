function h = plotForecast(tVal,xVal,xSim,vrVal,vrSim,multiStepSize)
%plotForecast Plot forecast
%
%    h = plotForecast(tVal,xVal,xSim,vrVal,vrSim) plots the forecasted data
%    xSim, vrSim and compares it to the true data xVal, xSim.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    tVal (:,1) {miscFunctions.mustBeMonotonic(tVal)}
    xVal (:,1) {miscFunctions.mustBeEqualLength(tVal,xVal)}
    xSim (:,1) {miscFunctions.mustBeEqualLength(tVal,xSim)}
    vrVal (:,1)
    vrSim (:,1) {miscFunctions.mustBeEqualLength(vrVal,vrSim)}
    multiStepSize (1,1) {mustBeReal,mustBePositive}
end

% remove lines between reset points
for i=1:multiStepSize:length(xSim)
    xSim(i:i+4) = nan;
    vrSim(i:i+4) = nan;
end

% plot
h = figure;
for i=1:2
    subplot(2,1,i); hold on

    if i==1
        x = [xVal,xSim];
        xlabel('')
        ylabel("x(t)")
        title(["HAVOK-SINDy-ML ("+multiStepSize+"-Step","Prediction, Validation Period)"]);
    elseif i==2
        x = [vrVal,vrSim];
        xlabel('time (t)')
        ylabel("v_{r}(t)")
    end

    plot(tVal,x(:,1),linewidth=2,color="#0072BD")
    plot(tVal,x(:,2),':',linewidth=2,color="#D95319")

    resetPoints = 1:multiStepSize:length(tVal);
    if length(x)/length(resetPoints) >= 50
        scatter(tVal(resetPoints),x(resetPoints,1),MarkerEdgeColor='white',linewidth=2)
    end

    grid on
    set(gca,'fontsize',20)
    range = [nanmin(x(:))-nanstd(x(:)),nanmax(x(:))+nanstd(x(:))];
    ylim(range)

end

if length(x)/multiStepSize >= 10
    leg = legend('True','Predicted','Initial Condition');
else
    leg = legend('True','Predicted');
end
leg.Orientation = "horizontal";
leg.Position = [.74,0,.1,.05];
% set(gcf,'color','w')
% set(gcf,'color','#0d1117')