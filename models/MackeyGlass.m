function dxdt = MackeyGlass(t,x,xtau,beta)
%MackeyGlass Model of the Mackey Glass system
%
%    dxdt = MackeyGlass(t,x,beta) is a function variable for the Mackey
%    Glass system for the parameters specified by beta. If beta is
%    unspecified, default values are used (a=0.2, b=0.1, r=10, τ=17)
%
   
%   Copyright 2023 Elise Jonsson

if nargin < 4
    % default parameter values
    beta = [0.2,0.1,10,17]';
end

% dde version
dxdt = beta(1)*(xtau / (1 + xtau^beta(3))) - beta(2)*x;

% ode version
% dxdt = beta(1)*x*(t-beta(4)) / ...
%     (1 + x.^beta(3) * (t - beta(4)));

end