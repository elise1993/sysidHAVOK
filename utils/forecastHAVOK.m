function [v,vr] = forecastHAVOK(V,U,S,Ad,Bd0,Bd1,stackmax,r,...
    Regressor,MLmethod,D,nSteps,multiStepSize,opt)
%forecastHAVOK Forecast HAVOK model with the specified ML method
%
%    [t,x,vr] = forecastHAVOK(tVal,VVal,stackmax,r,Regressor,vrMean,vrSTD,
%    nSteps) forecasts the system for the specified number of steps nSteps
%    with the initial condition v0. If v0 is a matrix, the first column is
%    used for intitial conditions.
% 
%   The system dynamics are specified by the HAVOK-SINDy-ML matrices U, S, 
%   Ad, Bd0, Bd1, stackmax, and r. The regressor model is specified by
%   Regressor. If the regressor was constructed using normalized values,
%   vrMean and vrSTD can be specified to recover the unnormalized values.
% 
%
   
%   Copyright 2023 Elise Jonsson

arguments
    V (:,:)
    U (:,:)
    S (:,:)
    Ad (:,:)
    Bd0 (:,:)
    Bd1 (:,:)
    stackmax (1,1)
    r (1,1)
    Regressor
    MLmethod (1,1) {mustBeMember(MLmethod,["Bag","Boost","RFR","RFR-MEX",...
        "SVR","MLP","LSTM"])}
    D (1,1) {mustBeReal,mustBePositive}
    nSteps (1,1) {mustBeReal,mustBePositive}
    multiStepSize (1,1) {mustBeReal,mustBePositive}
    opt.SimulateForcing {mustBeMember(opt.SimulateForcing,...
        [1,0])} = true
end

disp("Forecasting HAVOK-SINDy-ML model...")

% get initial conditions for training/validation data in delay coordinates
vVal0 = V(1:r-1,1);
vrVal = V(r,:);
nMax = length(vrVal);

if opt.SimulateForcing
    % run HAVOK-SINDy-ML forecast with forcing model
    vr = vrVal(1);
else
    % run HAVOK-SINDy-ML forecast without forcing model (feed true forcing)
    vr = vrVal(1:nSteps);
end

v = vVal0;
US = U(:,1:r-1)*S(1:r-1,1:r-1);

i = 2;
while i < nSteps && i < nMax

    h = US*v(:,i-1);

    if opt.SimulateForcing
        if mod(i+1,multiStepSize)==1
            vr(i) = vrVal(i);
            v(:,i) = V(1:r-1,i);
            disp("reset at "+i)
        else
            vr(i) = predictML(Regressor,h(1:D:end)',MLmethod);
            % vr(i) = regRF_predict(h(1:D:end)',Regressor);
            v(:,i) = Ad*v(:,i-1) + Bd0*vr(i-1) + Bd1*vr(i);
        end
    end

    if mod(i,100)==0 || i==nSteps
        disp("step: "+i+"/"+nSteps)
    end

    i = i+1;
end

if nMax < nSteps
    warning("Not enough validation data to forecast further. Stopping at i="+(i-1)+"/"+nSteps)
end
