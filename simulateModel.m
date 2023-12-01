%simulateModel - system identification and forecasting using HAVOK
%
%    This code generates some data from a linear or nonlinear system and
%    finds a Koopman-based linear representation of the system in delay
%    coordinates using the Hankel Alternative View of Koopman (HAVOK)
%    algorithm. This code requires the specification of the following
%    parameters:
% 
%    - x,t,x0 - Single-variable data, x, from a system at times t, with
%    initial condition x0.
% 
%    - stackmax - number of time(delay)-shifted copies of the data x, which
%    represents the memory of the HAVOK model. Similar to an Auto-Regressive
%    model, A longer memory allows for longer dependencies, but increases
%    the complexity of the model.
% 
%    - rmax - the maximum rank of the HAVOK model, defined as the maximum
%    number of singular values to retain when performing Singular Value
%    Decomposition (SVD). A low rank model retains only the lower order
%    statistics (moments) of the system, whereas a higher rank model also
%    captures higher order moments and more detail.
%

%   Author(s): Elise Jonsson, based on Brunton & Kutz (2022)
%   "Data-Driven Science and Engineering" 2nd Ed.

%% Data Pre-Processing
close all
clear
clc
rng(1) % for reproducibility

% linear data
% tmax = 100;
% dt = 0.05;
% t = 0:dt:tmax;
% [t,x] = generateLinear(t=t);
% x = x(:,1);

% nonlinear data
tmax = 200;
dt = 0.05;
t = 0:dt:tmax;
n = length(t);
x0 = [5, 10, 2]';
[t,x] = generateLorenz(t=t,x0=x0);
x = x(:,1);

% partition sequential data into training and validation sets
[xTrain,xVal] = partitionData(x, 0.5, 0.5, "testData", false);
[tTrain,tVal] = partitionData(t, 0.5, 0.5, "testData", false);

%% Construct HAVOK Model

% hyperparameters
stackmax = 40;
rmax = stackmax;
degOfSparsity = 0;

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
% superfluous GPU support
=======
% superfluous GPU support (add to dependent functions instead)
>>>>>>> 0024454 (added superfluous GPU support)
if canUseGPU
    t = gpuArray(t);
    x = gpuArray(x);
end

<<<<<<< HEAD
=======
>>>>>>> f047c9c (Version 1 of algorithm, without any optimization.)
=======
>>>>>>> 0024454 (added superfluous GPU support)
=======
>>>>>>> 4065f4d (Vectorized Hankel matrix construction)
% construct HAVOK model from data
[A,B,U,S,VTrain,r] = sysidHAVOK(xTrain,tTrain, ...
    'stackmax',stackmax, ...
    'rmax',rmax, ...
    'method','sparse',...
    'degOfSparsity',degOfSparsity);

vr = forcingFunction(tTrain(1:end-stackmax),VTrain(:,r), ...
    'method','overfit');

f = @(t,v) A*v(1:r-1) + B*vr(t);

%% Forecast and Validate Model

% get initial conditions for training/validation data in delay coordinates
HVal = HankelSVD(xVal,stackmax);
VVal = (inv(S)*inv(U)*HVal)';
vVal0 = VVal(1,1:r-1);
vTrain0 = VTrain(1,1:r-1);

% closed loop forecast with RKF45 for training/validation period
[~,VSimTrain] = ode45(@(t,v) f(t,v),tTrain,vTrain0);
[~,VSimVal] = ode45(@(t,v) f(t,v),tVal,vVal0);

% recover state x from delay coordinates v
xSimTrain = recoverState(VSimTrain,U,S,r,'cross-diagonal');
xSimVal = recoverState(VSimVal,U,S,r,'cross-diagonal');

% model performance
rmseSimTrain = rmse(xSimTrain,xTrain);
rmseSimVal = rmse(xSimVal,xVal);

%% Plotting

% plot true vs simulated trajectory (full state, x)
figure
subplot(2,1,1); hold on
plot(tTrain,xTrain,'b',linewidth=2)
plot(tTrain,xSimTrain,'r:',linewidth=2)
sgtitle("Forecasted vs True Trajectory",'fontsize',26)
title("Training Period")
ylabel("x(t)")
set(gca,fontsize=20)
text(.65,.85,0,"RMSE: "+num2str(rmseSimTrain),units='normalized',fontsize=20)

subplot(2,1,2); hold on
plot(tVal,xVal,'b',linewidth=2)
plot(tVal,xSimVal,'r:',linewidth=2)
title("Validation Period")
xlabel("t"); ylabel("x(t)")
leg = legend("True","Forecast");
set(leg,'Orientation','Horizontal','Position',[0.757,0.02,0.15,0.04],'Units','Normalized')
set(gca,fontsize=20)
text(.65,.85,0,"RMSE: "+num2str(rmseSimVal),units='normalized',fontsize=20)

% plot true vs simulated trajectory (first 6 delay-coordinates, v) [training]
figure; tiledLayout = tiledlayout(3,2);
title(tiledLayout,"Simulated vs True Behavior on Training \newline Data in the Trained Delay Coordinates")
for i = 1:6
    try
        nexttile
        plot(VTrain(:,i),'b')
        hold on
        plot(VSimTrain(:,i),'r--')
        ylabel("v " + i)
    catch
    end

    if i==1
        leg = legend('Target','Forecast');
        set(leg,'Orientation','Horizontal','Position',[0.757,0.02,0.15,0.04],'Units','Normalized')
    end
end

% plot true vs simulated trajectory (first 6 delay-coordinates, v) [validation]
figure; tiledLayout = tiledlayout(3,2);
title(tiledLayout,"Simulated vs True Behavior on Validation \newline Data in the Trained Delay Coordinates")
for i = 1:6
    try
        nexttile
        plot(VVal(:,i),'b')
        hold on
        plot(VSimVal(:,i),'r--')
        ylabel("v " + i)
    catch
    end

    if i==1
        leg = legend('Target','Forecast');
        set(leg,'Orientation','Horizontal','Position',[0.757,0.02,0.15,0.04],'Units','Normalized')
    end
end

% reconstructed attractor from first 3 delay-coordinates (training)
figure; hold on
plot3(VTrain(:,1),VTrain(:,2),VTrain(:,3),'b',linewidth=1)
plot3(VSimTrain(:,1),VSimTrain(:,2),VSimTrain(:,3),'r:',linewidth=1)
scatter3(VTrain(1,1),VTrain(1,2),VTrain(1,3),'go',linewidth=2)
title("Reconstructed Attractor of the Three Dominant Delay Variables (Training)")
xlabel("v_1(t)"); ylabel("v_2(t)"); zlabel("v_3(t)")
legend("True","Forecast","Initial Condition")
set(gca,fontsize=20)
% view(-45,45)
view(3)
xlim([-.04,.04]); ylim([-.06,.06]); zlim([-.1,.1])

% reconstructed attractor from first 3 delay-coordinates (validation)
figure; hold on
plot3(VVal(:,1),VVal(:,2),VVal(:,3),'b',linewidth=1)
plot3(VSimVal(:,1),VSimVal(:,2),VSimVal(:,3),'r:',linewidth=1)
scatter3(VVal(1,1),VVal(1,2),VVal(1,3),'go',linewidth=4)
title("Reconstructed Attractor of the Three Dominant Delay Variables (Validation)")
xlabel("v_1(t)"); ylabel("v_2(t)"); zlabel("v_3(t)")
legend("True","Forecast","Initial Condition")
set(gca,fontsize=20)
% view(-45,45)
view(3)
xlim([-.04,.04]); ylim([-.06,.06]); zlim([-.1,.1])

% visualize model coefficient matrix
load redwhiteblue.mat
figure
pcolor(A)
colormap(redwhiteblue)
colorbar










