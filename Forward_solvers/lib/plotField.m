function ax = plotField(fields, tx, quantity, varargin)
% PLOTFIELD  Plot the field radiated by transmitter TX on the mesh.
%
%   plotField(fields, tx)                       |E_z| of transmitter tx
%   plotField(fields, tx, quantity)             'abs' | 'dB' | 'phase' | 'real' | 'imag'
%   plotField(..., 'CLim', [cmin cmax])         colour limits (e.g. [-40 0] for 'dB');
%                                               values outside are saturated
%   plotField(..., 'Reference', ref)            plot E_fields - E_ref (same mesh),
%                                               e.g. scattered = total - incident
%   plotField(..., 'Limits', [x1 x2 y1 y2])     axis limits (m); default: the
%                                               physical region inside the PML
%   plotField(..., 'Title', str)                custom title (LaTeX)
%   plotField(..., 'Overlay', polylines)        cell array of K-by-2 curves to draw
%   plotField(..., 'Parent', ax)                draw into existing axes
%
%   'dB' is 20*log10(|E|/max|E|), so 0 dB is the maximum of the plotted map.
%   The DOI boundary (if fields.geom is present) and the antennas are drawn
%   on top; the active transmitter is marked in red.
%
%   See also FIELD_QUANTITY, FIELDVIEWER, PLOTPERMITTIVITY

if nargin < 3 || isempty(quantity), quantity = 'abs'; end

p = inputParser;
addParameter(p, 'CLim',      []);
addParameter(p, 'Reference', []);
addParameter(p, 'Limits',    []);
addParameter(p, 'Title',     "");
addParameter(p, 'Overlay',   {});
addParameter(p, 'Parent',    []);
parse(p, varargin{:});
o = p.Results;

[values, label, units] = field_quantity(fields, tx, quantity, o.Reference);

if isempty(o.Parent)
    figure;
    ax = gca;
else
    ax = o.Parent;
    cla(ax);
end

patch(ax, 'Faces', fields.mesh.cells, 'Vertices', fields.mesh.verts, ...
      'FaceVertexCData', values, 'FaceColor', 'flat', 'EdgeColor', 'none');
hold(ax, 'on');
drawOverlay(ax, fields, tx, o.Overlay);
hold(ax, 'off');

axis(ax, 'equal');
lim = o.Limits;
if isempty(lim) && isfield(fields, 'domain')
    lim = fields.domain.plotLimits;           % physical region, PML hidden
end
if ~isempty(lim)
    xlim(ax, lim(1:2)); ylim(ax, lim(3:4));
else
    axis(ax, 'tight');
end

if ~isempty(o.CLim)
    if numel(o.CLim) ~= 2 || o.CLim(1) >= o.CLim(2)
        error('plotField:CLim', 'CLim must be [cmin cmax] with cmin < cmax.');
    end
    clim(ax, o.CLim);
else
    clim(ax, 'auto');
end

cb = colorbar(ax);
cb.Label.String = units;
cb.Label.Interpreter = get(groot, 'defaultTextInterpreter');   % follows set_latex_figures
xlabel(ax, '$x$ (m)');
ylabel(ax, '$y$ (m)');

if strlength(string(o.Title)) > 0
    title(ax, o.Title);
else
    name = latex_text(fields.name);
    if ~isempty(o.Reference), name = name + " $-$ " + latex_text(o.Reference.name); end
    title(ax, sprintf('%s, Tx %d \\quad [%s]', label, tx, name));
end

end

% -------------------------------------------------------------------------
function drawOverlay(ax, fields, tx, overlay)
t = linspace(0, 2*pi, 200);
g = struct();
if isfield(fields, 'geom'), g = fields.geom; end
% DOI circle (circular scenarios)
if isfield(g, 'doiRadius')
    r = g.doiRadius;
    plot(ax, r*cos(t), r*sin(t), 'w-', 'LineWidth', 1);
end
% user curves (e.g. tissue boundaries)
for k = 1:numel(overlay)
    plot(ax, overlay{k}(:,1), overlay{k}(:,2), 'k-', 'LineWidth', 0.5);
end
% target outline, dashed (only if the target is present in this simulation)
if isfield(fields, 'includeTarget') && fields.includeTarget && ...
        isfield(g, 'targetRadius') && ~isempty(g.targetRadius) && g.targetRadius > 0
    plot(ax, g.targetCenter(1) + g.targetRadius*cos(t), ...
             g.targetCenter(2) + g.targetRadius*sin(t), 'w--', 'LineWidth', 1.5);
end
% antennas
ant = fields.mesh.verts(fields.mesh.probeNodes, :);
plot(ax, ant(:,1), ant(:,2), 'wo', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
plot(ax, ant(tx,1), ant(tx,2), 'wo', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
end
