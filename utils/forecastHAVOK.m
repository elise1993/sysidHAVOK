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
    MLmethod (1,1) {mustBeMember(MLmethod,["LinearRegression","Bag","Boost","RFR","RFR-MEX",...
        "SVR","MLP","LSTM"])}
    D (1,1) {mustBeReal,mustBePositive}
    nSteps (1,1) {mustBeReal,mustBePositive}
    multiStepSize (1,1) {mustBeReal,mustBePositive} = 1
    opt.SimulateForcing {mustBeMember(opt.SimulateForcing,...
        [1,0])} = true
end

disp("Forecasting HAVOK-SINDy-ML model...")

% get initial conditions for training/validation data in delay coordinates
vVal0 = V(1:r-1,1);
vrVal = V(r,:);
nMax = length(vrVal)-1;

if opt.SimulateForcing
    % run HAVOK-SINDy-ML forecast (forced linear model)
    vr = vrVal(1);
else
    % run HAVOK-SINDy forecast (linear model)
    try
        vr = vrVal(1:nSteps);
    catch
        vr = vrVal(1:nMax);
    end
end

v = vVal0;
US = U(:,1:r-1)*S(1:r-1,1:r-1);

i = 1;
while i < nSteps && i < nMax

    if ~mod(i,multiStepSize)
        vr0 = vrVal(i);
        v0 = V(1:r-1,i);
    else
        vr0 = vr(i);
        v0 = v(:,i);
    end

    h = US*v0;
    
    if opt.SimulateForcing
        vr1 = predictML(Regressor,h(1:D:end)',MLmethod);
    else
        vr0 = 0;
        vr1 = 0;
    end
        
    v(:,i+1) = Ad*v0 + Bd0*vr0 + Bd1*vr1;
    
    vr(i+1) = vr1;

    if ~mod(i,100) || i==nSteps
        disp("step: "+i+"/"+nSteps)
    end

    i = i+1;
end




if nMax < nSteps
    warning("Not enough validation data to forecast further. Stopping at i="+(i-1)+"/"+nSteps)
end
