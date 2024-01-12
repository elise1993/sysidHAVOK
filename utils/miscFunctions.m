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
                msg = 'The arrays, (a) and (b), are not the same length.';
                error(eid,msg)
            end
        end

        % test for monotonicity
        function mustBeMonotonic(x)
            if any(diff(x) < 0)
                eid = 'Monotonic:false';
                msg = 'The array (x) must consist of monotonically increasing values.';
                error(eid,msg)
            end
        end

        % test for equidistant
        function mustBeEquidistant(x)
            tol = 1e-6;
            dx = diff(x);
            if not(all(ismembertol(dx,dx(1),tol)))
                eid = 'Equidistant:false';
                msg = 'The elements of the array (x) are not equidistant.';
                error(eid,msg)
            end
        end

        % normalized mean square error
        function NMSE = nmse(xSim,xTarget)

            NMSE = sum((xTarget-xSim).^2)/sum((xTarget-mean(xTarget)).^2);

        end

    end



end