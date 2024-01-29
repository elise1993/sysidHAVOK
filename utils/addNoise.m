function x = addNoise(x,opt)

arguments
    x (:,1)

    opt.Distribution {mustBeMember(opt.Distribution,["Gaussian",...
        "Uniform","Gamma"])} = "Gaussian"

    opt.DegreeOfNoise (1,1) {mustBeReal,...
        mustBeGreaterThanOrEqual(opt.DegreeOfNoise,0)} = 0
end

switch opt.Distribution
    case "Gaussian"
        x = x + opt.DegreeOfNoise*std(x,'omitmissing')*randn(size(x));
    case "Uniform"
        x = x + opt.DegreeOfNoise*std(x,'omitmissing')*rand(size(x));
    case "Gamma"
        x = x + opt.DegreeOfNoise*std(x,'omitmissing')*randg(size(x));
end