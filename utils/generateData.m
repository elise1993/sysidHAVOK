function [t,x] = generateData(system,opt)
%generateData Generate data from the specified system of equations
%
%    dxdt = generateData(system,opt) simulates the specified system
%    for the specified window of time t with its parameters values
%    specified by beta and initial conditions x0. If t, beta or x0 are
%    unspecified, default values are used. Ordinary- and Delay Differential
%    equations (ODEs and DDEs) are solved using the Runge-Kutta (RK) 4,5
%    Scheme (ode45) and RK2,3 schemes (dde23) whereas Stochastic
%    Differential Equations (SDEs) are solved with methods described in
%    "simulate.m" depending on SDE class.
% 
%       - Lorenz system (ODE)
%       - Rossler system (ODE)
%       - Van der Pol system (ODE)
%       - Duffing oscillator (ODE)
%       - Double pendulum (ODE)
%       - Mackey Glass system (DDE)
%       - Earth magnetic field reversal (SDE) [generated based on Molina-
%                                                   Cardín et. al. (2021)]
%
   
%   Copyright 2023 Elise Jonsson

arguments
    system (1,1) {mustBeMember(system,[ ...
        "Lorenz", ...
        "Rossler", ...
        "VanderPol", ...
        "Duffing", ...
        "DoublePendulum", ...
        "MackeyGlass", ...
        "MagneticFieldReversal" ...
        ])}

    opt.Tolerance (1,1) {mustBeReal,mustBePositive} = 1e-9;

    opt.tspan (1,2) {mustBeReal,miscFunctions.mustBeMonotonic(opt.tspan)}

    opt.dt (1,1) {mustBeReal,mustBePositive}

    opt.x0 (:,:)

    opt.beta (:,:)
end

disp('Generating/importing data...')

if ~isfield(opt,"x0")
    switch system
        case "Lorenz"
            opt.x0 = [-8, 8, 27]';
        case "Rossler"
            opt.x0 = [1,1,1]';
        case {"VanderPol","Duffing"}
            opt.x0 = [1,1]';
        case "DoublePendulum"
            opt.x0 = [pi/2,-0.01,pi/2,-0.005];
        case "MackeyGlass"
            opt.x0 = 1;
        case "MagneticFieldReversal"
            opt.x0 = 0.1;
    end
end

if ~isfield(opt,"dt")
    switch system
        case {"Lorenz","VanderPol","Rossler","Duffing","DoublePendulum"}
            opt.dt = 0.01;
        case {"MackeyGlass","MagneticFieldReversal"}
            opt.dt = 1;
    end
end

if ~isfield(opt,"tspan")
    switch system
        case {"Lorenz","VanderPol","Duffing","DoublePendulum","Rossler"}
            t = 0:opt.dt:200;
        case "MackeyGlass"
            t = 0:opt.dt:2000;
        case "MagneticFieldReversal"
            t = 0:opt.dt:1e4;
    end
else
    t = tspan(1):opt.dt:tspan(2);
end

if ~isfield(opt,"beta")
    modelFunc = @(t,x) eval(system+"(t,x)");

    if system == "MackeyGlass"
        modelFunc = @(t,x,xtau) eval(system+"(t,x,xtau)");
    end
else
    modelFunc = @(t,x) eval(system+"(t,x),opt.beta");

    if system == "MackeyGlass"
        modelFunc = @(t,x,xtau) eval(system+"(t,x,xtau,opt.beta)");
    end
end


switch system
    case "MackeyGlass"

        MaxStep = t(2) - t(1);
        tauLags = 17;
        history = 0.8;

        tolerances = ddeset( ...
            'MaxStep',MaxStep, ...
            'RelTol',opt.Tolerance, ...
            'AbsTol',opt.Tolerance*ones(size(opt.x0)) ...
            );

        solution = dde23( ...
            @(t,x,xtau) MackeyGlass(t,x,xtau), ...
            tauLags, ...
            history, ...
            t, ...
            tolerances ...
            );

        x = deval(solution,t)';

    case "MagneticFieldReversal"

        load("data\MagneticFieldReversal.mat");
        x = double(x);

        % n = length(t);
        % tmax = t(end);
        % dt = ceil(tmax/n)*1e-3;
        % nPeriods = 1e-1*tmax/dt;
        % 
        % [F,G] = EarthMagneticField();
        % 
        % modelFunc = sde( ...
        %     F,G, ...
        %     "StartState",opt.x0, ...
        %     "StartTime",t(1) ...
        %     );
        % 
        % rng(1,'twister')
        % 
        % [X,t] = simulate( ...
        %     modelFunc, ...
        %     nPeriods, ...
        %     "DeltaTime",dt, ...
        %     "NTrials",1 ...
        %     );
        % 
        % % convert to ADM
        % xreal = real(X(:,1,1));
        % ximag = imag(X(:,1,1));
        % 
        % x = w.*xreal + (1-w).*ximag;

        % x = mean(X,3);
        % figure; hold on
        % plot(real(x))
        % plot(t,squeeze(abs(X)))

    otherwise

        tolerances = odeset( ...
            'RelTol',opt.Tolerance, ...
            'AbsTol',opt.Tolerance*ones(size(opt.x0)) ...
            );

        [t,x] = ode45( ...
            modelFunc, ...
            t, ...
            opt.x0, ...
            tolerances ...
            );

end


