function [Xi,list,U,S,V,r] = sysidHAVOK(x,t,stackmax,opt)
% sysidHAVOK   Train a HAVOK-SINDy model
%
%   [Xi,list,U,S,V,r] = sysidHAVOK(x,t,opt) trains and returns a
%   HAVOK-SINDy-based model in the delay-coordinates specified by U,S,V
%   with optimal truncation r. Xi are the polynomial coefficients defined
%   by list.
% 
%   Arguments:
% 
%   x - single-variable sequential input data.
% 
%   t - time vector at which x is sampled (must be equidistant).
% 
%   stackmax - number of time-shifted copies of the input data x.
% 
%   rmax - maximum truncation threshold of singular values.
% 
%   r - truncation value used for model (overrides identification of
%   optimal truncation value).
% 
%   degOfSparsity - parameter determining how much sparsity is enforced in
%   the SINDy model, i.e. how many coefficients are set to zero in Xi.
% 
%   polyDegree - maximum polynomial degree allowed in SINDy-model. For
%   example, polyDegree=2 constructs a model of dxdt,dydt,dzdt using the 
%   polynomials: {1, x, y, z, x^2, x^2, z^2, xy, xz, yz} [Only polyDegree=1
%   supported at this time]
% 

%   Copyright 2023 Elise Jonsson

arguments
    x (:,1) {mustBeReal}
    
    t (:,1) {mustBeReal,miscFunctions.mustBeEqualLength(t,x)}
    
    stackmax (1,1) {mustBeInteger,mustBePositive}

    opt.rmax (1,1) {mustBeInteger,mustBePositive}

    opt.r (1,1) {mustBeInteger,mustBePositive}

    opt.DegreeOfSparsity (1,1) {mustBeNumeric,mustBeReal, ...
        mustBeGreaterThanOrEqual(opt.DegreeOfSparsity,0)} = 0

    opt.PolynomialDegree (1,1) {mustBePositive,mustBeInteger, ...
        mustBeLessThanOrEqual(opt.PolynomialDegree,1)} = 1
end

disp("Training HAVOK-SINDy model...")

% if unspecified, set rmax to its maximum possible value
if ~isfield(opt,'rmax')
    opt.rmax = stackmax;
end

% construct Hankel matrix and apply Singular Value Decomposition
H = HankelMatrix(x,stackmax);
[U,S,V] = HankelSVD(H);

% identify the optimal hard threshold of singular values
singularVals = diag(S);
aspectRatio = size(H,1) / size(H,2);

% unless specified, identify optimal hard thresholding of singular values
% based on Gavish & Donoho (2014) and retrieve the required files from 
% github/bwbrunton if unavailable
if isfield(opt,'r')
    r = opt.r;
else
    if ~exist("optimal_SVHT_coef.m",'file')
            disp("'optimal_SVHT_coef.m' not found in current directory, retrieving...")
            url = "https://github.com/bwbrunton/dmd-neuro/blob/master/optimal_SVHT_coef.m?raw=true";
            websave("./downloaded/optimal_SVHT_coef.m",url);
    end

    hardThreshold = optimal_SVHT_coef(aspectRatio,0) * median(singularVals);
    r = length(singularVals(singularVals > hardThreshold));
    r = min(opt.rmax,r);
end

% compute derivative
dVdt = derivativeCentralDiff4(V(:,1:r),t);

% retrieve SINDy files from github/dynamicslab if unavailable
files = ["poolData.m","sparsifyDynamics.m","poolDataLIST.m"];
for i = 1:length(files)
    if ~exist(files(i),'file')
        disp(files(i)+" not found in current directory, retrieving...")
        url = "https://github.com/dynamicslab/databook_matlab/blob/master/CH07/";
        websave("./downloaded/"+files(i),url+files(i)+"?raw=true");
    end
end

% assign variabless to GPU if large enough
if numel(V) > 1e7 & canUseGPU
    V = gpuArray(V);
    dVdt = gpuArray(dVdt);
end

if opt.DegreeOfSparsity > 0
    % perform SINDy
    Theta = poolData(V(3:end-3,1:r),r,opt.PolynomialDegree);
    Xi = sparsifyDynamics(Theta,dVdt,opt.DegreeOfSparsity,r);
else
    % perform least-squares
    Xi = V(3:end-3,1:r)\dVdt;
    Xi = [zeros(1,r);Xi];
end

list = poolDataLIST(cellstr("v"+(1:r)),Xi,r,opt.PolynomialDegree);

[Xi,U,S,V] = gather(Xi,U,S,V);
