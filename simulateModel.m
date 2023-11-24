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

%   Author(s): Elise Jonsson, based on code by Brunton & Kutz (2022)

%% Data Pre-Processing
close all
clear
clc

% linear data
% tmax = 1000;
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

% partition sequential data into training, validation, and test data
[xtrain,xval,xtest] = partitionData(x,.6,.2,.2);
[ttrain,tval,ttest] = partitionData(t,.6,.2,.2);

%% Construct HAVOK Model

% hyperparameters
stackmax = 40;
rmax = 15;
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
[A,B,U,S,V,r] = sysidHAVOK(xtrain,ttrain, ...
    'stackmax',stackmax, ...
    'rmax',rmax, ...
    'method','sparse',...
    'degOfSparsity',degOfSparsity);

% build linear system dvdt = f(t,v) = Av_[1:r-1](t)
f = @(t,v) A(:,1:r-1)*v(1:r-1);

%% Forecast and Validate Model

% get initial conditions for validation data in delay coordinates
Hval = HankelSVD(xval,stackmax);
Vval = (inv(S)*inv(U)*Hval)';
v0 = Vval(1,1:r-1);

% closed loop forecast with RKF45 during the validation period
[~,vSim] = ode45(@(t,v) f(t,v),[tval;ttest],v0);

% recover Hankel matrix from the simulated data
Hsim = U*S(:,1:r-1)*vSim';

% recover the simulated x by taking the cross-diagonal average of the Hankel matrix
xSim = spdiags(Hsim(end:-1:1,:));
xSim(xSim==0) = nan;
xSim = nanmean(xSim)';
xSim = xSim(1:length([tval;ttest]));

% model performance on validation data (RMSE)
rmseSim = rmse(xSim(1:length(xval)),xval);

%% Plotting

% plot true vs simulated
figure; hold on
plot(tval,xval,'b',linewidth=2)
plot([tval;ttest],xSim,'r:',linewidth=2)
title("Simulated vs True Behavior on Validation Data")
xlabel("t"); ylabel("x(t)")
legend("True Trajectory","Closed-Loop Forecast (Linear)")
set(gca,fontsize=20)
text(.65,.75,0,"RMSE (Linear): "+num2str(rmseSim),units='normalized',fontsize=20)

% plot true vs simulated (first 6 delay-coordinates)
figure; tiledLayout = tiledlayout(3,2);
title(tiledLayout,"Simulated vs True Behavior on Validation \newline Data in the Trained Delay Coordinates")
for i = 1:6
    try
        nexttile
        plot(Vval(:,i),'b')
        hold on
        plot(vSim(:,i),'r--')
        ylabel("v " + i)
    catch
    end

    if i==1
        leg = legend('Target','Forecast');
        set(leg,'Orientation','Horizontal','Position',[0.757,0.02,0.15,0.04],'Units','Normalized')
    end
end

% reconstructed attractor
figure; hold on
% plot3(Vval(:,1),Vval(:,2),Vval(:,3),'b',linewidth=2)
plot3(vSim(:,1),vSim(:,2),vSim(:,3),'r:',linewidth=2)
title("Reconstructed Attractor of the Dominant Delay Variables")
xlabel("v_1(t)"); ylabel("v_2(t)"); zlabel("v_3(t)")
legend("Closed-Loop Forecast (Linear)")
set(gca,fontsize=20)
view(-45,45)



