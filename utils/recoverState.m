function x = recoverState(V,U,S,r,method)
%recoverState Converts state from delay coordinates back into measurement
%coordinates
%
%    x = recoverState(V,U,S,r,method) recovers the original state x from
%    the variables V in the delay coordinates U*S with truncation r. To do
%    this, a Hankel matrix H is reconstructed based on V and U*S.
%
%    method='cross-diagonal': To obtain x, cross-diagonal averages of H
%    are taken. While this method is more accurate than simply using the
%    edges of H to reconstruct x, the following implementation does not
%    allow true zeroes in H to occur. However, true zeroes are often
%    rare due to machine precision and, provided that they are few, are
%    unlikely to affect the averaging for large systems.
%
%    method='edges': To obtain x, the edges of H are used. This method
%    may be less accurate than 'cross-diagonal', but is a safer option
%    for systems where the state may reach true zero, or systems with
%    logic state variables.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    V (:,:) {mustBeNumeric}
    U (:,:) {mustBeNumeric}
    S (:,:) {mustBeNumeric}
    r (1,1) {mustBePositive,mustBeGreaterThan(r,1)}
    method {mustBeMember(method,{'edges','cross-diagonal'})} = 'cross-diagonal'
end

H = U(1:r-1,1:r-1)*S(1:r-1,1:r-1)*V';

switch method
    case 'edges'
        x = [H(1,:)'; H(2:end,end)];

    case 'cross-diagonal'
        x = spdiags(H(end:-1:1,:));
        x(x==0) = nan;
        x = mean(x,'omitnan')';
end

x = x(1:length(V));

