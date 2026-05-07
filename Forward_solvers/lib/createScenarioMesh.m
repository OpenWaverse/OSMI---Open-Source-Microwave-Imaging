function scenario = createScenarioMesh(geom, meshControl)
% CREATESCENARIOMESH  Build the PDE geometry and FEM mesh for a microwave
%                     imaging scenario.
%
%   scenario = createScenarioMesh(geom, meshControl)
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
%                   geom.squareSize   — side length of the square domain (m).
%                   geom.doiRadius    — radius of the DOI circle (m).
%                   geom.targetCenter — 1-by-2 vector [x, y] of target
%                                       circle centre (m).
%                   geom.targetRadius — radius of the target circle (m).
%                   geom.nAntennas    — number of antennas, evenly spaced on
%                                       a circle of radius antennaRing.
%                   geom.antennaRing  — radius of the antenna ring (m).
%
%   meshControl : Struct with mesh size parameters:
%                   meshControl.rAnt    — radius of each antenna disc (m).
%                   meshControl.hDOI    — target element size inside DOI.
%                   meshControl.hBG     — target element size in background.
%                   meshControl.hTarget — target element size inside target.
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
%
%   Geometry layout (all coordinates centred at origin)
%   ---------------------------------------------------
%   SQ  — outer square boundary.
%   OBJ — circular DOI region.
%   TGT — circular target inclusion inside OBJ.
%   A01..Akk — small circular antenna discs on the ring.
%
%   The set-formula passed to decsg is:
%       SQ + A01 + ... + Akk + OBJ + TGT
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

%% Square

L = geom.squareSize;

x1 = -L/2;
x2 =  L/2;
y1 = -L/2;
y2 =  L/2;

SQ = [3;4; x1;x2;x2;x1; y1;y1;y2;y2];

%% DOI

Cobj = [1;0;0;geom.doiRadius];
Ctarget = [1;
           geom.targetCenter(1);
           geom.targetCenter(2);
           geom.targetRadius];

%% Antennas

theta = linspace(0,2*pi,geom.nAntennas+1);
theta(end)=[];

xant = geom.antennaRing*cos(theta);
yant = geom.antennaRing*sin(theta);

geomList = {};
geomList{1} = SQ;
geomList{2} = Cobj;
geomList{3} = Ctarget;

for k=1:geom.nAntennas

    geomList{end+1} = [1;
                       xant(k);
                       yant(k);
                       meshControl.rAnt];
end

%% Padding

maxLen = max(cellfun(@length,geomList));

for k=1:length(geomList)
    geomList{k}(end+1:maxLen)=0;
end

gd = [geomList{:}];

%% Names

ns = [];
ns = [ns; 'SQ '];
ns = [ns; 'OBJ'];
ns = [ns; 'TGT'];

for k=1:geom.nAntennas
    ns = [ns; sprintf('A%02d',k)];
end

ns = ns';

%% Formula
sf = 'SQ';

for k=1:geom.nAntennas
    sf = [sf sprintf('+A%02d',k)];
end

sf = [sf '+OBJ+TGT'];

%% Geometry

dl = decsg(gd,sf,ns);
geometryFromEdges(model,dl);

%% Mesh

mesh = generateMesh(model,...
    'Hface',{ ...
        [1], meshControl.hDOI, ...
        [2], meshControl.hBG, ...
        [3], meshControl.hTarget, ...
        [4:(3+geom.nAntennas)], meshControl.hAnt ...
    },...
    'GeometricOrder','linear');

%% Centroids

p = mesh.Nodes;
t = mesh.Elements';

xc = (p(1,t(:,1)) + p(1,t(:,2)) + p(1,t(:,3))) / 3;
yc = (p(2,t(:,1)) + p(2,t(:,2)) + p(2,t(:,3))) / 3;
rCells = sqrt(xc(:).^2 + yc(:).^2);

scenario.cellsDOI = find(rCells <= geom.doiRadius);
scenario.model = model;
scenario.mesh = mesh;
scenario.centroids = [xc(:), yc(:)];
scenario.antennaPositions = [xant(:), yant(:)];


end
