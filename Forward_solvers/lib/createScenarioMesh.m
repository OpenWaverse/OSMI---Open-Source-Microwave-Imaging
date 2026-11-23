function scenario = createScenarioMesh(geom, meshControl, domain)
% CREATESCENARIOMESH  Build the PDE geometry and FEM mesh for a microwave
%                     imaging scenario.
%
%   scenario = createScenarioMesh(geom, meshControl)
%   scenario = createScenarioMesh(geom, meshControl, domain)
%
%   The side of the outer square is domain.squareSize (see COMPUTEDOMAIN,
%   called by GENERATE_FIELDS) or, if no domain is given, geom.squareSize.
%
%   Constructs a 2-D multi-region geometry composed of a square outer
%   boundary, a circular domain of interest (DOI), a circular target
%   inclusion, and a set of small circular antenna discs arranged on a ring.
%   The geometry is described symbolically via decsg, converted into a PDE
%   model, and then meshed with region-specific element sizes. Element
%   centroids and antenna positions are computed and returned alongside the
%   model and mesh.
%
%   Inputs
%   ------
%   geom        : Struct with scenario geometry parameters:
%                   geom.squareSize   — side of the square (m); only used
%                                       when no DOMAIN is given.
%                   geom.doiRadius    — radius of the DOI circle (m).
%                   geom.targetCenter — (optional) 1-by-2 [x, y] centre of
%                                       the circular target (m).
%                   geom.targetRadius — (optional) target radius (m). Omit
%                                       (or 0) for a scenario without target.
%                   geom.nAntennas    — number of antennas, evenly spaced on
%                                       a circle of radius antennaRing.
%                   geom.antennaRing  — radius of the antenna ring (m).
%
%   meshControl : Struct with mesh size parameters:
%                   meshControl.rAnt    — radius of each antenna disc (m).
%                   meshControl.hDOI    — target element size inside DOI.
%                   meshControl.hBG     — target element size in background.
%                   meshControl.hTarget — element size inside the target
%                                         (only used if there is a target).
%                   meshControl.hAnt    — target element size at antennas.
%
%   Output
%   ------
%   scenario    : Struct with fields:
%                   scenario.model            — PDEModel object with geometry
%                                               and linear triangular mesh.
%                   scenario.mesh             — FEMesh object (mesh.Nodes,
%                                               mesh.Elements, etc.).
%                   scenario.centroids        — nElem-by-2 matrix of element
%                                               centroid (x, y) coordinates.
%                   scenario.cellsDOI         — indices of elements whose
%                                               centroid lies inside the DOI.
%                   scenario.antennaPositions — nAnt-by-2 matrix of antenna
%                                               (x, y) positions on the ring.
%                   scenario.faces            — face IDs of each region
%                                               (.doi, .bg, .target, .antennas),
%                                               detected from decsg's table.
%
%   Geometry layout (all coordinates centred at origin)
%   ---------------------------------------------------
%   SQ  — outer square boundary.
%   OBJ — circular DOI region.
%   TGT — circular target inclusion inside OBJ.
%   A01..Akk — small circular antenna discs on the ring.
%
%   The set-formula passed to decsg is:
%       SQ + A01 + ... + Akk + OBJ [+ TGT]
%   so each sub-region becomes a separate face in the PDE model, allowing
%   independent mesh sizing and material assignment per region.
%
%   Example
%   -------
%   geom.squareSize   = 0.20;
%   geom.doiRadius    = 0.07;
%   geom.targetCenter = [0.02, 0.01];
%   geom.targetRadius = 0.015;
%   geom.nAntennas    = 16;
%   geom.antennaRing  = 0.08;
%
%   meshControl.rAnt    = 0.003;
%   meshControl.hDOI    = 0.003;
%   meshControl.hBG     = 0.008;
%   meshControl.hTarget = 0.002;
%   meshControl.hAnt    = 0.001;
%
%   scenario = createScenarioMesh(geom, meshControl);
%   plotMesh(scenario.model);
%
%   See also ASSIGNPERMITTIVITY, FINDPROBENODES, PLOTGEOMETRY, PLOTMESH

model = createpde();

hasTarget = isfield(geom, 'targetRadius') && ~isempty(geom.targetRadius) ...
            && geom.targetRadius > 0;

%% Shapes (decsg geometry description matrix columns)
if nargin >= 3 && ~isempty(domain)
    L = domain.squareSize;
else
    L = geom.squareSize;
end
SQ = [3; 4; -L/2; L/2; L/2; -L/2; -L/2; -L/2; L/2; L/2];   % outer square
DOI = [1; 0; 0; geom.doiRadius];                            % DOI circle

theta = linspace(0, 2*pi, geom.nAntennas+1);
theta(end) = [];
xant = geom.antennaRing*cos(theta);
yant = geom.antennaRing*sin(theta);

geomList = {SQ, DOI};
names    = {'SQ', 'OBJ'};
if hasTarget
    geomList{end+1} = [1; geom.targetCenter(1); geom.targetCenter(2); geom.targetRadius];
    names{end+1}    = 'TGT';
end
for k = 1:geom.nAntennas
    geomList{end+1} = [1; xant(k); yant(k); meshControl.rAnt]; %#ok<AGROW>
    names{end+1}    = sprintf('A%02d', k);                     %#ok<AGROW>
end

% Pad columns to equal length
maxLen = max(cellfun(@numel, geomList));
for k = 1:numel(geomList)
    geomList{k}(end+1:maxLen) = 0;
end
gd = [geomList{:}];
ns = char(names)';                   % name-space matrix (one column per shape)
% Union of all shapes (antennas first, then DOI and target); every shape
% becomes its own face.
isAnt = startsWith(names, 'A');
sf = strjoin([names(~isAnt & ~ismember(names, {'OBJ','TGT'})), names(isAnt), ...
              names(ismember(names, {'OBJ','TGT'}))], '+');

%% Geometry
% bt(f, s) = 1 if face f lies inside shape s; used to find the faces of each
% region (face numbering of decsg is not fixed).
[dl, bt] = decsg(gd, sf, ns);
geometryFromEdges(model, dl);

antCols = startsWith(names, 'A');
inAnt   = any(bt(:, antCols), 2);
inDOI   = bt(:, strcmp(names, 'OBJ')) == 1;
if hasTarget
    inTgt = bt(:, strcmp(names, 'TGT')) == 1 & ~inAnt;
else
    inTgt = false(size(inAnt));
end

faces.antennas = find(inAnt)';
faces.target   = find(inTgt)';
faces.doi      = find(inDOI & ~inTgt & ~inAnt)';
faces.bg       = find(~inDOI & ~inTgt & ~inAnt)';

%% Mesh (element size per region)
hface = {faces.doi, meshControl.hDOI, ...
         faces.bg,  meshControl.hBG, ...
         faces.antennas, meshControl.hAnt};
if hasTarget
    hface = [hface, {faces.target, meshControl.hTarget}];
end
mesh = generateMesh(model, 'Hface', hface, 'GeometricOrder', 'linear');

%% Centroids and DOI cells
p = mesh.Nodes;
t = mesh.Elements';

xc = (p(1,t(:,1)) + p(1,t(:,2)) + p(1,t(:,3))) / 3;
yc = (p(2,t(:,1)) + p(2,t(:,2)) + p(2,t(:,3))) / 3;
rCells = sqrt(xc(:).^2 + yc(:).^2);

scenario.cellsDOI         = find(rCells <= geom.doiRadius);
scenario.model            = model;
if nargin >= 3, scenario.domain = domain; end
scenario.mesh             = mesh;
scenario.faces            = faces;
scenario.centroids        = [xc(:), yc(:)];
scenario.antennaPositions = [xant(:), yant(:)];

end
