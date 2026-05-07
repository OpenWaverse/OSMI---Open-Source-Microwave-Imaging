function plotGeometry(model)

figure;
pdegplot(model,...
    'FaceLabels','on',...
    'EdgeLabels','on');

axis equal;
grid on;

title('Geometry and Face Labels');

end