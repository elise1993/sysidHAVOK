function Regressor = trainForcingModel(vrTrain,vrVal,method,opt)
%trainForcingModel Train Machine Learning model [unfinished]
%
%    Regressor = trainForcingModel(vrTrain,vrVal,method,opt) trains a
%    Machine Learning (ML) model, using the columns of vrTrain as
%    predictors for the response variable vrVal.
% 
%    The type of ML method is specified by "method", which can be:
% 
%       - Bootstrap Aggregation (Bag)
%       - Boosting (LSBoost)
%       - Random Forest Regression (RFR)
%       - Support Vector Regression (SVR)
%       - Multilayer Perceptron (MLP)
%       - Long Short-Term Memory (LSTM)
%       - Temoral Convolutional Network (TCN) [unfinished]
% 
%    The model output can be used with the function predictML.m to
%    make predictions. Optional arguments are provided to specify the model
%    properties, such as the number of decision trees (NumTrees), splits
%    (MaxNumSplits), leaf size (MinLeafSize), etc. Other properties can be
%    edited within the function. See MATLAB documentation for more info
%    regarding these properties.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    vrTrain (:,:)

    vrVal (:,:)

    method {mustBeMember(method,[ ...
        "Bag",...
        "LSBoost",...
        "RFR", ...
        "SVR", ...
        "MLP", ...
        "LSTM" ...
        ])} = "RFR"

    opt.MaxNumSplits (1,1) {mustBeInteger,mustBePositive} = 100;

    opt.NumTrees (1,1) {mustBeInteger,mustBePositive} = 20;

    opt.EnsembleMethod {mustBeMember(opt.EnsembleMethod,...
        ["Bag","LSBoost"])} = "Bag"

    opt.MinLeafSize (1,1) {mustBeInteger,mustBePositive} = 5;

    opt.NumFeaturesToSample (1,1) {mustBeInteger,mustBePositive} = ...
        floor(size(vrTrain{1},2)*(1/3))

    opt.KernelFunction (1,1) {mustBeMember(opt.KernelFunction,...
        ["linear","gaussian","rbf","polynomial"])} = "linear"

    opt.NumLayers (1,1) {mustBeInteger,mustBePositive} = 3

    opt.HiddenLayerSizes (1,:) {mustBeInteger,mustBePositive} = [10,10,10]

    opt.ActivationFunction (1,1) {mustBeMember(opt.ActivationFunction,...
        ["relu","tanh","sigmoid"])} = "relu"

    opt.DropoutProbability (1,1) {mustBeLessThan(opt.DropoutProbability,1)} = 0

    opt.LearnRate (1,1) {mustBePositive,mustBeReal} = 1e-2

end

disp("Training ML forcing model...")

if not(length(opt.HiddenLayerSizes) == opt.NumLayers)
            error("HiddenLayerSizes must be specified for all layers as a vector.")
end

switch method
    case {"Bag","LSBoost"}

        % weak learner baseline model
        Learners = templateTree( ...
            'MinLeafSize',opt.MinLeafSize, ...
            'MaxNumSplits',opt.MaxNumSplits ...
            );

        % ensemble model
        Regressor = fitensemble( ...
            vrTrain{1},vrTrain{2}, ...
            method, ...
            opt.NumTrees, ...
            Learners, ...
            'Type','regression', ...
            'NPrint',1 ...
            );

        % Using TreeBagger instead of fitensemble (slightly different)
        % Regressor = TreeBagger( ...
        %     opt.NumTrees, ...
        %     vrTrain{1},vrTrain{2}, ...
        %     'Method','regression', ...
        %     'MinLeafSize',opt.MinLeafSize, ...
        %     'MaxNumSplits',opt.MaxNumSplits, ...
        %     'NumPrint',1 ...
        %     );

    case "RFR"

        Regressor = TreeBagger( ...
            opt.NumTrees, ...
            vrTrain{1},vrTrain{2}, ...
            'Method','regression', ...
            'MinLeafSize',opt.MinLeafSize, ...
            'MaxNumSplits',opt.MaxNumSplits, ...
            'NumPredictorsToSample',opt.NumFeaturesToSample, ...
            'PredictorSelection','curvature', ...
            'InBagFraction',1/opt.NumTrees, ...
            'NumPrint',1 ...
            );

    case "SVR"

        Regressor = fitrsvm( ...
            vrTrain{1},vrTrain{2}, ...
            'KernelFunction',opt.KernelFunction, ...
            'KernelScale','auto', ...
            'NumPrint',1 ...
            );

        disp("Did SVR converge?" + Regressor.ConvergenceInfo.Converged)


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
    %case "SVR"
    otherwise
        %disp("Resubstitution Loss: "+resubLoss(Regressor))
end

end