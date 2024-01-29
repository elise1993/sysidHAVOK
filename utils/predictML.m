function y = predictML(Regressor,x,method)
%predictML Make prediction using specified Regressor
%
%    Because SeriesNetwork, TreeBagger, and RegressionEnsemble objects
%    require different input dimensions when using the predict.m function,
%    this function simply transposes the input depending on which method is
%    used.
%

%   Copyright 2023 Elise Jonsson

arguments
    Regressor (1,1) {mustBeA(Regressor,["TreeBagger",...
        "classreg.learning.regr.RegressionEnsemble",...
        "SeriesNetwork","struct","LinearModel"])}

    x (:,:) {mustBeReal}

    method (1,1) {mustBeMember(method,["LinearRegression","Bag","Boost","RFR","RFR-MEX",...
        "SVR","MLP","LSTM"])}
end

switch method
    case {"LinearRegression","Bag","LSBoost","RFR","SVR"}
        y = predict(Regressor,x);

    case "RFR-MEX"
        y = regRF_predict(x,Regressor);

    case {"MLP","LSTM"}
        y = predict(Regressor,x')';

end