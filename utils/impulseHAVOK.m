function [t,v] = impulseHAVOK(A,B,t,vr,v0,opt)
%impulseHAVOK Produces an impulse-response of the HAVOK model
%
%    [t,x] = impulseHAVOK(A,B,t,vr,v0) produces and visualizes the impulse
%    response of the HAVOK model with coefficient matrices A,B,r over the
%    time span t when the forcing vr is applied with initial conditions v0.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    A (:,:)
    B (:,1)
    t (:,1)
    vr (:,1) {miscFunctions.mustBeEqualLength(t,vr)}
    v0 (:,1) {miscFunctions.mustBeEqualLength(v0,B)}
    opt.C (:,:) {miscFunctions.mustBeEqualSize(opt.C,A)} = eye(length(A))
    opt.D (:,:) {miscFunctions.mustBeEqualSize(opt.D,B)} = 0*B
end

% build continous-time state-space model
sys = ss(A,B,opt.C,opt.D);

% impulse response
[v,t] = lsim(sys,vr,t,v0);
plot(t,v(:,1))
