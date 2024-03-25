function plotImpulse(t,x,y)

figure; hold on
plot(t,x)
plot(t,y,'--')
title('Impulse Response of HAVOK Model')
set(gca,'fontsize',20)
legend('True','Predicted')
