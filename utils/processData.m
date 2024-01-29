function [t,x,dt,xMean,xSTD] = processData(t,x,opt)
%processData Add noise, remove outliers, interpolate, and normalize data.
%
%   [t,x] = processData(t,x,opt) is a data processing function where the
%   user may add noise, remove outliers, interpolate, and normalize data.
% 
   
%   Copyright 2023 Elise Jonsson

arguments(Input)
    t (:,1) {miscFunctions.mustBeMonotonic(t),...
        miscFunctions.mustBeEquidistant(t)}

    x (:,1) {mustBeReal}

    opt.DegreeOfNoise (1,1) {mustBeReal,...
        mustBeGreaterThanOrEqual(opt.DegreeOfNoise,0)} = 0

    opt.NoiseDistribution {mustBeMember(opt.NoiseDistribution,["Gaussian",...
        "Uniform","Gamma"])} = "Gaussian"

    opt.PercentOutliers (1,1) {mustBeReal,...
        mustBeGreaterThanOrEqual(opt.PercentOutliers,0)} = 0

    opt.SmoothingMethod {mustBeMember(opt.SmoothingMethod,['moving',...
        'lowess','loess','sgolay','rlowess','rloess'])} = 'moving'

    opt.SmoothingWindowSize {mustBePositive,mustBeInteger} = 1

    opt.InterpolationMethod (1,1) {mustBeMember(opt.InterpolationMethod,...
        ["linear","nearest","next","previous","spline","pchip","cubic",...
        "v5cubic","makima"])} = "linear"

    opt.InterpolationFactor (1,1) {mustBeReal,mustBePositive} = 1

    opt.OutlierMethod (1,1) {mustBeMember(opt.OutlierMethod,["median",...
        "mean","quartiles","grubbs","movmean","movmedian","gesd"])}

    opt.FillMethod (1,1) {mustBeMember(opt.FillMethod,["linear","makima",...
        "nearest","next","spline","constant","movmean","movmedian","pchip",...
        "knn"])} = "makima"

    opt.Normalize (1,1) {mustBeMember(opt.Normalize,[1,0])} = false
end

arguments(Output)
    t (:,1)
    x (:,1) {mustBeReal}
    dt (1,1) {mustBeReal}
    xMean (1,1) {mustBeReal}
    xSTD (1,1) {mustBeReal}
end

% corrupt data
x = addNoise(x, ...
    "Distribution",opt.NoiseDistribution,...
    "DegreeOfNoise",opt.DegreeOfNoise ...
    );

x = addOutliers(x, ...
    "PercentOutliers",opt.PercentOutliers ...
    );

% enhance data
x = smooth(x,...
    opt.SmoothingWindowSize,...
    opt.SmoothingMethod ...
    );

[x,t,dt] = interpolateData(x,t,...
    "InterpolationFactor",opt.InterpolationFactor,...
    "InterpolationMethod",opt.InterpolationMethod ...
    );

if isfield(opt,"OutlierMethod")
    x = filloutliers(x,...
        opt.FillMethod,...
        opt.OutlierMethod ...
        );
end

x = fillmissing(x,opt.FillMethod);

[xNorm,xMean,xSTD] = normalize(x);
if opt.Normalize
    x = xNorm;
end
