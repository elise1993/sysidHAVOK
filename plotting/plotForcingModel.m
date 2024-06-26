function h = plotForcingModel(Train,Val,Predictions,zoomCoords,MLmethod)
%plotForcingModel Plot forcing model
%
%    h = plotForcingModel(Train,Val,Predictions,zoomCoords) plots the
%    training and validation data used for the forcing model, along with
%    open-loop (single-step) predictions.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    Train (:,:)
    Val (:,:)
    Predictions (:,:)
    zoomCoords (2,2)
    MLmethod (1,1)
end

tTrain = Train{1};
xTrain = Train{2};

tVal = Val{1};
xVal = Val{2};

x = [xTrain;xVal];
t = [tTrain;tVal];

xSimTrain = Predictions{1};
xSimVal = Predictions{2};

switch MLmethod
    case "LinearRegression"
        MLtitle = "Linear Regression";
    case "Bag"
        MLtitle = "Bootstrap Aggregation";
    case "LSBoost"
        MLtitle = "Least-Squares Boosting";
    case {"RFR","RFR-MEX"}
        MLtitle = "Random Forest Regressor";
    case "SVR"
        MLtitle = "Support Vector Regression";
    case "MLP"
        MLtitle = "Multilayer Perceptron";
    case "LSTM"
        MLtitle = "Long Short-Term Memory Network";
    case "TCN"
        MLtitle = "Temporal Convolutional Network";
end

% plot
h = figure;
for i=1:2
    subplot(2,1,i); hold on

    % shaded areas
    range = [min(x)-std(x),max(x)+std(x)];
    areaRangeTrain = {[t(1),tVal(1),tVal(1),t(1)],[range(1),range(1),range(2),range(2)]};
    areaRangeVal = {[tVal(1),tVal(end),tVal(end),tVal(1)],[range(1),range(1),range(2),range(2)]};
    patch(areaRangeTrain{1},areaRangeTrain{2},'g','FaceAlpha',0.05,'EdgeColor','none')
    patch(areaRangeVal{1},areaRangeVal{2},'r','FaceAlpha',0.05,'EdgeColor','none')

    % lines
    plot([tTrain;tVal],[xTrain;xVal],linewidth=2,color="#0072BD")
    plot([tTrain;tVal],[xSimTrain;xSimVal],':',linewidth=2,color="#D95319")

    grid on
    set(gca,'fontsize',20,'linewidth',2)
    ylabel("v_{r}(t)")
    ylim(range)

    if i==1
        title(MLtitle+" (Single-Step Prediction Performance)")
        xlabel('')
        xlim([zoomCoords(1),zoomCoords(3)])
        text(0.22,.92,"Training",'Units','normalized','fontsize',18);
        text(0.72,.92,"Validation",'Units','normalized','fontsize',18)
    elseif i==2
        xlabel('time (t)')
        xlim([zoomCoords(2),zoomCoords(4)])
    end

end

leg = legend('','','True','Predicted');
leg.Orientation = "horizontal";
leg.Position = [.74,0,.1,.05];


% ylim([-0.05,0.05])
% % xlim([92.7,93.1])
% set(gcf,'color','w')
% set(gcf,'color','#0d1117')