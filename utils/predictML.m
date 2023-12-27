function y = predictML(Regressor,x,method)
%predictML Make prediction using specified Regressor
%
%    Because SeriesNetwork, TreeBagger, and fitensemble objects require
%    different input dimensions when using the predict.m function, this
%    function simply transposes the input depending on which method is
%    used.
%

%   Copyright 2023 Elise Jonsson

arguments
    Regressor (1,1) {mustBeA(Regressor,["TreeBagger",...
        "classreg.learning.regr.RegressionEnsemble",...
        "SeriesNetwork"])}

    x (:,:) {mustBeReal}

    method (1,1) {mustBeMember(method,["TreeBagger","BaggedEnsemble",...
        "MLP","LSTM"])}
end

switch method
    case {"TreeBagger","BaggedEnsemble"}
        y = predict(Regressor,x);

    case {"MLP","LSTM"}
        y = predict(Regressor,x')';

end