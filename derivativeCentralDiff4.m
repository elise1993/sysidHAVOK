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

% compute derivatives n+2
for i = 3:n-3
    % use central differencing to compute most derviatives
    dxdt(i-2) = (-x(i+2) + 8*x(i+1) - 8*x(i-1) + x(i-2)) / (12*dt);
end

% for i = n-4:n
%     % use Euler forward for the final derivatives (creates instability)
%     dxdt(i) = (x(i) - x(i-3))/(3*dt);
% end


end