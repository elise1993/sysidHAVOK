%Data Partition
   %
   %    [xtrain,xval,xtest] = partitionData(x,p1,p2,p3) partitions a
   %    sequential data set x into training, validation, and testing data
   %    sets xtrain,xval,xtest with relative proportions p1, p2, and
   %    p3.
   %
   
%   Author(s): Elise Jonsson

function [xtrain,xval,xtest] = partitionData(x,p1,p2,p3)

arguments
    x (:,1)
    p1 (1,1) {mustBeNumeric,mustBeLessThanOrEqual(p1,1)} = .6
    p2 (1,1) {mustBeNumeric,mustBeLessThanOrEqual(p2,1)} = .2
    p3 (1,1) {mustBeNumeric,mustBeLessThanOrEqual(p3,1)} = .2
end

n = length(x);
iTrain = floor(1 : n*p1);
iVal = floor((n*p1 + 1) : n*(p1+p2));
iTest = floor(n*(p1+p2)+1) : n;

xtrain = x(iTrain);
xval = x(iVal);
xtest = x(iTest);

end
