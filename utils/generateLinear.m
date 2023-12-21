%generateLinear
   %
   %    dxdt = generateLinear(t,x,beta) simulates the Linear system of
   %    equations for the specified window of time t with initial 
   %    conditions x0. If t and x0 are unspecified, default values are used.
   %
   
%   Author(s): Elise Jonsson

% generate data by solving the following Linear system
function [t,x] = generateLinear(opt)

arguments
    opt.t (:,1) {mustBeReal,mustBeMonotonic(opt.t)} = 0:.1:10
    opt.x0 (1,2) {mustBeReal} = [10;10]'
end

% system
A = [-0.1+1i*.5, 1 ; 0, -0.1-1i*.5];
f = @(t,x) A*x;

% solve the system using the RKF 4,5 scheme:
options = odeset('RelTol',1e-12,'AbsTol',1e-12*ones(size(opt.x0)));
[t,x] = ode45(f,opt.t,opt.x0,options);
x = real(x);

end

% test for monotonicity
function mustBeMonotonic(a)
    if any(diff(a) < 0)
        eid = 'Monotonic:false';
        msg = 'The time array (a) must consist of monotonically increasing values!';
        error(eid,msg)
    end
end

