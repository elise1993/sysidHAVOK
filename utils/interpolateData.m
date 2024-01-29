function [x,t,dt] = interpolateData(x,t,opt)

arguments
    x (:,1)

    t (:,1) {miscFunctions.mustBeEqualLength(x,t),...
        miscFunctions.mustBeEquidistant(t)}

    opt.InterpolationFactor (1,1) {mustBeReal,mustBePositive} = 1

    opt.InterpolationMethod (1,1) {mustBeMember(opt.InterpolationMethod,...
        ["linear","nearest","next","previous","spline","pchip","cubic",...
        "v5cubic","makima"])} = "linear"
end

tmax = t(end);
dt = t(2)-t(1);

dt = dt*opt.InterpolationFactor;
tNew = (t(1):dt:tmax)';

x = interp1(t,x,tNew,opt.InterpolationMethod,"extrap");
t = tNew;