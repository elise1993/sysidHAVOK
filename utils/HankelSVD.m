function [U,S,V] = HankelSVD(H)
%HankelSVD Compute Singular Value Decomposition
%
%    [U,S,V] = HankelSVD(H) computes the Singular Value Decomposition (SVD)
%    of the matrix H. For very large H (>1e6), the SVD benefits from
%    parallel computing, and is assigned to the GPU.
%
   
%   Copyright 2023 Elise Jonsson

if numel(H) > 1e7 & canUseGPU
    H = gpuArray(H);
end

[U,S,V] = svd(H,'econ');

[U,S,V] = gather(U,S,V);

end