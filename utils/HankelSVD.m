%Hankel Singular Value Decomposition
   %
   %    [U,S,V,H] = HankelSVD(x,stackmax) constructs a Hankel matrix of the
   %    data x and applies Singular Value Decomposition to obtain the
   %    dominant "modes" in delay coordinates.
   %
   
%   Author(s): Elise Jonsson

function [U,S,V] = HankelSVD(H)

% assign H to GPU if large enough
if numel(H) > 1e6 & canUseGPU
    H = gpuArray(H);
end

% take singular value decomposition
[U,S,V] = svd(H,'econ');

% retrieve GPU arrays
[U,S,V] = gather(U,S,V);

end