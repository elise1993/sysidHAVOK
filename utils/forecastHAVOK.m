function [v,vr] = forecastHAVOK(v0,U,S,Ad,Bd0,Bd1,stackmax,r,...
    Regressor,vrMean,vrSTD,nSteps,opt)
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
    v0 (:,:)
    U (:,:)
    S (:,:)
    Ad (:,:)
    Bd0 (:,:)
    Bd1 (:,:)
    stackmax (1,1)
    r (1,1)
    Regressor
    vrMean (1,1)
    vrSTD (1,1)
    nSteps (1,1) {mustBeReal,mustBePositive}
    opt.SimulateForcing {mustBeMember(opt.SimulateForcing,...
        [1,0])} = true
end

disp("Forecasting HAVOK-SINDy-ML model...")

% get initial conditions for training/validation data in delay coordinates
vVal0 = v0(1:r-1,1);
vrVal = v0(r,:);

if opt.SimulateForcing
    % run HAVOK-SINDy-ML forecast with forcing model
    vr = vrVal(1);
else
    % run HAVOK-SINDy-ML forecast without forcing model (feed true forcing)
    vr = vrVal(1:nSteps);
end

v = vVal0;
US = U(:,1:r-1)*S(1:r-1,1:r-1);

for i = 1:nSteps-1

    h = US*v(:,i);

    if opt.SimulateForcing
        vr(i+1) = predictML(Regressor,h(1:D:end)',MLmethod);
        vr(i+1) = vr(i+1)*vrSTD + vrMean;
    end

    v(:,i+1) = Ad*v(:,i) + Bd0*vr(i) + Bd1*vr(i+1);

    if mod(i,100)==0 || i==nSteps
        disp("step: "+i+"/"+nSteps)
    end
end

if ~opt.SimulateForcing
    vr = vr/vrSTD - vrMean;
end
