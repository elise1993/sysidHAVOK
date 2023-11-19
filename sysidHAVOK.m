%sysidHAVOK  system identification based on the HAVOK algorithm
%
%    [A,B,U,S,V,r] = sysidHAVOK(x,t,opt) returns a function dvdt
%    representing a Koopman-based linearization of the data x from a
%    nonlinear system. The algorithm essentially decomposes a nonlinear
%    system x into a set of linearized systems of equations
%    dv/dt = A v_[1:r-1](t) plus a nonlinear intermittent forcing term
%    B v_r(t):
%
%         dv/dt = A v_[1:r-1](t) + B v_r(t)
%
%    - The input data x(t) is a vector time series or sequence of numbers
%    generated by a system.
%
%    - The rows of of V represents scalar values of
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

function [A,B,U,S,V,r] = sysidHAVOK(x,t,opt)

% specify optional input arguments
arguments
    x (:,1) {mustBeNumeric,mustBeReal}
    t (:,1) {mustBeNumeric,mustBeReal,mustBeEqualLength(t,x)}
    opt.stackmax (1,1) {mustBeNumeric,mustBeReal,mustBePositive}
    opt.rmax (1,1) {mustBeNumeric,mustBeReal,mustBePositive}
    opt.r (1,1) {mustBeNumeric,mustBeReal,mustBePositive}
    opt.method (1,:) char {mustBeMember(opt.method,{'least-squares','sparse'})} = 'least-squares'
    opt.degOfSparsity (1,1) {mustBeNumeric,mustBeReal} = 0.01
end

% specify number of delay coordinates (stackmax) and maximum number of
% singular values to include in the HAVOK model (rmax) (default values):
if ~isfield(opt,'stackmax')
    % define algorithm to automatically determine a good stackmax/rmax
    opt.stackmax = floor(length(t)/2);
end

if ~isfield(opt,'rmax')
    opt.rmax = opt.stackmax;
end

% construct Hankel matrix and apply singular value decomposition
[H,U,S,V] = HankelSVD(x,opt.stackmax);

% identify the optimal threshold of singular values
singularVals = diag(S);
aspectRatio = size(H,1) / size(H,2);

% unless specified, identify optimal hard thresholding of singular values
% based on Gavish & Donoho (2014) using MATLAB code by github/bwbrunton:
if isfield(opt,'r')
    r = opt.r;
else
    switch exist("optimal_SVHT_coef.m",'file')
        case 0
            disp("'optimal_SVHT_coef.m' not found in current directory, retrieving...")
            url = "https://github.com/bwbrunton/dmd-neuro/blob/master/optimal_SVHT_coef.m?raw=true";
            websave("optimal_SVHT_coef.m",url);
        otherwise
    end

    hardThreshold = optimal_SVHT_coef(aspectRatio,0) * median(singularVals);
    r = length(singularVals(singularVals > hardThreshold));
    r = min(opt.rmax,r);
end

% compute derivative using 4th order central difference
dVdt = derivativeCentralDiff4(V(:,1:r),t);

%  build regression model in delay coordinates
Xi = V(3:end-3,1:r)\dVdt;
switch opt.method
    case 'least-squares'

    case 'sparse'

        for k=1:10
            smallIndices = (abs(Xi) < opt.degOfSparsity);
            Xi(smallIndices) = 0;
            for i = 1:r % r???
                biginds = ~smallIndices(:,i);
                Xi(biginds,i) = V(3:end-3,biginds)\dVdt(:,i);
            end
        end

end

A = Xi(1:r-1,1:r-1)';
B = Xi(end,1:r-1)';

end

% test for equal length
function mustBeEqualLength(a,b)
    if ~isequal(length(a),length(b))
        eid = 'Size:notEqual';
        msg = 'The data matrix (x) is not the same length as the time vector (t)!';
        error(eid,msg)
    end
end








