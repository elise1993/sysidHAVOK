function plotvr(x,y)

figure;
title('Intermittent Forcing (Training)')
subplot(2,1,1)
plot(x,y,linewidth=1)
ylabel('v_r');
set(gca,'fontsize',20)

subplot(2,1,2)
plot(x,y,linewidth=2)
ylabel('v_r');
xlabel('time (t)');
xlim([91,92]);
set(gca,'fontsize',20)