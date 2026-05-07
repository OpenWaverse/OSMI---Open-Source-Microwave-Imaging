function scenario = createScenarioMesh(geom, meshControl)

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
