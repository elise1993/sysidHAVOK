function [RMSE,NMSE,R2,pvalue_R2] = forecastSkill(xTarget,xSimVal)

RMSE = rmse(xSimVal,xTarget);

NMSE = miscFunctions.nmse(xSimVal,xTarget);

[R,pvalue_R2] = corr(xSimVal,xTarget,'type','Pearson');

R2 = R^2;

disp("RMSE: "+RMSE)
disp("NMSE: "+NMSE)
disp("R^2: "+R2+", p-value="+pvalue_R2)