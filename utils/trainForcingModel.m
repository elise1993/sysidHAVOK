function Regressor = trainForcingModel(vrTrain,vrVal,method,opt)
%trainForcingModel Train Machine Learning model [Work in Progress]
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
%       - C++ Optimized Random Forest Regression (RFR-MEX)*
%       - Support Vector Regression (SVR)
%       - Multilayer Perceptron (MLP)
%       - Long Short-Term Memory (LSTM)
%       - Temoral Convolutional Network (TCN) [unfinished]
% 
%       * [by Leo Breiman et al. from the R-source by Andy Liaw et al.
%         http://cran.r-project.org/web/packages/randomForest/index.html
%         Ported to MATLAB by Abhishek Jaiantilal]
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
        "LinearRegression",...
        "Bag",...
        "LSBoost",...
        "RFR", ...
        "RFR-MEX", ...
        "SVR", ...
        "MLP", ...
        "LSTM" ...
        ])} = "RFR-MEX"

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

disp("Training ML forcing model ("+method+") ...")

if not(length(opt.HiddenLayerSizes) == opt.NumLayers)
            error("HiddenLayerSizes must be specified for all layers as a vector.")
end

switch method
    case "LinearRegression"
        
        Regressor = fitlm(vrTrain{1},vrTrain{2});

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

    case "RFR-MEX"

        mkdir("downloaded\RF_Reg_C");
        addpath("downloaded\RF_Reg_C\");
        files = ["regRF_train.m","regRF_predict.m","mexRF_train.mexw64",...
            "mexRF_train.mexw32","mexRF_predict.mexw64",...
            "mexRF_predict.mexw32"];

        for i = 1:length(files)
            if ~exist(files(i),'file')
                disp(files(i)+" not found in current directory, retrieving...")
                url = "https://github.com/tingliu/randomforest-matlab/blob/master/RF_Reg_C/";
                websave("./downloaded/RF_Reg_C/"+files(i),url+files(i)+"?raw=true");
            end
        end

        Regressor = regRF_train(vrTrain{1},vrTrain{2},opt.NumTrees,opt.NumFeaturesToSample);

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