function msh = readGmshMesh(file)
% READGMSHMESH  Read a 2-D triangular Gmsh mesh (MSH 2.2 ASCII) for FEM2D.
%
%   msh = readGmshMesh(file)
%
%   Export the mesh from Gmsh as MSH 2.2 ASCII, e.g.
%       gmsh geometry.geo -2 -format msh22 -o mesh.msh
%
%   Output (ready for FEM2D / SOLVE_FIELDS)
%   ------
%   msh.verts      Nv-by-2  node coordinates [x y] (m)
%   msh.cells      Nc-by-3  triangle connectivity (1-based row indices of verts)
%   msh.region     Nc-by-1  physical-group tag of each triangle
%   msh.names      containers.Map  physical tag -> name (e.g. 1 -> "background")
%   msh.points     struct array of physical points: .tag, .node (index into verts)
%
%   Only linear triangles (Gmsh element type 2) and points (type 15) are
%   read; lines and other elements are ignored. Nodes not used by any
%   triangle are removed and the connectivity is renumbered, because FEM2D
%   needs every node to belong to at least one triangle.
%
%   See also FEM2D, SOLVE_FIELDS

txt   = fileread(file);
lines = splitlines(string(txt));

%% Format check
i = find(lines == "$MeshFormat", 1);
ver = sscanf(lines(i+1), '%f', 1);
if isempty(ver) || floor(ver) ~= 2
    error('readGmshMesh:format', ...
        'Only MSH 2.x ASCII is supported (found "%s"). Export with -format msh22.', lines(i+1));
end

%% Physical names
msh.names = containers.Map('KeyType', 'double', 'ValueType', 'char');
i = find(lines == "$PhysicalNames", 1);
if ~isempty(i)
    n = str2double(lines(i+1));
    for k = 1:n
        tok = regexp(lines(i+1+k), '^\s*(\d+)\s+(\d+)\s+"(.*)"', 'tokens', 'once');
        msh.names(str2double(tok{2})) = char(tok{3});
    end
end

%% Nodes:  id x y z
i  = find(lines == "$Nodes", 1);
nN = str2double(lines(i+1));
A  = sscanf(strjoin(lines(i+2:i+1+nN), ' '), '%f', [4, nN])';
ids = A(:, 1);
xy  = A(:, 2:3);
map = zeros(max(ids), 1);
map(ids) = 1:nN;                       % Gmsh node id -> row of xy

%% Elements:  id type ntags tag1(physical) tag2(elementary) ... nodes
i  = find(lines == "$Elements", 1);
nE = str2double(lines(i+1));
tri = zeros(nE, 3);  reg = zeros(nE, 1);  nt = 0;
pts = zeros(nE, 2);  np = 0;
for k = 1:nE
    v = sscanf(lines(i+1+k), '%d')';
    type  = v(2);
    ntags = v(3);
    phys  = v(4);
    nodes = v(4+ntags:end);
    if type == 2                       % 3-node triangle
        nt = nt + 1;
        tri(nt, :) = map(nodes);
        reg(nt)    = phys;
    elseif type == 15                  % 1-node point
        np = np + 1;
        pts(np, :) = [phys, map(nodes)];
    end
end
tri = tri(1:nt, :);  reg = reg(1:nt);  pts = pts(1:np, :);

if nt == 0
    error('readGmshMesh:noTriangles', 'No linear triangles found (mesh with -2 and ElementOrder 1).');
end

if size(unique(sort(tri, 2), 'rows'), 1) < nt
    error('readGmshMesh:duplicates', ...
        'Repeated triangles: a surface belongs to more than one physical group.');
end

%% Keep only nodes used by triangles and renumber
used = unique(tri(:));
newIdx = zeros(nN, 1);
newIdx(used) = 1:numel(used);

msh.verts  = xy(used, :);
msh.cells  = newIdx(tri);
msh.region = reg;

msh.points = struct('tag', {}, 'node', {});
for k = 1:np
    if newIdx(pts(k, 2)) > 0
        msh.points(end+1) = struct('tag', pts(k, 1), 'node', newIdx(pts(k, 2)));
    end
end

end
