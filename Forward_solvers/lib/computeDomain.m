function domain = computeDomain(geom, meshControl, lambda_bg, pml)
% COMPUTEDOMAIN  Size the computational square and the PML from the geometry.
%
%   domain = computeDomain(geom, meshControl, lambda_bg)
%   domain = computeDomain(geom, meshControl, lambda_bg, pml)
%
%   1. Extent: bounding box of everything the user defines (DOI circle,
%      antenna discs on the ring, target), giving the maximum radius
%          a = max(|xmin|, |xmax|, |ymin|, |ymax|).
%   2. Square side:            L = squareFactor * a        (default 4a)
%   3. PML: the outer pmlFraction of the half-size (default 25 %),
%          PML starts at       s = (1 - pmlFraction) * L/2
%          PML thickness       d = pmlFraction * L/2
%      and the clearance between the geometry and the PML is gap = s - a.
%
%            <------------------ L = 4a ------------------>
%           +---------------------------------------------+
%           |  PML (outer 25 % of L/2)                    |
%           |    +-----------------------------------+    |
%           |    |  gap                              |    |
%           |    |    +-------------------------+    |    |
%           |    |    | antennas, DOI, target   |    |    |
%           |    |    +---------- a ------------+    |    |
%           |    +--------------- s ----------------+    |
%           +---------------------------------------------+
%
%   An error is raised if the PML would touch the geometry (gap <= 0), and
%   a warning if the PML is thinner than half a background wavelength
%   (weak absorption); increase squareFactor in both cases.
%
%   Inputs
%   ------
%   geom        : geometry (doiRadius, antennaRing, nAntennas, optional target)
%   meshControl : needs .rAnt (antenna disc radius)
%   lambda_bg   : wavelength in the background medium (m)
%   pml         : (optional) struct, any of
%                   .squareFactor  square side / maximum radius     [4]
%                   .pmlFraction   PML share of the half-size       [0.25]
%                   .R             normal-incidence reflection coeff. [1e-5]
%                   .n             polynomial grading order         [2]
%                   .kappaMax      maximum real stretching          [1]
%
%   Output
%   ------
%   domain.extent     [xmin xmax ymin ymax] of the user geometry (m)
%   domain.radius     a, maximum radius of the geometry (m)
%   domain.pmlStart   s, |x| or |y| where the PML begins (m)
%   domain.halfSize   L/2 (m)
%   domain.squareSize L (m)
%   domain.plotLimits [-s s -s s]: whole region except the PML (default
%                     limits of the field plots)
%   domain.pml        PML parameters (incl. .start, .thickness, .gap)
%
%   See also GENERATE_FIELDS, CREATESCENARIOMESH, FEM2D

if nargin < 4 || isempty(pml), pml = struct(); end
if ~isfield(pml, 'squareFactor'), pml.squareFactor = 4;     end
if ~isfield(pml, 'pmlFraction'),  pml.pmlFraction  = 0.25;  end
if ~isfield(pml, 'R'),            pml.R            = 1e-5;  end
if ~isfield(pml, 'n'),            pml.n            = 2;     end
if ~isfield(pml, 'kappaMax'),     pml.kappaMax     = 1;     end

%% Bounding box of the geometry
r   = geom.doiRadius;
box = [-r r -r r];                                         % DOI

theta = linspace(0, 2*pi, geom.nAntennas+1);  theta(end) = [];
xa = geom.antennaRing*cos(theta);
ya = geom.antennaRing*sin(theta);
ra = meshControl.rAnt;
box = mergeBox(box, [min(xa)-ra, max(xa)+ra, min(ya)-ra, max(ya)+ra]);   % antennas

if isfield(geom, 'targetRadius') && ~isempty(geom.targetRadius) && geom.targetRadius > 0
    c  = geom.targetCenter;  rt = geom.targetRadius;
    box = mergeBox(box, [c(1)-rt, c(1)+rt, c(2)-rt, c(2)+rt]);          % target
end

a = max(abs(box));

%% Square and PML
H = pml.squareFactor * a / 2;                  % half-size
pml.start     = (1 - pml.pmlFraction) * H;
pml.thickness = pml.pmlFraction * H;
pml.gap       = pml.start - a;

if pml.gap <= 0
    error('computeDomain:pml', ...
        ['The PML (from %.3f m) would overlap the geometry (radius %.3f m). ' ...
         'Increase pml.squareFactor (now %g) or reduce pml.pmlFraction.'], ...
        pml.start, a, pml.squareFactor);
end
if pml.thickness < lambda_bg/2
    warning('computeDomain:thinPML', ...
        ['PML thickness %.3f m is below half a background wavelength (%.3f m); ' ...
         'absorption may be poor. Consider a larger pml.squareFactor.'], ...
        pml.thickness, lambda_bg/2);
end

domain.extent     = box;
domain.radius     = a;
domain.pmlStart   = pml.start;
domain.halfSize   = H;
domain.squareSize = 2*H;
domain.plotLimits = pml.start*[-1 1 -1 1];
domain.pml        = pml;

end

% -------------------------------------------------------------------------
function b = mergeBox(b, c)
b = [min(b(1), c(1)), max(b(2), c(2)), min(b(3), c(3)), max(b(4), c(4))];
end
