function plotMesh(model)

figure;

pdemesh(model);

axis equal;
grid on;

title('FEM Mesh');

end