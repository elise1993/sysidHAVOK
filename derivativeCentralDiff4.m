%Derivative 4th Order Central Difference
   %
   %    dxdt = derivativeCentralDiff4(x,t) computes the discrete derivative
   %    of x(t) using a 4th order central difference scheme. To fill out
   %    the final values truncated by the central differencing, an Euler
   %    forward scheme is used. If x is a matrix, the derivative is
   %    computed for each column separately.
   %
   
%   Author(s): Elise Jonsson

function dxdt = derivativeCentralDiff4(x,t)

[n,m] = size(x);
dt = t(2)-t(1);
dxdt = nan(n-5,m);

% use central differencing to compute most derviatives
i = 3:n-3;
j = 1:m;
dxdt(i-2,j) = (-x(i+2,j) + 8*x(i+1,j) - 8*x(i-1,j) + x(i-2,j)) / (12*dt);

% use Euler forward for the final derivatives (creates instability)
% i = n-4:n
% dxdt(i,j) = (x(i,j) - x(i-1,j))/dt;

end