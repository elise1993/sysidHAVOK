function yf = forcingFunction(x,y,opt)

arguments
    x (:,1) {mustBeReal}
    y (:,1) {mustBeReal}
    opt.method {mustBeTextScalar} = 'none'
    opt.func (1,1) = @(b,x) b(1)*x + b(2)
end

switch opt.method
    case 'none'

        mdl = nan;
        yf = @(x) 0;

    case 'linear'

        mdl = fitlm(x,y,'linear');
        yf = @(x) predict(mdl,x);

    case 'overfit'

        breaks =[x;x(end)];
        coefs = [y(1:end-1);0];
        mdl = mkpp(breaks,coefs);
        yf = @(x) ppval(mdl,x);

    case 'Yang-et-al-2022'

        

        %dydt*dt = vrp - vr(t)

    case 'custom-function'

        b0 = rand(2,1);
        mdl = fitnlm(x,y,func,b0);
        yf = @(x) predict(mdl,x);

end