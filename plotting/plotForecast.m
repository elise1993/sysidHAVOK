function h = plotForecast(tVal,xVal,xSim,vrVal,vrSim)

arguments
    tVal (:,1) {miscFunctions.mustBeMonotonic(tVal)}
    xVal (:,1) {miscFunctions.mustBeEqualLength(tVal,xVal)}
    xSim (:,1) {miscFunctions.mustBeEqualLength(tVal,xSim)}
    vrVal (:,1)
    vrSim (:,1) {miscFunctions.mustBeEqualLength(vrVal,vrSim)}
end

% plot
h = figure;
for i=1:2
    subplot(2,1,i); hold on

    if i==1
        x = [xVal,xSim];
        xlabel('')
        ylabel("x(t)")
        title(["HAVOK-SINDy-ML (Closed-Loop","Forecasting Validation Performance)"]);
    elseif i==2
        x = [vrVal,vrSim];
        xlabel('time (t)')
        ylabel("v_{r}(t)")
    end

    plot(tVal,x(:,1),linewidth=2,color="#0072BD")
    plot(tVal,x(:,2),':',linewidth=2,color="#D95319")

    grid on
    set(gca,'fontsize',20)
    range = [min(x(:))-std(x(:)),max(x(:))+std(x(:))];
    ylim(range)

end

leg = legend('True','Predicted');
leg.Orientation = "horizontal";
leg.Position = [.74,0,.1,.05];
% set(gcf,'color','w')

end