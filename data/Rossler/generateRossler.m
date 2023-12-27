function [t,x] = generateRossler(opt)
%generateRossler Generate data from the Rossler system
%
%    dxdt = generateRossler(opt) simulates the Rossler system of equations 
%    for the specified window of time t with parameters specified by beta
%    and initial conditions x0. If t, beta or x0 are unspecified, default
%    values are used. The system of equations is solved using the
%    Runge-Kutta 4,5 Scheme (ode45).
%
   
%   Copyright 2023 Elise Jonsson

arguments
    opt.t (:,1) {mustBeReal,...
        miscFunctions.mustBeMonotonic(opt.t)} = 0.01:0.01:200
    opt.x0 (3,1) {mustBeReal} = [1,1,1]'
    opt.beta (3,1) = [0.1,0.1,14]'
end

tolerances = odeset('RelTol',1e-12,'AbsTol',1e-12*ones(1,3));

[t,x] = ode45( ...
    @(t,x) rosslerSystem(t,x,opt.beta), ...
    opt.t, ...
    opt.x0, ...
    tolerances ...
    );


