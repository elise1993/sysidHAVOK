function H = HankelMatrix(x,stackmax)

arguments
    x (:,1)
    stackmax (1,1) {mustBePositive}
end

% construct Hankel matrix
n = length(x);
ij = (1:n-stackmax) + (0:(stackmax-1))';
H = x(ij);

end