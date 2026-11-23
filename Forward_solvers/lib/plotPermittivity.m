function ax = plotPermittivity(fields, part, varargin)
% PLOTPERMITTIVITY  Plot the permittivity (or a contrast) stored in a FIELDS struct.
%
%   plotPermittivity(fields)                    Re{eps_r}
%   plotPermittivity(fields, part)              'real' | 'imag' | 'abs' | 'sigma'
%   plotPermittivity(..., 'Reference', ref)     contrast  eps_r - eps_r,ref  (same mesh)
%   plotPermittivity(..., 'CLim', [cmin cmax])  colour limits
%   plotPermittivity(..., 'Limits', [x1 x2 y1 y2])   default: region inside the PML
%   plotPermittivity(..., 'Title', str)         custom title (LaTeX)
%
%   'sigma' shows the equivalent conductivity  sigma = -omega*eps0*Im{eps_r}.
%
%   See also PLOTFIELD, ASSIGNPERMITTIVITY

if nargin < 2 || isempty(part), part = 'real'; end

p = inputParser;
addParameter(p, 'Reference', []);
addParameter(p, 'CLim',      []);
addParameter(p, 'Limits',    []);
addParameter(p, 'Title',     "");
parse(p, varargin{:});
o = p.Results;

epsr = fields.perm;
sym  = '\varepsilon_r';
if ~isempty(o.Reference)
    if numel(o.Reference.perm) ~= numel(epsr)
        error('plotPermittivity:mesh', 'Reference is on a different mesh.');
    end
    epsr = epsr - o.Reference.perm;
    sym  = '\Delta\varepsilon_r';
end

switch lower(part)
    case 'real',  v = real(epsr);  lbl = ['$\mathrm{Re}\{' sym '\}$'];  units = '';
    case 'imag',  v = imag(epsr);  lbl = ['$\mathrm{Im}\{' sym '\}$'];  units = '';
    case 'abs',   v = abs(epsr);   lbl = ['$|' sym '|$'];               units = '';
    case 'sigma'
        v = -2*pi*fields.freq*8.854187817e-12*imag(epsr);
        lbl = '$\sigma$';  if ~isempty(o.Reference), lbl = '$\Delta\sigma$'; end
        units = 'S/m';
    otherwise, error('plotPermittivity:part', 'Unknown part "%s".', part);
end

figure;
ax = gca;
patch(ax, 'Faces', fields.mesh.cells, 'Vertices', fields.mesh.verts, ...
      'FaceVertexCData', v, 'FaceColor', 'flat', 'EdgeColor', 'none');
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
if ~isempty(o.CLim), clim(ax, o.CLim); end

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
    title(ax, sprintf('%s \\quad [%s]', lbl, name));
end

end
