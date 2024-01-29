function x = addOutliers(x,opt)

arguments
    x (:,1)

    opt.PercentOutliers (1,1) {mustBeReal,...
        mustBeGreaterThanOrEqual(opt.PercentOutliers,0)} = 0
    
    opt.Replace {mustBeMember(opt.Replace,[1,0])} = 0
end

if opt.PercentOutliers > 0
    xLen = length(x);
    xMean = mean(x);
    xSTD = std(x,'omitmissing');

    xMin = xMean - 3*xSTD;
    xMax = xMean + 3*xSTD;

    nOutliers = ceil(opt.PercentOutliers * xLen / 100);

    iOutliers = randsample(xLen,nOutliers,opt.Replace);
    x(iOutliers) = rand(nOutliers,1)*(xMax-xMin) + xMin;
end
