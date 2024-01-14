function plotvr(x,y,zoomCoords)

figure;
title('Intermittent Forcing (Training)')
subplot(2,1,1)
plot(x,y,linewidth=1)
ylabel('v_r');
xlim(zoomCoords([1,3]))
set(gca,'fontsize',20)

subplot(2,1,2)
plot(x,y,linewidth=2)
ylabel('v_r');
xlabel('time (t)');
xlim(zoomCoords([2,4]));
set(gca,'fontsize',20)