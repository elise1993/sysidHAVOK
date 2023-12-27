function dxdt = SINDyModel(t,x,Xi,polyDegree)
%SINDyModel Function output for the SINDy model [deprecated]
%
%    dxdt = SINDyModel(t,x,Xi,polyDegree) produces a function for the SINDy
%    model with polynomial coefficients Xi and polynomial degree polyDegree
%    which can be used in e.g., ode45.
%
   
%   Copyright 2023 Elise Jonsson

nVars = size(Xi,2);
ind = 1;

dxdt(:,ind) = Xi(ind,:)';
ind = ind+1;

if polyDegree >= 1
    for i = 1:nVars
        dxdt(:,ind) = Xi(ind,:)'*x(i);
        ind = ind+1;
    end
end

if polyDegree >= 2
    for i = 1:nVars
        for j = i:nVars
            dxdt(:,ind) = Xi(ind,:)'*x(i)*x(j);
            ind = ind+1;
        end
    end
end

if polyDegree >= 3
    for i = 1:nVars
        for j =  i:nVars
            for k = j:nVars
                dxdt(:,ind) = Xi(ind,:)'*x(i)*x(j)*x(k);
                ind = ind+1;
            end
        end
    end
end

dxdt = sum(dxdt,2);

