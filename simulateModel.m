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
%    model, Aalonger memory allows for longer dependencies, but increases
%    the complexity of the model.
% 
%    - rmax - the maximum rank of the HAVOK model, defined as the maximum
%    number of singular values to retain when performing Singular Value
%    Decomposition (SVD). A low rank model retains only the lower order
%    statistics (moments) of the system, whereas a higher rank model also
%    captures higher order moments and more detail.
%

%   Author(s): Elise Jonsson, based on code by Brunton & Kutz (2022)

% initialization
close all
clear
clc

% linear data
% [t,x] = generateLinear();

% nonlinear data
t = linspace(0,10,1000);
x0 = [5, 10, 2]';
[t,x] = generateLorenz(t,x0);

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
% construct HAVOK model from data
x = x(:,1);
stackmax = 40;
rmax = stackmax;
[A,B,U,S,V,H,x,t,r] = sysidHAVOK(rmax,stackmax,x,t);

% build linear system dvdt = f(t,v) = Av_[1:r-1](t)
f = @(t,v) A(:,1:r-1)*v(1:r-1);

% get initial conditions in delay coordinates
v0 = inv(S)*inv(U)*H;
v0 = v0(1:r-1,1);

% solve system of ODEs (closed loop simulation)
[t,vSim] = ode45(@(t,v) f(t,v),t,v0);

% get true linear time series in delay coordinates
% vTrue = V(:,1:r-1);

% solve system of ODEs (open loop simulation)
vTrue = nan(size(V(:,1:r-1)));
dt = t(2)-t(1);
for k = 2:length(t)-stackmax
    % Euler forward
    vTrue(k,:) = V(k-1,1:r-1)' + (A(:,1:r-1)*V(k,1:r-1)' - B(1:r-1).*V(k,1:r-1)')*dt;
end

% reconstruct Hankel matrix H from v
Hsim = U*S(:,1:r-1)*vSim';
Htrue = U*S(:,1:r-1)*vTrue';

% reconstruct x using edges of Hankel matrix
% xSim = [Hsim(1,:)'; Hsim(2:end,end)];
% xTrue = [Htrue(1,:)'; Htrue(2:end,end)];

% reconstruct x using all values in the Hankel matrix
% (more accurate but cannot include zeroes in H; unlikely)
xSim = spdiags(Hsim(end:-1:1,:));
xSim(xSim==0) = nan;
xSim = nanmean(xSim)';

xTrue = spdiags(Htrue(end:-1:1,:));
xTrue(xTrue==0) = nan;
xTrue = nanmean(xTrue)';

% Root mean square error
rmseOpen = rmse(xTrue(2:end),x(2:end-1));
rmseClosed = rmse(xSim(1:length(x)),x);

% plot true vs simulated
figure; hold on
plot(x,'b',linewidth=2)
plot(xTrue,'g--',linewidth=2)
plot(xSim,'r:',linewidth=2)
title("Simulated vs True Behavior")
xlabel("t"); ylabel("x(t)")
legend("True Trajectory","Open-Loop Forecast (Linear)","Closed-Loop Forecast (Linear)")
set(gca,fontsize=20)
text(.65,.8,0,"RMSE (Open-Loop): "+num2str(rmseOpen),units='normalized',fontsize=20)
text(.65,.75,0,"RMSE (Closed-Loop): "+num2str(rmseClosed),units='normalized',fontsize=20)

% reconstructed attractor
figure; hold on
plot3(V(:,1),V(:,2),V(:,3),'b',linewidth=2)
plot3(vTrue(:,1),vTrue(:,2),vTrue(:,3),'g--',linewidth=2)
plot3(vSim(:,1),vSim(:,2),vSim(:,3),'r:',linewidth=2)
title("Reconstructed Attractor of the Dominant Delay Variables")
xlabel("v_1(t)"); ylabel("v_2(t)"); zlabel("v_3(t)")
legend("True Trajectory","Open-Loop Forecast (Linear)","Closed-Loop Forecast (Linear)")
set(gca,fontsize=20)
view(-45,45)




