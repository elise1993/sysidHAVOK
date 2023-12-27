function H = HankelMatrix(x,stackmax)
%HankelMatrix Arrange a Hankel matrix
%
%    H = HankelMatrix(x,stackmax) constructs a Hankel matrix from the
%    sequential input data x with the number of stack-shifted copies
%    specified by stackmax.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    x (:,1)
    stackmax (1,1) {mustBePositive}
end

n = length(x);
ij = (1:n-stackmax) + (0:(stackmax-1))';
H = x(ij);
