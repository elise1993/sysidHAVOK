function dxdt = Duffing(t,x,beta)
%Duffing Model of the Duffing oscillator
%
%    dxdt = Duffing(t,x,beta) is a function variable for the Duffing
%    oscillator for the parameters specified by beta. If beta is
%    unspecified, default values are used (δ=0, α=1, β=4)
%
   
%   Copyright 2023 Elise Jonsson

if nargin < 3
    % default parameter values (chaotic conditions)
    beta = [0,1,4]';
end

dxdt = [

    x(2)

    -beta(1)*x(2) - beta(2)*x(1) - beta(3)*x(1).^3
    
    ];

end