function fields = solve_fields(verts, cells, perm, freq, probeNodes, eps_bg, current, cellsDOI, name, pml)
% SOLVE_FIELDS  Run FEM2D for every antenna and pack the result in a FIELDS struct.
%
%   fields = solve_fields(verts, cells, perm, freq, probeNodes, eps_bg, current, cellsDOI)
%   fields = solve_fields(..., name)
%   fields = solve_fields(..., name, pml)      PML parameters for FEM2D
%
%   Inputs
%   ------
%   verts      : Nv-by-2 node coordinates (m)
%   cells      : Nc-by-3 triangle connectivity
%   perm       : Nc-by-1 complex relative permittivity per triangle
%   freq       : frequency (Hz)
%   probeNodes : Nant-by-1 node index of each antenna (also the receivers)
%   eps_bg     : complex relative permittivity of the outer medium (PML)
%   current    : line-source current I (A)
%   cellsDOI   : indices of the triangles inside the Domain of Interest
%   name       : (optional) scenario name, e.g. "background"
%
%   Output: FIELDS struct (the format stored by SAVE_FIELDS)
%   ------
%   .name                 scenario name
%   .freq, .current       frequency (Hz), source current (A)
%   .eps_bg               outer-medium permittivity
%   .mesh.verts           Nv-by-2
%   .mesh.cells           Nc-by-3
%   .mesh.area            Nc-by-1 triangle areas
%   .mesh.probeNodes      Nant-by-1
%   .mesh.cellsDOI        DOI triangle indices
%   .perm                 Nc-by-1 complex relative permittivity
%   .Everts               Nv-by-Nant   E_z at nodes   (column n = transmitter n)
%   .Ecells               Nc-by-Nant   E_z per triangle
%   .Eprobes              Nant-by-Nant E_z at the antennas (row = receiver m,
%                                      column = transmitter n)
%
%   See also GENERATE_FIELDS, SAVE_FIELDS, LOAD_FIELDS, FEM2D

if nargin < 9,  name = ""; end
if nargin < 10, pml  = []; end

verts = verts(:, 1:2);
perm  = perm(:);

[Everts, Ecells, Area] = fem2d(verts, cells, perm, freq, probeNodes, eps_bg, [], current, pml);

fields.name    = string(name);
fields.freq    = freq;
fields.current = current;
fields.eps_bg  = eps_bg;

fields.mesh.verts      = verts;
fields.mesh.cells      = cells;
fields.mesh.area       = Area;
fields.mesh.probeNodes = probeNodes(:);
fields.mesh.cellsDOI   = cellsDOI(:);

fields.perm    = perm;
fields.Everts  = Everts;
fields.Ecells  = Ecells;
fields.Eprobes = Everts(probeNodes, :);

end
