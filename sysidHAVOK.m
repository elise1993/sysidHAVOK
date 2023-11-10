%sysidHAVOK  system identification based on the HAVOK algorithm
%
%    dvdt = sysidHAVOK(x,t) returns a function dvdt representing a
%    Koopman-based linearization of the data x from a nonlinear system.
%    The algorithm essentially decomposes a nonlinear system x into a
%    set of linearized systems of equations dv/dt = A v_[1:r-1](t) plus
%    a nonlinear intermittent forcing term B v_r(t):
%
%         dv/dt = A v_[1:r-1](t) + B v_r(t)
%
%    - The input data x(t) is a vector time series or sequence of numbers
%    generated by a nonlinear system.
%
%    - The variable v(t) is a vector representing each scalar value of
%    x(t) in delay coordinates. v_[1:r-1](t) are the first r-1 elements
%    of the vector v(t), whereas v_r(t) represents the r:th element of
%    v(t), where r is an optimal truncation based on the Singular Value
%    Decomposition (SVD)
%
%    - A and B are matrices specifying the coupling between the delay-
%    variables in v(t).
%
%    For more information, see "Data-Driven Science and Engineering",
%    Brunton & Kutz (2022), Cambridge University Press, URL:
%    https://www.cambridge.org/highereducation/product/9781009089517/book
%

%   Author(s): Elise Jonsson, based on code by Brunton & Kutz (2022)

function [A,B,U,S,V,H,x,t,r] = sysidHAVOK(rmax,stackmax,x,t)

% specify number of delay coordinates (stackmax) and maximum number of
% singular values to include in the HAVOK model (rmax) (default):
if nargin == 0
    % define algorithm to automatically determine a good stackmax/rmax
    stackmax = 20;
    rmax = 300;
end

% if no data is provided, generate data from the Lorenz system:
if nargin < 3
    [t,x] = generateLorenz();
    x = x(:,1);
end
n = length(x);

% construct Hankel matrix and apply SVD
H = nan(stackmax,n-stackmax);
for k=1:stackmax
    H(k,:) = x(k:end-stackmax-1+k);
end

[U,S,V] = svd(H,'econ');

% identify the optimal threshold of singular values
singularVals = diag(S);
aspectRatio = size(H,1) / size(H,2);

% identify optimal hard thresholding of singular values based on Gavish &
% Donoho (2014) using MATLAB code by github/bwbrunton:
switch exist("optimal_SVHT_coef.m",'file')
    case 0
        disp("'optimal_SVHT_coef.m' not found in current directory, retrieving...")
        url = "https://github.com/bwbrunton/dmd-neuro/blob/master/optimal_SVHT_coef.m?raw=true";
        websave("optimal_SVHT_coef.m",url);
    otherwise
end

hardThreshold = optimal_SVHT_coef(aspectRatio,0) * median(singularVals);
r = length(singularVals(singularVals > hardThreshold));
r = min(rmax,r);

% compute derivative using 4th order central difference
dVdt = nan(n-stackmax-5,r);
for k = 1:r
    dVdt(:,k) = derivativeCentralDiff4(V(:,k),t);
end

%  build linear regression model in delay coordinates
Xi = V(3:end-3,1:r)\dVdt;
A = Xi(1:r-1,1:r-1)';
B = Xi(end,1:r)';

end










