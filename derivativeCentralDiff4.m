%Derivative 4th Order Central Difference
   %
   %    dxdt = derivativeCentralDiff4(x,t) computes the discrete derivative
   %    of x(t) using a 4th order central difference scheme. To fill out
   %    the final values truncated by the central differencing, an Euler
   %    forward scheme is used.
   %
   
%   Author(s): Elise Jonsson

function dxdt = derivativeCentralDiff4(x,t)

n = length(x);
dt = t(2)-t(1);
dxdt = nan(n-5,1);

% use central differencing to compute most derviatives
i = 3:n-3;
dxdt(i-2) = (-x(i+2) + 8*x(i+1) - 8*x(i-1) + x(i-2)) / (12*dt);

% use Euler forward for the final derivatives (creates instability)
% i = n-4:n
% dxdt(i) = (x(i) - x(i-3))/(3*dt);

end