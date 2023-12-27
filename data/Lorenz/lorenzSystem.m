function dxdt = lorenzSystem(t,x,beta)
% lorenzSystem Model of the Lorenz system
%
%    dxdt = lorenzSystem(t,x,beta) is a function variable for the Lorenz
%    system of equations for the set of parameters specified by beta.
%    If the beta parameters are unspecified, the default values for
%    chaotic conditions beta=[10,28,8/3] are used.
%

%   Copyright 2023 Elise Jonsson

if nargin < 3
    % default parameter values (chaotic conditions)
    beta = [10, 28, 8/3]';
end

dxdt = [
    beta(1) * (x(2) - x(1));

    x(1) * (beta(2) - x(3)) - x(2);
    
    x(1) * x(2) - beta(3) * x(3);
    
    ];
