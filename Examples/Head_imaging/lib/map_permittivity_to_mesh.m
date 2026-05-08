function perm = map_permittivity_to_mesh( ...
    A_perm, verts, cells, resolution, idx_cells_DoI, perm_bg)
% MAP_PERMITTIVITY_TO_MESH  Interpolate a pixel-level permittivity map onto
%                           FEM mesh cells by nearest-neighbour lookup.
%
%   perm_cells = map_permittivity_to_mesh(A_perm, verts, cells, ...
%                    resolution, idx_cells_DoI, perm_bg)
%
%   Each triangular cell centroid is mapped to the nearest pixel of A_perm.
%   Cells whose indices do not appear in idx_cells_DoI are assigned the
%   scalar background value perm_bg regardless of the image content.
%   The permittivity map is centred in the image and vertically flipped to
%   match the coordinate convention of the FEM mesh.
%
%   Inputs
%   ------
%   A_perm         : 2-D complex permittivity map (Ny x Nx), e.g. the output
%                    of compute_dielectric_maps after permute([2 1 3]).
%
%   verts          : (N x 2) or (N x 3) matrix of mesh vertex coordinates [m].
%                    Only the first two columns (x, y) are used.
%
%   cells          : (M x 3) matrix of triangle connectivity (1-based indices
%                    into verts).
%
%   resolution     : Pixel size [m] of A_perm (e.g. 0.5e-3 for 0.5 mm MRI).
%
%   idx_cells_DoI  : Column vector of global cell indices that belong to the
%                    Domain of Interest (DOI).  Only these cells receive values
%                    from A_perm; all others are set to perm_bg.
%
%   perm_bg        : Scalar complex permittivity assigned to non-DOI cells and
%                    to background pixels outside the anatomy.
%
%   Output
%   ------
%   perm_cells     : (M x 1) complex vector of per-cell relative permittivity
%                    values, ready to pass as argument 3 of fem2d.
%
%   See also COMPUTE_DIELECTRIC_MAPS

%% --- Center permittivity map ---
B = A_perm ~= A_perm(1,1);

[row, col] = find(B);
bbox = A_perm(min(row):max(row), min(col):max(col));

[Ny, Nx] = size(A_perm);

A = ones(Ny, Nx) * A_perm(1,1);

r0 = floor((Ny - size(bbox,1))/2) + 1;
c0 = floor((Nx - size(bbox,2))/2) + 1;

A(r0:r0+size(bbox,1)-1, c0:c0+size(bbox,2)-1) = bbox;
A = flipud(A);

%% --- Coordinate system ---
dx = resolution;
dy = resolution;

x = ((1:Nx) - (Nx+1)/2 + 0.5) * dx;
y = ((1:Ny) - (Ny+1)/2 + 0.5) * dy;

%% --- Cell centroids ---
centroids = ( ...
    verts(cells(:,1),:) + ...
    verts(cells(:,2),:) + ...
    verts(cells(:,3),:) ) / 3;

col = round((centroids(:,1) - x(1))/dx) + 1;
row = round((centroids(:,2) - y(1))/dy) + 1;

col = max(1, min(Nx, col));
row = max(1, min(Ny, row));

idx = sub2ind([Ny, Nx], row, col);

%% --- Map permittivity ---
perm_cells = A(idx);

%% --- Background assignment ---
mask_bg = true(size(perm_cells));
mask_bg(idx_cells_DoI) = false;

perm_cells(mask_bg) = perm_bg;
perm.real = real(perm_cells);
perm.imag = imag(perm_cells);
perm.complex = perm_cells;

end