%generateLorenz
   %
   %    dxdt = generateLorenz(t,x,beta) simulates the Lorenz system of
   %    equations for the specified window of time t with parameters
   %    specified by beta and initial conditions x0. If t, beta or x0 are
   %    unspecified, default values are used.
   %
   
%   Author(s): Elise Jonsson

% generate data by solving the Lorenz system
function [t,x] = generateLorenz(t,x0,beta)

% initial conditions (default)
switch nargin
    case 0
        tmax = 50;
        dt = 0.1;
        t = 0:dt:tmax;
        x0 = [0, 1, 20]';
    case 1
        x0 = [0, 1, 20]';
    otherwise
end

% solve the Lorenz system using the Runge-Kutta 4,5 scheme:
options = odeset('RelTol',1e-12,'AbsTol',1e-12*ones(1,3));

switch nargin
    case {0,1,2}
        [t,x] = ode45(@(t,x) lorenzSystem(t,x),t,x0,options);
    otherwise
        [t,x] = ode45(@(t,x) lorenzSystem(t,x,beta),t,x0,options);
end

end