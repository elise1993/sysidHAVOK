%lorenzSystem
   %
   %    dxdt = lorenzSystem(t,x,beta) is a function variable for the Lorenz
   %    system of equation for the set of parameters specified by beta.
   %    If the beta parameters are unspecified, the default values for
   %    chaotic conditions beta=[10,28,8/3] are used.
   %
   
%   Author(s): Elise Jonsson

function dxdt = lorenzSystem(t,x,beta)

% default parameter values (chaotic conditions)
if nargin < 3
    beta = [10, 28, 8/3]';
end

% model equations
dxdt = [
    beta(1) * (x(2) - x(1));

    x(1) * (beta(2) - x(3)) - x(2);
    
    x(1) * x(2) - beta(3) * x(3);
    
    ];

end