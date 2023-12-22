%generateLorenz
   %
   %    dxdt = generateLorenz(t,x,beta) simulates the Lorenz system of
   %    equations for the specified window of time t with parameters
   %    specified by beta and initial conditions x0. If t, beta or x0 are
   %    unspecified, default values are used.
   %
   
%   Author(s): Elise Jonsson

% generate data by solving the Lorenz system
function [t,x] = generateRossler(opt)

arguments
    opt.time (:,1) {mustBeReal,...
        miscFunctions.mustBeMonotonic(opt.time)} = 0.01:0.01:200
    opt.initialCondition (3,1) {mustBeReal} = [1,1,1]'
    opt.beta (3,1) = [0.1,0.1,14]'
end

% solve the Rossler system using the RKF45 scheme:
options = odeset('RelTol',1e-12,'AbsTol',1e-12*ones(1,3));
[t,x] = ode45(@(t,x) rosslerSystem(t,x,opt.beta) ...
    ,opt.time,opt.initialCondition,options);

end

