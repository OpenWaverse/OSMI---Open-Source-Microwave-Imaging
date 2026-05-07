function plotField(mesh, fieldData, plotTitle)
% PLOTFIELD  Plot a scalar field (e.g. electric field) on the FEM mesh.
%
%   plotField(mesh, fieldData, plotTitle)
%
%   Renders a colour map of a node-wise scalar field over the triangular
%   mesh using trisurf viewed from above. Intended for visualising FEM
%   solution quantities such as the magnitude or phase of the electric field,
%   incident field, or scattered field at each node.
%
%   Inputs
%   ------
%   mesh       : Mesh object (e.g. scenario.mesh). Must contain the fields
%                  mesh.Nodes    — 2-by-N matrix of (x, y) node coordinates.
%                  mesh.Elements — 3-by-nElem matrix of node connectivity
%                                  (linear triangular elements).
%
%   fieldData  : 1-by-N (or N-by-1) real-valued vector, one value per mesh
%                node. If the field is complex, pass abs(fieldData) or
%                angle(fieldData) depending on what you want to visualise.
%
%   plotTitle  : Character string used as the figure title (e.g.
%                '|E| – Incident Field').
%
%   Example
%   -------
%   u = solvepde(model);
%   plotField(scenario.mesh, abs(u.NodalSolution), '|E| total field');
%
%   See also PLOTPERMITTIVITY, PLOTMESH, FINDPROBENODES

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