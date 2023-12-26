function [U,S,V] = HankelSVD(H)
%HankelSVD Compute Singular Value Decomposition
%
%    [U,S,V] = HankelSVD(H) computes the Singular Value Decomposition (SVD)
%    of the matrix H. For very large H (>1e6), the SVD benefits from
%    parallel computing, and is assigned to the GPU.
%
   
%   Copyright 2023 Elise Jonsson

% assign H to GPU if large enough
if numel(H) > 1e6 & canUseGPU
    H = gpuArray(H);
end

% take singular value decomposition
[U,S,V] = svd(H,'econ');

% retrieve GPU arrays
[U,S,V] = gather(U,S,V);

end