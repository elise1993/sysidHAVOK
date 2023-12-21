%% HAVOK impulse response

% build continous-time state-space model

sys = ss(A,B,eye(r-1),0*B);

% impulse response
tspan = t(1:end-stackmax);
dt = t(2)-t(1);
[y,t] = lsim(sys,V(L,r),tspan,V(1,1:r-1));
plot(t,y(:,1))
