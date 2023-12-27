function Regressor = trainForcingModel(vrTrain,vrVal,method,opt)
%trainForcingModel Train Machine Learning model [unfinished]
%
%    Regressor = trainForcingModel(vrTrain,vrVal,method,opt) trains a
%    Machine Learning (ML) model, using the columns of vrTrain as
%    predictors for the response variable vrVal.
% 
%    The type of ML method is specified by "method", and can be a
%    TreeBagger, BaggedEnsemble, Multilayer Perceptron (MLP), etc. While
%    TreeBagger can only produce bagged regression trees, BaggedEnsemble
%    also allows for boosted trees by setting the EnsembleMethod option.
%    Both are included here since they provide different functionality that 
%    the user may wish to edit, see 
%    https://se.mathworks.com/help/stats/ensemble-algorithms.html#bsxabwd
%    for a comparison of TreeBagger and BaggedEnsemble.
% 
%    The model output can be used with the MATLAB function predict.m to
%    make predictions. Optional arguments are provided to specify the
%    number of regression trees (NumTrees), splits (MaxNumSplits), and leaf
%    size (MinLeafSize), etc. Other properties can be edited within the
%    function.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    vrTrain (:,:)

    vrVal (:,:)

    method {mustBeMember(method,[ ...
        "TreeBagger",...
        "BaggedEnsemble",...
        "MLP", ...
        "LSTM" ...
        ])} = "BaggedEnsemble"

    opt.MaxNumSplits (1,1) {mustBeInteger,mustBePositive} = 100;

    opt.NumTrees (1,1) {mustBeInteger,mustBePositive} = 20;

    opt.EnsembleMethod {mustBeMember(opt.EnsembleMethod,...
        ["Bag","LSBoost"])} = "Bag"

    opt.MinLeafSize (1,1) {mustBeInteger,mustBePositive} = 5;

    opt.NumLayers (1,1) {mustBeInteger,mustBePositive} = 3

    opt.HiddenLayerSizes (1,:) {mustBeInteger,mustBePositive} = [10,10,10]

    opt.ActivationFunction (1,1) {mustBeMember(opt.ActivationFunction,...
        ["relu","tanh","sigmoid"])} = "relu"

    opt.DropoutProbability (1,1) {mustBeLessThan(opt.DropoutProbability,1)} = 0

    opt.LearnRate (1,1) {mustBePositive,mustBeReal} = 1e-2

end

if not(length(opt.HiddenLayerSizes) == opt.NumLayers)
            error("HiddenLayerSizes must be specified for all layers as a vector.")
end

switch method
    case "TreeBagger"

        Regressor = TreeBagger( ...
            opt.NumTrees, ...
            vrTrain{1},vrTrain{2}, ...
            'Method','regression', ...
            'MinLeafSize',opt.MinLeafSize, ...
            'MaxNumSplits',opt.MaxNumSplits ...
            );

    case "BaggedEnsemble"

        Learners = templateTree( ...
            'MinLeafSize',opt.MinLeafSize, ...
            'MaxNumSplits',opt.MaxNumSplits ...
            );

        Regressor = fitensemble( ...
            vrTrain{1},vrTrain{2}, ...
            opt.EnsembleMethod, ...
            opt.NumTrees, ...
            Learners, ...
            'Type','regression' ...
            );


    case "MLP"
        
        inputSize = size(vrTrain{1},2);

        switch opt.ActivationFunction
            case "relu"
                ActivationFunction = reluLayer;
            case "tanh"
                ActivationFunction = tanhLayer;
            case "sigmoid"
                ActivationFunction = sigmoidLayer;
        end

        layers = sequenceInputLayer(inputSize,'Normalization','none');

        for i = 1:opt.NumLayers
            layers = [
                layers
                fullyConnectedLayer(opt.HiddenLayerSizes(i))
                dropoutLayer(opt.DropoutProbability)
                ActivationFunction
                ];
        end

        layers = [
            layers
            fullyConnectedLayer(1)
            regressionLayer
            ];

    case "LSTM"

        inputSize = size(vrTrain{1},2);

        layers = sequenceInputLayer(inputSize,'Normalization','none');

        for i = 1:opt.NumLayers
            layers = [
                layers
                lstmLayer(opt.HiddenLayerSizes(i),'BiasInitializer','narrow-normal')
                dropoutLayer(opt.DropoutProbability)
                ];
        end

        layers = [
            layers
            fullyConnectedLayer(1)
            regressionLayer
            ];

    case "TCN"
        % temporal convolutional network (WIP)

end

switch method
    case {"MLP","LSTM"}

        options = trainingOptions('adam', ...
            'Plots','none', ...
            'Verbose',true, ...
            'OutputNetwork','best-validation-loss', ...
            'Shuffle','every-epoch', ...
            'MaxEpochs',200, ...
            'InitialLearnRate',opt.LearnRate, ...
            'LearnRateDropFactor',1, ...
            'LearnRateSchedule','piecewise', ...
            'GradientThreshold',1, ...
            'ValidationData',{vrVal{1}',vrVal{2}'}, ...
            'ValidationFrequency',1e2 ...
            );

        [Regressor,info] = trainNetwork(vrTrain{1}',vrTrain{2}',layers,options);

        disp("Validation RMSE: "+info.FinalValidationRMSE)
    otherwise
        % disp("Resubstitution Loss: "+resubLoss(Regressor))
end

end