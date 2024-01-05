function [t,x] = generateData(system,opt)
%generateData Generate data from the specified system of equations
%
%    dxdt = generateData(system,opt) simulates the specified system
%    for the specified window of time t with its parameters values
%    specified by beta and initial conditions x0. If t, beta or x0 are
%    unspecified, default values are used. The system of equations is
%    solved using the Runge-Kutta 4,5 Scheme (ode45).
%
   
%   Copyright 2023 Elise Jonsson

arguments
    system (1,1) {mustBeMember(system,[ ...
        "Lorenz", ...
        "Rossler", ...
        "VanderPol", ...
        "Duffing", ...
        "DoublePendulum", ...
        "MackeyGlass" ...
        ])}

    opt.t (:,1) {mustBeReal,...
        miscFunctions.mustBeMonotonic(opt.t)}

    opt.x0 (:,:)

    opt.beta (:,:)
end

if ~isfield(opt,"x0")
    switch system
        case "Lorenz"
            opt.x0 = [-8, 8, 27]';
        case "Rossler"
            opt.x0 = [1,1,1]';
        case {"VanderPol","Duffing"}
            opt.x0 = [1,1]';
        case "DoublePendulum"
            opt.x0 = [1.6,0,2.2,0];
        case "MackeyGlass"
            opt.x0 = 1;
    end
end

if ~isfield(opt,"t")
    switch system
        case {"Lorenz","Rossler","VanderPol","Duffing","DoublePendulum"}
            opt.t = 0.01:0.01:200;
        case "MackeyGlass"
            opt.t = 0:0.1:500;
        case "MagneticField"
    end
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

        MaxStep = opt.t(2) - opt.t(1);
        tauLags = 17;
        history = 0.8;

        tolerances = ddeset( ...
            'MaxStep',MaxStep ...
            );

        solution = dde23( ...
            @(t,x,xtau) MackeyGlass(t,x,xtau), ...
            tauLags, ...
            history, ...
            opt.t, ...
            tolerances ...
            );

        t = solution.x;
        x = (solution.y)';

    otherwise

        tolerances = odeset( ...
            'RelTol',1e-12, ...
            'AbsTol',1e-12*ones(size(opt.x0)));

        [t,x] = ode45( ...
            modelFunc, ...
            opt.t, ...
            opt.x0, ...
            tolerances ...
            );

end


