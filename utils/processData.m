function [t,x,dt,xMean,xSTD] = processData(t,x,opt)
%processData Add noise, remove outliers, interpolate, and normalize data.
%
%   [t,x] = processData(t,x,opt) is a data processing function where the
%   user may add gaussian noise, remove outliers, interpolate, and
%   normalize data.
% 
   
%   Copyright 2023 Elise Jonsson

arguments(Input)
    t (:,1) {miscFunctions.mustBeMonotonic(t),...
        miscFunctions.mustBeEquidistant(t)}

    x (:,1) {mustBeReal}

    opt.DegreeOfNoise (1,1) {mustBeReal,mustBeGreaterThanOrEqual(opt.DegreeOfNoise,0)} = 0

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

% add noise
x = x + opt.DegreeOfNoise*std(x,'omitmissing')*randn(size(x));

% interpolate
tmax = t(end);
dt = t(2)-t(1);
dt = dt*opt.InterpolationFactor;
tNew = (t(1):dt:tmax)';
x = interp1(t,x,tNew,opt.InterpolationMethod,"extrap");
t = tNew;

% remove outliers/missing values
if isfield(opt,"OutlierMethod")
    outliers = isoutlier(x,opt.OutlierMethod);
    x(outliers) = nan;
end
x = fillmissing(x,opt.FillMethod);

% normalize
[xNorm,xMean,xSTD] = normalize(x);
if opt.Normalize
    x = xNorm;
end
