function dxdt = rosslerSystem(t,x,beta)
%rosslerSystem Model of the Rossler system
%
%    dxdt = rosslerSystem(t,x,beta) is a function variable for the Rossler
%    system of equations for the set of parameters specified by beta.
%    If the beta parameters are unspecified, the default values for
%    chaotic conditions beta=[0.1,0.1,14] are used.
%
   
%   Copyright 2023 Elise Jonsson

% default parameter values (chaotic conditions)
if nargin < 3
    beta = [0.1,0.1,14]';
end

% model equations
dxdt = [
    -x(2) - x(3);

    x(1) + beta(1)*x(2);
    
    beta(2) + x(3)*(x(1) - beta(3))
    
    ];

end