function dxdt = DoublePendulum(t,x,beta)
%DoublePendulum Model of the double pendulum system
%
%    dxdt = DoublePendulum(t,x,beta) is a function variable for the double
%    pendulum system of equations for the set of parameters specified by
%    beta. If the beta parameters are unspecified, the default values for
%    chaotic conditions (l1=l2=m1=m2=1, g=10) are used.
%

%   Copyright 2023 Elise Jonsson

if nargin < 3
    % default parameter values (chaotic conditions)
    beta = [1,1,1,1,10]';
end

l1 = beta(1);
l2 = beta(2);
m1 = beta(3);
m2 = beta(4);
g = beta(5);

a = (m1+m2)*l1;
b = m2*l2*cos(x(1)-x(3));
c = m2*l1*cos(x(1)-x(3));
d = m2*l2;
e = -m2*l2*x(4).^2 * sin(x(1)-x(3)) - g*(m1+m2)*sin(x(1));
f = m2*l1*x(2).^2 * sin(x(1)-x(3)) - m2*g*sin(x(3));

dxdt = [
    
    x(2)

    (e*d - b*f)/(a*d - c*b)

    x(4)

    (a*f - c*e)/(a*d - c*b)
    
    ];
