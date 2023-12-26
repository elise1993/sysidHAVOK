function [t,x] = generateLorenz(opt)
%generateLorenz Generate data from the Lorenz system
%
%    dxdt = generateLorenz(opt) simulates the Lorenz system of equations 
%    for the specified window of time t with parameters specified by beta
%    and initial conditions x0. If t, beta or x0 are unspecified, default
%    values are used.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    opt.t (:,1) {mustBeReal,...
        miscFunctions.mustBeMonotonic(opt.t)} = 0.01:0.01:200;
    opt.x0 (3,1) {mustBeReal} = [-8, 8, 27]'
    opt.beta (3,1) = [10, 28, 8/3]'
end

% solve the Lorenz system using the RKF45 scheme:
tolerances = odeset('RelTol',1e-12,'AbsTol',1e-12*ones(1,3));

[t,x] = ode45( ...
    @(t,x) lorenzSystem(t,x,opt.beta), ...
    opt.t, ...
    opt.x0, ...
    tolerances ...
    );


