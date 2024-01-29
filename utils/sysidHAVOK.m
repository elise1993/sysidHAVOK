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

    opt.RegularizedDifferentiation (1,1) {mustBeMember(...
        opt.RegularizedDifferentiation,[1,0])} = 1

    opt.RegularizationParameter (1,1) {mustBeReal,mustBePositive} = 10

    opt.DerivativeIterations (1,1) {mustBeReal,mustBePositive} = 10

    opt.Conditioning (1,1) {mustBeReal,mustBePositive} = 1e-6
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
    filename = "optimal_SVHT_coef.m";
    if ~exist(filename,'file')
            disp(filename+" not found in current directory, retrieving...")
            url = "https://github.com/bwbrunton/dmd-neuro/blob/master/optimal_SVHT_coef.m?raw=true";
            websave("./downloaded/"+filename,url);
    end

    hardThreshold = optimal_SVHT_coef(aspectRatio,0) * median(singularVals);
    r = length(singularVals(singularVals > hardThreshold));
    r = min(opt.rmax,r);
end

% compute derivatives
dVdt = derivativeCentralDiff4(V(:,1:r),t);
dt = t(2)-t(1);

if opt.RegularizedDifferentiation == true

    filename = "TVRegDiff.m";
    if ~exist(filename,'file')
        disp(filename+" not found in current directory, retrieving...")
        url = "https://github.com/JeffreyEarly/GLNumericalModelingKit/blob/master/Matlab/TVRegDiff.m?raw=true";
        websave("./downloaded/"+filename,url);
    end

    % simpler computations with 'large', ideal for large systems >1000
    if numel(V) > 1e6
        ScaleOptimization = 'large';
        indices = 3:length(V)-3;
    else
        ScaleOptimization = 'small';
        indices = 3:length(V)-4;
    end

    % larger values give less accurate peaks but more stability

    % plots/verbose
    plotFlag=0;
    diagFlag=1;

    for i = 1:r

        dVdt(:,i) = TVRegDiff(V(indices,i),...
            opt.DerivativeIterations,...
            opt.RegularizationParameter, ...
            dVdt(:,i), ...
            ScaleOptimization, ...
            opt.Conditioning, ...
            dt, ...
            plotFlag, ...
            diagFlag ...
            );
    
    end
end

% retrieve SINDy files from github/dynamicslab if unavailable
filename = ["poolData.m","sparsifyDynamics.m","poolDataLIST.m"];
for i = 1:length(filename)
    if ~exist(filename(i),'file')
        disp(filename(i)+" not found in current directory, retrieving...")
        url = "https://github.com/dynamicslab/databook_matlab/blob/master/CH07/";
        websave("./downloaded/"+filename(i),url+filename(i)+"?raw=true");
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
