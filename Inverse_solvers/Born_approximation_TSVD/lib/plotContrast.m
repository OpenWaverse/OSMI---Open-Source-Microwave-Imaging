function plotContrast(verts, cells, values, plotTitle, cbLabel, cmap, cLim)
% PLOTCONTRAST  Cell-wise patch plot of an image on a triangular mesh.
%
%   plotContrast(verts, cells, values, plotTitle)
%   plotContrast(verts, cells, values, plotTitle, cbLabel)
%   plotContrast(verts, cells, values, plotTitle, cbLabel, cmap)
%   plotContrast(verts, cells, values, plotTitle, cbLabel, cmap, cLim)
%
%   verts     : N-by-2 (or N-by-3) node coordinates (only x, y are used).
%   cells     : Nc-by-3 triangle connectivity (e.g. the DOI cells only).
%   values    : Nc-by-1 real values, one per triangle.
%   plotTitle : title (LaTeX).
%   cbLabel   : colour-bar label (LaTeX)                [''].
%   cmap      : colormap name or matrix                 [parula].
%   cLim      : colour limits [cmin cmax]               [] (auto).

if nargin < 5, cbLabel = ''; end
if nargin < 6 || isempty(cmap), cmap = 'parula'; end
if nargin < 7, cLim = []; end

figure;
patch('Faces', cells, 'Vertices', verts(:,1:2), ...
      'FaceVertexCData', values(:), ...
      'FaceColor', 'flat', 'EdgeColor', 'none');
axis equal tight;
colormap(gca, cmap);
if ~isempty(cLim), clim(cLim); end
cb = colorbar;
cb.Label.String = cbLabel;
cb.Label.Interpreter = get(groot, 'defaultTextInterpreter');   % follows set_latex_figures
title(plotTitle);
xlabel('$x$ (m)');
ylabel('$y$ (m)');

end
