function perm = assignPermittivity(...
    centroids,...
    geom,...
    materials)

x = centroids(:,1);
y = centroids(:,2);

rDOI = sqrt(x.^2 + y.^2);

rTarget = sqrt( ...
    (x - geom.targetCenter(1)).^2 + ...
    (y - geom.targetCenter(2)).^2);

perm.complex = zeros(size(x));

%% Regions
insideTarget = rTarget <= geom.targetRadius;
insideDOI    = (rDOI <= geom.doiRadius) & (~insideTarget);
outsideDOI   = rDOI > geom.doiRadius;

%% Assign Materials
perm.complex(outsideDOI) = materials.background.epsc;
perm.complex(insideDOI)  = materials.doi.epsc;
perm.complex(insideTarget) = materials.target.epsc;

perm.real = real(perm.complex);
perm.imag = imag(perm.complex);

end
