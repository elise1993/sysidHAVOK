%generateLorenz
   %
   %    dxdt = generateLorenz(t,x,beta) simulates the Lorenz system of
   %    equations for the specified window of time t with parameters
   %    specified by beta and initial conditions x0. If t, beta or x0 are
   %    unspecified, default values are used.
   %
   
%   Author(s): Elise Jonsson

% generate data by solving the Lorenz system
function [t,x] = generateLorenz(t,opt)

arguments
    t (:,1) {mustBeReal,miscFunctions.mustBeMonotonic(t)}
    opt.initialCondition (3,1) {mustBeReal} = [-8, 8, 27]'
    opt.beta (3,1) = [10, 28, 8/3]'
end

% solve the Lorenz system using the RKF45 scheme:
options = odeset('RelTol',1e-12,'AbsTol',1e-12*ones(1,3));
[t,x] = ode45(@(t,x) lorenzSystem(t,x,opt.beta) ...
    ,t,opt.initialCondition,options);

end

