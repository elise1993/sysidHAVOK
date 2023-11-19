%generateLorenz
   %
   %    dxdt = generateLorenz(t,x,beta) simulates the Lorenz system of
   %    equations for the specified window of time t with parameters
   %    specified by beta and initial conditions x0. If t, beta or x0 are
   %    unspecified, default values are used.
   %
   
%   Author(s): Elise Jonsson

% generate data by solving the Lorenz system
function [t,x] = generateLorenz(opt)

arguments
    opt.t (:,1) {mustBeReal,mustBeMonotonic(opt.t)} = 0:0.05:100
    opt.x0 (3,1) {mustBeReal} = [0, 1, 20]'
    opt.beta (3,1) = [10, 28, 8/3]'
end

% solve the Lorenz system using the RKF45 scheme:
options = odeset('RelTol',1e-12,'AbsTol',1e-12*ones(1,3));
[t,x] = ode45(@(t,x) lorenzSystem(t,x,opt.beta),opt.t,opt.x0,options);

end

% test for monotonicity
function mustBeMonotonic(a)
    if any(diff(a) < 0)
        eid = 'Monotonic:false';
        msg = 'The time array (a) must consist of monotonically increasing values!';
        error(eid,msg)
    end
end