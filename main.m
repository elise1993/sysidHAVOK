%% MAIN    main
% This code takes some data, interpolates it, partitions it into
% training/validation/testing sets, and finds a Koopman-based linear
% representation of the system in delay coordinates using HAVOK analysis
% and SINDy. It then trains a Machine Learning (ML) method on the 
% intermittent forcing term of HAVOK and uses this forcing model to 
% produce a forecast over the validation period. This code requires the
% specification of the following parameters:
% 
% x,t,x0 - Single-variable data, x, from a nonlinear chaotic system sampled
% at times t, with initial condition x0. Example data are generated from
% the following systems:
% 
%       - Lorenz
%       - Rossler
%       - VanderPol
%       - Duffing
%       - DoublePendulum
%       - MackeyGlass
%       - MagneticFieldReversal*
% 
%       * Based on Molina-Cardín et. al. (2021) "Simple stochastic model 
%         for geomagnetic excursions and reversals ...", PNAS
% 
% stackmax - number of time-shifted (delayed) copies of the data x, which
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
% DegreeOfNoise - the amount of Gaussian noise in the data x, as a fraction
% of the standard deviation of x. Note: The noise level in x will affect
% the optimal stackmax and r of the model.
% 
% PolynomialDegree - specifies the polynomial degree of the HAVOK-SINDy model.
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
% The user may specify the following methods, including various ensemble
% methods and neural networks:
% 
%   - Bagging (Bag)
%   - Boosting (LSBoost)
%   - Random Forest Regression (RFR)
%   - C++ Optimized Random Forest Regression (RFR-MEX)*
%   - Support Vector Regression (SVR)
%   - Multilayer Perceptron (MLP)
%   - Long-Short Term Memory (LSTM)
%   - Temporal Convolutional Network (TCN) [unfinished]
% 
%       * [by Leo Breiman et al. from the R-source by Andy Liaw et al.
%         http://cran.r-project.org/web/packages/randomForest/index.html
%         Ported to MATLAB by Abhishek Jaiantilal]
% 
% D - The ML method uses previous values of the data x to predict the next
% value of vr. The parameter D specifies the spacing between these previous
% values. For example, if D = 5, the ML method uses [x(t), x(t-5dt),
% x(t-10dt), ...] to predict vr(t+dt). The number of x-predictors is
% limited by the stackmax of the HAVOK model.

%   Copyright 2023 Elise Jonsson

close all; clear; clc

%% Hyperparameters

% data
SystemName = "Lorenz";
dt = 0.01;
Tolerance = 1e-12;
start = 1;
TrainFactor = 0.5;
ValFactor = 0.1;

% data corruption
DegreeOfNoise = 0;
NoiseDistribution = "Gaussian";
PercentOutliers = 0;

% data enhancement
SmoothingMethod = 'moving';
SmoothingWindowSize = 1;
InterpolationMethod = "cubic";
InterpolationFactor = 0.1;
OutlierMethod = "median";
FillMethod = "makima";
Normalize = false;

% HAVOK-SINDy model
stackmax = 39;
rmax = 7;
PolynomialDegree = 1;
DegreeOfSparsity = 0;
RegularizedDifferentiation = true;
RegularizationParameter = 10;
DerivativeIterations = 3;
Conditioning = 1e-6;

% ML model
MLmethod = "RFR-MEX";
D = 5;
zoomCoords = [0,120;92,93];

% ensemble methods (Bag, LSBoost, RFR, RFR-MEX)
MaxNumSplits = 50000;
NumTrees = 20;
MinLeafSize = 27;
NumFeaturesToSample = 2;

% support vector regression (SVR)
KernelFunction = "gaussian";

% neural networks (MLP, LSTM, TCN)
NumLayers = 2;
HiddenLayerSizes = [10,10];
ActivationFunction = "relu";
DropoutProbability = 0;
LearnRate = 1e-2;

% forecast
nSteps = 2e4;
multiStepSize = 1000;
SimulateForcing = true;

% pre-loaded hyperparameters
% load("tests\HAVOK-SINDy-Lorenz.mat");

%% Prepare Data
mkdir("./downloaded");
addpath('./utils','./plotting','./models','./downloaded',genpath('./data/'));

% generate nonlinear data
[t,x] = generateData(SystemName,...
    "Tolerance",Tolerance,...
    "dt",dt ...
    );

% process data
x = x(:,1);
[t,x,dt] = processData(t,x, ...
    ...
    ... % data corruption
    'DegreeOfNoise',DegreeOfNoise, ...
    'NoiseDistribution',NoiseDistribution, ...
    'PercentOutliers',PercentOutliers, ...
    ...
    ... % data enhancement
    'SmoothingMethod',SmoothingMethod, ...
    'SmoothingWindowSize',SmoothingWindowSize, ...
    'InterpolationMethod',InterpolationMethod, ...
    'InterpolationFactor',InterpolationFactor, ...
    'OutlierMethod',OutlierMethod, ...
    'FillMethod',FillMethod, ...
    'Normalize',Normalize ...
    );

% partition into training/validation/test data
[xTrain,xVal,xTest] = partitionData(x,...
    TrainFactor,ValFactor,'testData',true);

[tTrain,tVal,tTest] = partitionData(t,...
    TrainFactor,ValFactor,'testData',true);

% trim warmup data
xTrain = xTrain(start:end);
tTrain = tTrain(start:end);

plotData(tTrain,xTrain,tVal,xVal);


%% Train HAVOK-SINDy Model

% construct HAVOK-SINDy model
[Xi,list,U,S,VTrain,r] = sysidHAVOK( ...
    xTrain,tTrain,stackmax, ...
    'rmax',rmax, ...
    'DegreeOfSparsity',DegreeOfSparsity, ...
    'PolynomialDegree',PolynomialDegree, ...
    'RegularizedDifferentiation',RegularizedDifferentiation, ...
    'RegularizationParameter',RegularizationParameter, ...
    'DerivativeIterations',DerivativeIterations, ...
    'Conditioning',Conditioning ...
    );

% check how intermittent forcing behaves for this HAVOK decomposition
plotvr(tTrain(1:end-stackmax),VTrain(:,r),zoomCoords)

% construct forcing-augmented system
A = Xi(2:r,1:r-1)';
B = Xi(end,1:r-1)';

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

% training and validation data for x,v,vr
HTrain = HankelMatrix(xTrain,stackmax);
HVal = HankelMatrix(xVal,stackmax);
VVal = inv(S)*inv(U)*HVal;

% vr predictors (use previous values of x to predict vr)
hTrain = HTrain(1:D:end,1:end-1)';
hVal = HVal(1:D:end,1:end-1)';

% vr
vrTrain = VTrain(2:end,r);
vrVal = VVal(r,2:end)';

% train ML model
Regressor = trainForcingModel( ...
    {hTrain,vrTrain}, ...
    {hVal,vrVal}, ...
    MLmethod, ...
    ...
    ... % for ensemble methods
    "MaxNumSplits",MaxNumSplits, ...
    "NumTrees",NumTrees, ...
    "MinLeafSize",MinLeafSize, ...
    "NumFeaturesToSample",NumFeaturesToSample, ...
    ...
    ... % for support vector regression
    "KernelFunction",KernelFunction, ...
    ...
    ... % for neural networks
    "NumLayers",NumLayers, ...
    "HiddenLayerSizes",HiddenLayerSizes, ...
    "ActivationFunction",ActivationFunction, ...
    "DropoutProbability",DropoutProbability, ...
    "LearnRate",LearnRate ...
    );

% validate ML model
vrpTrain = predictML(Regressor,hTrain,MLmethod);
vrpVal = predictML(Regressor,hVal,MLmethod);

plotForcingModel( ...
    {tTrain(2:end-stackmax),vrTrain}, ...
    {tVal(2:end-stackmax),vrVal}, ...
    {vrpTrain,vrpVal}, ...
    zoomCoords, ...
    MLmethod ...
    );

plotHistogram(VTrain(:,r));

%% Forecast and Validate Model

[vSimVal,vrSimVal] = forecastHAVOK( ...
    VVal,U,S,Ad,Bd0,Bd1,stackmax,r, ...
    Regressor,MLmethod,D, ...
    nSteps,multiStepSize, ...
    'SimulateForcing',SimulateForcing ...
    );

% recover x from v
xSimVal = recoverState(vSimVal',U,S,r,'cross-diagonal');
vrSimVal = vrSimVal';

tTarget = tVal(1:length(xSimVal));
xTarget = xVal(1:length(xSimVal));
vrTarget = vrVal(1:length(vrSimVal));

% model performance
[RMSE,NMSE,R2,pvalue_R2] = forecastSkill(xTarget,xSimVal);

% plot
plotForecast( ...
    tTarget, ...
    xTarget, ...
    xSimVal, ...
    vrTarget,...
    vrSimVal, ...
    multiStepSize ...
    );

plotAttractor( ...
    tVal(1:length(xSimVal)), ...
    VVal(:,1:length(xSimVal)), ...
    vSimVal, ...
    multiStepSize ...
    );

%% Impulse Response of HAVOK Model

% external forcing
vrForce = vrVal';
vInitialCondition = VVal(1:r-1,1);

% impulse response using custom forcing
[~,vResponse] = responseHAVOK(A,B, ...
    tVal(1:end-stackmax-1),vInitialCondition,...
    "Custom","Forcing",vrForce);

xResponse = recoverState(vResponse,U,S,r,'cross-diagonal');

plotResponse( ...
    tVal(1:end-stackmax-1), ...
    xVal(1:end-stackmax-1), ...
    xResponse ...
    )

plotAttractor( ...
    tVal(1:end-stackmax-1), ...
    VVal(:,1:end-1), ...
    vResponse', ...
    1e6 ...
    );
legend('True','Response')