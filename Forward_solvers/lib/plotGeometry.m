function plotGeometry(model)
% PLOTGEOMETRY  Visualise the PDE model geometry with face and edge labels.
%
%   plotGeometry(model)
%
%   Opens a new figure and calls pdegplot to render the 2-D geometry stored
%   in the PDE model object. Face (region) labels and edge labels are both
%   shown, which is useful for verifying that regions and boundaries were
%   built correctly before meshing.
%
%   Input
%   -----
%   model : PDEModel object created by createpde() and populated with
%           geometry via geometryFromEdges(). Typically obtained from the
%           'model' field of the struct returned by createScenarioMesh.
%
%   Example
%   -------
%   scenario = createScenarioMesh(geom, meshControl);
%   plotGeometry(scenario.model);
%
%   See also CREATESCENARIOMESH, PLOTMESH, PDEGPLOT

figure;
pdegplot(model,...
    'FaceLabels','on',...
    'EdgeLabels','on');

axis equal;
grid on;

title('Geometry and Face Labels');

end