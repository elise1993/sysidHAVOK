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
        "SeriesNetwork"])}

    x (:,:) {mustBeReal}

    method (1,1) {mustBeMember(method,["Bag","Boost","RFR","SVR",...
        "MLP","LSTM"])}
end

switch method
    case {"Bag","LSBoost","RFR","SVR"}
        y = predict(Regressor,x);

    case {"MLP","LSTM"}
        y = predict(Regressor,x')';

end