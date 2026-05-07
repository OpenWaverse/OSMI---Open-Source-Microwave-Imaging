function plotPermittivity(mesh, data, plotTitle)
% PLOTPERMITTIVITY  Plot a scalar permittivity distribution on the FEM mesh.
%
%   plotPermittivity(mesh, data, plotTitle)
%
%   Renders a colour map of a node-wise scalar quantity (e.g. real part of
%   complex permittivity) over the triangular mesh using trisurf viewed from
%   above. The colour axis is linked to a colorbar so magnitudes can be read
%   directly from the plot.
%
%   Inputs
%   ------
%   mesh       : Mesh object (e.g. scenario.mesh). Must contain the fields
%                  mesh.Nodes    — 2-by-N matrix of (x, y) coordinates.
%                  mesh.Elements — 3-by-nElem matrix of node connectivity
%                                  (linear triangular elements).
%
%   data       : 1-by-N (or N-by-1) vector of scalar values, one per mesh
%                node, to be colour-mapped. Typically perm.real or perm.imag
%                as returned by assignPermittivity.
%
%   plotTitle  : Character string used as the figure title (e.g.
%                'Real Permittivity').
%
%   Example
%   -------
%   perm = assignPermittivity(scenario.centroids, geom, materials);
%   plotPermittivity(scenario.mesh, perm.real, 'Real Permittivity');
%
%   See also ASSIGNPERMITTIVITY, PLOTFIELD, PLOTMESH

p = mesh.Nodes;
t = mesh.Elements';

figure;
hold on;

trisurf(...
    t,...
    p(1,:),...
    p(2,:),...
    zeros(size(p(1,:))),...
    data,...
    'EdgeColor','none');

view(2);
axis equal;
colorbar;

title(plotTitle);

end