function perm = assignPermittivity(...
    centroids,...
    geom,...
    materials)
% ASSIGNPERMITTIVITY  Assign complex permittivity to each cell.
%
%   perm = assignPermittivity(centroids, geom, materials)
%
%   Map every element centroid into one of non-overlapping
%   spatial regions — background (outside DOI), domain of interest (DOI),
%   and target inclusion — based on radial distances. Each region is
%   then assigned the complex permittivity of its corresponding material.
%
%   Inputs
%   ------
%   centroids  : nElem-by-2 matrix of element centroid coordinates [x, y],
%                one row per triangular element.
%
%   geom       : Struct with geometry parameters:
%                  geom.doiRadius      — radius of the DOI circle (m).
%                  geom.targetCenter   — 1-by-2 vector [x, y] of target
%                                        circle centre (m).
%                  geom.targetRadius   — radius of the target circle (m).
%
%   materials  : Struct with one sub-struct per region, each containing a
%                field 'epsc' (complex relative permittivity εr − jσ/(ωε0)):
%                  materials.background.epsc — background medium.
%                  materials.doi.epsc        — coupling/immersion medium
%                                              inside DOI, excluding target.
%                  materials.target.epsc     — target (scatterer) inclusion.
%
%   Output
%   ------
%   perm       : Struct with fields:
%                  perm.complex — nElem-by-1 complex permittivity vector.
%                  perm.real    — real part of perm.complex (ε').
%                  perm.imag    — imaginary part of perm.complex (= −σ/(ωε0) ≤ 0).
%
%   Region assignment logic
%   -----------------------
%   outsideDOI   : sqrt(x^2 + y^2) > doiRadius
%   insideTarget : distance to targetCenter <= targetRadius
%   insideDOI    : inside DOI circle AND not inside target
%
%   Example
%   -------
%   perm = assignPermittivity(scenario.centroids, geom, materials);
%   plotPermittivity(scenario.mesh, perm.real, 'Real Permittivity');
%
%   See also CREATESCENARIOMESH, PLOTPERMITTIVITY

x = centroids(:,1);
y = centroids(:,2);

rDOI = sqrt(x.^2 + y.^2);

perm.complex = zeros(size(x));

%% Regions (the target is optional)
hasTarget = isfield(geom, 'targetRadius') && ~isempty(geom.targetRadius) ...
            && geom.targetRadius > 0 && isfield(materials, 'target');
if hasTarget
    rTarget = sqrt((x - geom.targetCenter(1)).^2 + (y - geom.targetCenter(2)).^2);
    insideTarget = rTarget <= geom.targetRadius;
else
    insideTarget = false(size(x));
end
insideDOI    = (rDOI <= geom.doiRadius) & (~insideTarget);
outsideDOI   = rDOI > geom.doiRadius;

%% Assign Materials
perm.complex(outsideDOI) = materials.background.epsc;
perm.complex(insideDOI)  = materials.doi.epsc;
if hasTarget
    perm.complex(insideTarget) = materials.target.epsc;
end

perm.real = real(perm.complex);
perm.imag = imag(perm.complex);

end
