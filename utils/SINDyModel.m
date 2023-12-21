function dxdt = SINDyModel(t,x,Xi,polyDegree)

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

end