function L = cholinc(A,droptol)
% TVRegDiff uses the cholinc function, which has been deprecated as of
% MATLAB2014, replace with ichol:

opt.droptol = droptol;

L = ichol(A,opt);