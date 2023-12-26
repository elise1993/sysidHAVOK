function H = HankelMatrix(x,stackmax)
%HankelMatrix Arrange a Hankel matrix
%
%    H = HankelMatrix(x,stackmax) arranges a Hankel matrix from the
%    sequential input data x with the number of stack-shifted copies
%    defined by stackmax.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    x (:,1)
    stackmax (1,1) {mustBePositive}
end

% construct Hankel matrix
n = length(x);
ij = (1:n-stackmax) + (0:(stackmax-1))';
H = x(ij);
