%generateLinear
   %
   %    dxdt = generateLinear(t,x,beta) simulates the Linear system of
   %    equations for the specified window of time t with initial 
   %    conditions x0. If t and x0 are unspecified, default values are used.
   %
   
%   Author(s): Elise Jonsson

% generate data by solving the following Linear system
function [t,x] = generateLinear(t,x0)

% initial conditions (default)
switch nargin
    case 0
        t = 0:.1:10;
        tmax = max(t);
        dt = t(2)-t(1);
        x0 = [10;10]';
    case 1
        x0 = [10;10]';
    otherwise
end

% system
A = [-0.1+1i*.5, 1 ; 0, -0.1-1i*.5]; % diagonalizable
% A = [-0.1+1i*.5, 1 ; 0, -0.1+1i*.5]; % undiagonalizable
f = @(t,x) A*x;

% solve the Lorenz system using the Runge-Kutta 4,5 scheme:
options = odeset('RelTol',1e-12,'AbsTol',1e-12*ones(size(x0)));
[t,x] = ode45(f,t,x0,options);
x = real(x);

end

