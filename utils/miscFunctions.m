classdef miscFunctions
    %miscFunctions Miscellaneous functions used throughout the code
    %
    %    miscFunctions is a class file containing small utility functions
    %    that are used throughout the code.
    %

    %   Copyright 2023 Elise Jonsson

    methods(Static)

        % test for equal length
        function mustBeEqualLength(a,b)
            if ~isequal(length(a),length(b))
                eid = 'Size:notEqual';
                msg = 'The data matrix (x) is not the same length as the time vector (t)!';
                error(eid,msg)
            end
        end

        % test for monotonicity
        function mustBeMonotonic(a)
            if any(diff(a) < 0)
                eid = 'Monotonic:false';
                msg = 'The time array (a) must consist of monotonically increasing values!';
                error(eid,msg)
            end
        end

        % normalized mean square error
        function NMSE = nmse(xSim,xTarget)

            NMSE = sum((xTarget-xSim).^2)/sum((xTarget-mean(xTarget)).^2);

        end

    end



end