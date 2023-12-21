%% Generate/Import Data
close all; clear; clc
mkdir("./downloaded"); mkdir("./data");
addpath('./utils','./plotting','./data','./downloaded');

% generate nonlinear data (Lorenz system)
tmax = 200;
dt = 0.01;
t = dt:dt:tmax;
x0 = [-8, 8, 27]';
beta = [10, 28, 8/3]';

[t,x] = generateLorenz(t, ...
    'initialCondition',x0, ...
    'beta',beta ...
    );

x = x(:,1);
nVars = size(x,2);

% interpolate
dt = 0.1*dt;
tNew = (dt:dt:tmax)';
x = interp1(t,x,tNew,"makima","extrap");
t = tNew;
N = length(x);

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
    xTrain,tTrain, ...
    'stackmax',stackmax, ...
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

% plot (make sure vr is well-behaved)
% figure
% plot(tTrain(1:end-stackmax),VTrain(:,r))
% xlim([92,93])

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

plotHistogram(VTrain(2:end,r))

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

    %vAug = expM*[v(:,i); vr(i); vr(i+1)-vr(i)];
    %v(:,i+1) = vAug(1:r-1);

    % or equivalently: (MUCH FASTER!)
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





