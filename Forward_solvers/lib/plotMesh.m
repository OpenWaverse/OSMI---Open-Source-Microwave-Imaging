function plotMesh(model)
% PLOTMESH  Display the finite-element mesh of a PDE model.
%
%   plotMesh(model)
%
%   Opens a new figure and draws the triangular FEM mesh stored in the PDE
%   model object using pdemesh. Useful for inspecting mesh density, element
%   size transitions between regions (background, DOI, target, antennas),
%   and overall mesh quality before running the forward solver.
%
%   Input
%   -----
%   model : PDEModel object that already has a mesh generated (i.e.
%           generateMesh has been called on it). Typically obtained from the
%           'model' field of the struct returned by createScenarioMesh.
%
%   Example
%   -------
%   scenario = createScenarioMesh(geom, meshControl);
%   plotMesh(scenario.model);
%
%   See also CREATESCENARIOMESH, PLOTGEOMETRY, PDEMESH

figure;

pdemesh(model);

axis equal;
grid on;

title('FEM Mesh');

end