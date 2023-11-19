%Hankel Singular Value Decomposition
   %
   %    [U,S,V,H] = HankelSVD(x,stackmax) constructs a Hankel matrix of the
   %    data x and applies Singular Value Decomposition to obtain the
   %    dominant "modes" in delay coordinates.
   %
   
%   Author(s): Elise Jonsson

function [H,U,S,V] = HankelSVD(x,stackmax)

n = length(x);
ij = (1:n-stackmax) + (0:(stackmax-1))';
H = x(ij);

[U,S,V] = svd(H,'econ');

end