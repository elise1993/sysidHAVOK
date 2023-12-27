function dxdt = derivativeCentralDiff4(x,t)
% derivativeCentralDiff4 Compute 4th order central derivative
%
%    dxdt = derivativeCentralDiff4(x,t) computes the discrete derivative
%    of x(t) using a 4th order central difference scheme. To fill out
%    the final values truncated by the central differencing, an Euler
%    forward scheme is used. If x is a matrix, the derivative is
%    computed for each column separately.
%
   
%   Copyright 2023 Elise Jonsson

[n,m] = size(x);
dt = t(2)-t(1);
dxdt = nan(n-5,m);

i = 3:n-3;
j = 1:m;
dxdt(i-2,j) = (-x(i+2,j) + 8*x(i+1,j) - 8*x(i-1,j) + x(i-2,j)) / (12*dt);

