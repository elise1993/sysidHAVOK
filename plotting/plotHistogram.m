function h = plotHistogram(x)

h = figure;
histogram(x, ...
    'NumBins',100, ...
    'Normalization','percentage', ...
    'LineWidth',2, ...
    'FaceColor',"#D95319", ...
    'EdgeColor','k')

xrange = mean(x)+3*[-std(x),std(x)];
xlim(xrange);

axis square
set(gca,'fontsize',20,'linewidth',2)
xlabel('v_{r}')
ylabel('Frequency (%)')

end