%% MAIN    main
% This code takes some data, interpolates it, partitions it into
% training/validation/testing sets, and finds a Koopman-based linear
% representation of the system in delay coordinates using HAVOK analysis
% and SINDy. This code requires the specification of the following
% parameters:
% 
% x,t,x0 - Single-variable data, x, from a nonlinear chaotic system sampled
% at times t, with initial condition x0. Example data are generated from
% the Lorenz- and Van der Pol systems.
% 
% stackmax - number of time(delay)-shifted copies of the data x, which
% represents the memory of the HAVOK model. Similar to an Auto-Regressive
% model, A longer memory allows for longer dependencies, but increases the
% complexity and computational intensity of the model.
% 
% rmax - the maximum rank of the HAVOK model, defined as the maximum number
% of singular values to retain when performing Singular Value Decomposition
% (SVD). A low rank model retains only the lower order statistics (moments)
% of the system, whereas a higher rank model also captures higher order
% moments and more detail. A higher-ranked model will have greater
% forecasting skill on both training and validation data, as the linear
% system asymptotically approximates the nonlinear system with increasing
% size, but it will make identification of an optimal ML method more
% difficult and might be prohibitevly expensive to run.
% 
% polyDegree - specifies the polynomial degree of the HAVOK-SINDy model.
% The standard HAVOK algorithm finds a linear representation in delay
% coordinates using least-squares regression, meaning that the algorithm
% tries to find a best-fit linear model dvdt = Av in a least-squares sense,
% where each variable v_i is valued equally. Meanwhile, the HAVOK-SINDy
% algorithm tries to find the sparsest solution, where unimportant v_i
% variables are truncated (for more intuititon, google Least-Squares vs
% LASSO). (Note: Currently, only polynomial degrees of 1 are supported)
% 
% degOfSparsity - specifies the degree at which unimportant variables v_i
% are truncated in the HAVOK-SINDy algorithm.
% 
% MLmethod - specify which type of model is trained on the forcing term vr.
% The user may specify Random Forest Regression (RFR), Regression Trees,
% and various Neural Networks; Multilayer Perceptrons (MLPs), Long-Short
% Term Memory (LSTM) models, etc.
% 
% treeSize/maxNumSplits - specifies properties of the ML method. In this
% case the number of ensembled trees and number of splits in those trees.
% 
% D - The ML method uses previous values of the data x to predict the next
% value of vr. The parameter D specifies the spacing between these previous
% values. For example, if D = 5, the ML method uses [x(t), x(t-5dt),
% x(t-10dt), ...] to predict vr(t+dt). The number of x-predictors is
% limited by the stackmax of the HAVOK model.

%   Copyright 2023 Elise Jonsson

%% Generate/Import Data
close all; clear; clc
mkdir("./downloaded"); mkdir("./data");
addpath('./utils','./plotting','./data','./downloaded');

% generate nonlinear data
[t,x] = generateLorenz();  % Lorenz system
% [t,x] = generateRossler(); % Rossler system
x = x(:,1);
nVars = size(x,2);

% interpolate
tmax = t(end);
dt = t(2)-t(1);
dt = 0.1*dt;
tNew = (dt:dt:tmax)';
x = interp1(t,x,tNew,"makima","extrap");
t = tNew;

% standardize (removes constants from HAVOK model)
x = normalize(x);

% partition into training/validation/test data and visualize
[xTrain,xVal,xTest] = partitionData(x,0.5,0.1,'testData',true);
[tTrain,tVal,tTest] = partitionData(t,0.5,0.1,'testData',true);
plotData(tTrain,xTrain,tVal,xVal);

%% Train HAVOK-SINDy Model

% hyperparameters
stackmax = 40;
rmax = 11;
polyDegree = 1; % no support for >1 degrees
degOfSparsity = 1e-1;

% construct HAVOK-SINDy model
[Xi,list,U,S,VTrain,r] = sysidHAVOK( ...
    xTrain,tTrain,stackmax, ...
    'rmax',rmax, ...
    'degOfSparsity',degOfSparsity, ...
    'polyDegree',polyDegree ...
    );

% placeholder code (only works for polyDegree=1)
A = Xi(2:r,1:r-1)';
B = Xi(end,1:r-1)';

% construct forcing-augmented system
nStates = size(A,1);
nInputs = size(B,2);

M = [[A*dt , B*dt , zeros(nStates,nInputs)];
     [zeros(nInputs,nStates + nInputs), eye(nInputs)];
     [zeros(nInputs, nStates+2*nInputs)]];

expM = expm(M);
Ad = expM(1:nStates,1:nStates);
Bd1 = expM(1:nStates,nStates+1+nInputs:end);
Bd0 = expM(1:nStates,nStates+1:nStates+nInputs) - Bd1;

%% Train Machine-Learning (ML) model

% hyperparameters
maxNumSplits = 20;
treeSize = 20;
D = 5;
method = "RandomForestRegressor";

% training and validation data for x and v
HTrain = HankelMatrix(xTrain,stackmax);
HVal = HankelMatrix(xVal,stackmax);
VVal = inv(S)*inv(U)*HVal;

% use previous values of x to predict vr
vrTrain = {HTrain(1:D:end,1:end-1)',VTrain(2:end,r)};
vrVal = {HVal(1:D:end,1:end-1)',VVal(r,2:end)'};

% train ML model
Regressor = trainForcingModel( ...
    vrTrain,vrVal,method,...
    "MaxNumSplits",maxNumSplits,...
    "TreeSize",treeSize ...
    );

% validate ML model (the input dimension is flipped with perceptron)
vrpTrain = predict(Regressor,vrTrain{1});
vrpVal = predict(Regressor,vrVal{1});

% plot and zoom
zoomCoords = [90,110;103,105];

plotForcingModel( ...
    {tTrain(2:end-stackmax),VTrain(2:end,r)}, ...
    {tVal(2:end-stackmax),VVal(r,2:end)'}, ...
    {vrpTrain,vrpVal}, ...
    zoomCoords);

plotHistogram(VTrain(:,r));

%% Forecast and Validate Model

% get initial conditions for training/validation data in delay coordinates
vVal0 = VVal(1:r-1,1);
vTrain0 = VTrain(1:r-1,1);
vrVal = VVal(r,:);
vr = vrVal(1);

% true vr (theoretical HAVOK-SINDy performance)
% vr = vrVal;

% forecast
n = length(tVal)-stackmax-1;
v = vVal0;
US = U(:,1:r-1)*S(1:r-1,1:r-1);
for i = 1:n

    h = US*v(:,i);

    vr(i+1) = predict(Regressor,h(1:D:end)');

    v(:,i+1) = Ad*v(:,i) + Bd0*vr(i) + Bd1*vr(i+1);

    if mod(i,100)==0 || i==n
        disp(i+"/"+n)
    end
end

% recover x from v
xSimVal = recoverState(v',U,S,r,'cross-diagonal');
vrSimVal = vr';
vSimVal = v;

% model performance
xTarget = xVal(1:length(xSimVal));
RMSE = rmse(xSimVal,xTarget);
NMSE = miscFunctions.nmse(xSimVal,xTarget);
[R,pvalue] = corr(xSimVal,xTarget,'type','Pearson');
R2 = R^2;

% plot
plotForecast( ...
    tVal(1:length(xSimVal)), ...
    xVal(1:length(xSimVal)), ...
    xSimVal, ...
    vrVal(1:length(vrSimVal)),...
    vrSimVal ...
    );

plotAttractor( ...
    tVal(1:length(xSimVal)), ...
    VVal(:,1:length(xSimVal)), ...
    vSimVal ...
    );

%% Impulse Response of HAVOK Model

% impulse response using exact vr
[~,vimpulse] = impulseHAVOK(A,B,tVal(1:end-stackmax),vrVal',vVal0);

hold on
plot(tVal(1:end-stackmax),VVal(1,:))
title('Impulse Response of HAVOK Model with True Intermittent Forcing')
set(gca,'fontsize',20)
legend('Predicted','True')

