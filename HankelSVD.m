%Hankel Singular Value Decomposition
   %
   %    [U,S,V,H] = HankelSVD(x,stackmax) constructs a Hankel matrix of the
   %    data x and applies Singular Value Decomposition to obtain the
   %    dominant "modes" in delay coordinates.
   %
   
%   Author(s): Elise Jonsson

function [H,U,S,V] = HankelSVD(x,stackmax)

% construct Hankel matrix
n = length(x);
ij = (1:n-stackmax) + (0:(stackmax-1))';
H = x(ij);

% assign H to GPU if large enough
if numel(ij) > 1e6 | canUseGPU
    H = gpuArray(H);
end

% take singular value decomposition
[U,S,V] = svd(H,'econ');

[H,U,S,V] = gather(H,U,S,V);

end