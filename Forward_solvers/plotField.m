function plotField(mesh, fieldData, plotTitle)

p = mesh.Nodes;
t = mesh.Elements';

figure;
hold on;

trisurf(...
    t,...
    p(1,:),...
    p(2,:),...
    zeros(size(p(1,:))),...
    fieldData,...
    'EdgeColor','none');

view(2);
axis equal;
colorbar;

title(plotTitle);

end