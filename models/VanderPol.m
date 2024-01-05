function dxdt = VanderPol(t,x,mu)
%VanderPol Model of the Van der Pol system
%
%    dxdt = VanderPol(t,x,beta) is a function variable for the Van der
%    Pol system of equations for the parameter specified by mu. If mu is
%    unspecified, default values are used (mu=5)
%
   
%   Copyright 2023 Elise Jonsson

if nargin < 3
    % default parameter values (chaotic conditions)
    mu = 5;
end

dxdt = [

    x(2)

    mu*(1-x(1).^2)*x(2) - x(1)
    
    ];

end