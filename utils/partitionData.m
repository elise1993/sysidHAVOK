function [xtrain,xval,xtest] = partitionData(x,p1,p2,opt)
%partitionData Function that partitions data
%
%    [xtrain,xval,xtest] = partitionData(x,p1,p2,opt) partitions a
%    sequential data set x into training, validation, and optional
%    testing data sets xtrain, xval, xtest with relative proportions p1,
%    p2, and p3, where p3 = 1 - (p1 + p2).
%

%   Copyright 2023 Elise Jonsson

arguments
    x (:,1)
    p1 (1,1) {mustBeNumeric,mustBeLessThanOrEqual(p1,1)} = .6
    p2 (1,1) {mustBeNumeric,mustBeLessThanOrEqual(p2,1)} = .4
    opt.testData (1,1) {mustBeMember(opt.testData,[1,0])} = false
end

n = length(x);
iTrain = floor(1 : n*p1);
iVal = floor((n*p1 + 1) : n*(p1+p2));

xtrain = x(iTrain);
xval = x(iVal);

if opt.testData == true
    iTest = floor(n*(p1+p2)+1) : n;
    xtest = x(iTest);
end

