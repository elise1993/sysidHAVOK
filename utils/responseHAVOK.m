function [t,v] = responseHAVOK(A,B,t,InitialCondition,ImpulseFunction,opt)
%impulseHAVOK Produces an system response of the HAVOK model
%
%    [t,x] = impulseHAVOK(A,B,t,vr,v0) produces and visualizes the system
%    response of the HAVOK model with coefficient matrices A,B,r over the
%    time span t when the forcing vr is applied with initial conditions v0.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    A (:,:)

    B (:,1)

    t (:,1)

    InitialCondition (:,1) {miscFunctions.mustBeEqualLength(...
        InitialCondition,B)}

    ImpulseFunction (1,1) {mustBeMember(ImpulseFunction,["Initial",...
        "Impulse","Step","Custom"])} = "Initial"

    opt.Forcing (:,1) {miscFunctions.mustBeEqualLength(t,opt.Forcing)}

    opt.C (:,:) {miscFunctions.mustBeEqualSize(opt.C,A)} = eye(length(A))
    
    opt.D (:,:) {miscFunctions.mustBeEqualSize(opt.D,B)} = 0*B
end

% build continous-time state-space model
sys = ss(A,B,opt.C,opt.D);

% impulse response
switch ImpulseFunction
    case "Initial"
        [v,t] = initial(sys,InitialCondition,t);

    case "Impulse"
        [v,t] = impulse(sys,t);

    case "Step"
        [v,t] = step(sys,t);

    case "Custom"
        assert(isfield(opt,"Forcing"),"Must specify forcing function.")
        [v,t] = lsim(sys,opt.Forcing,t,InitialCondition);
end

plot(t,v(:,1))
