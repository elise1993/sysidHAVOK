function h = plotAttractor(t,V,Vsim,multiStepSize)
%plotAttractor Plot attractor
%
%    h = plotAttractor(t,V,Vsim) plots the "shadowed" attractor in the
%    dominant two or three delay coordinates, where V is the true attractor
%    in these coordinates and Vsim is the simulated attractor.
%
   
%   Copyright 2023 Elise Jonsson

arguments
    t (:,1) {miscFunctions.mustBeMonotonic(t)}
    V (:,:) {miscFunctions.mustBeEqualLength(t,V)}
    Vsim (:,:) {miscFunctions.mustBeEqualLength(t,Vsim)}
    multiStepSize (1,1) {mustBeReal,mustBePositive}
end

% remove lines between reset points
for i=1:multiStepSize:length(Vsim)
    Vsim(:,i:i+4) = nan;
end

% truncate to first three dimensions
if size(V,1) == 2
    maxDim = 2;
else
    maxDim = 3;
end
V = V(1:maxDim,:);
Vsim = Vsim(1:maxDim,:);
v = [V,Vsim];

% axis limits
xyzLimits = [
    nanmin(v(1,:))-.5*nanstd(v(1,:)),nanmax(v(1,:))+.5*nanstd(v(1,:)),...
    nanmin(v(2,:))-.5*nanstd(v(2,:)),nanmax(v(2,:))+.5*nanstd(v(2,:)),...
    nanmin(v(3,:))-.5*nanstd(v(3,:)),nanmax(v(3,:))+.5*nanstd(v(3,:))...
    ];

% plot
h = figure; hold on

xlabel('v_{1}(t)')
ylabel('v_{2}(t)')
xlim([xyzLimits(1),xyzLimits(2)])
ylim([xyzLimits(3),xyzLimits(4)])

if maxDim == 2
    plot(V(1,:),V(2,:),linewidth=2,color="#0072BD")
    plot(Vsim(1,:),Vsim(2,:),':',linewidth=2,color="#D95319")
elseif maxDim == 3
    plot3(V(1,:),V(2,:),V(3,:),linewidth=2,color="#0072BD")
    plot3(Vsim(1,:),Vsim(2,:),Vsim(3,:),':',linewidth=2,color="#D95319")
    view(3)
    zlabel('v_{3}(t)')
    zlim([xyzLimits(5),xyzLimits(6)])
end

title(["Shadowed Attractor in the","Dominant Delay Coordinates"]);
set(gca,'fontsize',20)
leg = legend('True','Predicted');
leg.Orientation = "horizontal";
leg.Position = [.74,0,.1,.05];
% set(gcf,'color','w')

end