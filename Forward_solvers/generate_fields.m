function [fields, scenario] = generate_fields(sim, materials, geom, meshControl, opts)
% GENERATE_FIELDS  Simulate ONE scenario with the FEM solver and save it by name.
%
%   [fields, scenario] = generate_fields(sim, materials, geom, meshControl, opts)
%
%   Sizes the computational square and the PML from the geometry, builds
%   the mesh, assigns the materials, solves the field radiated by every
%   antenna (one FEM solve per transmitter) and, if opts.name is given,
%   saves the result as <opts.outputDir>/<opts.name>.mat.
%
%   Run it once per scenario you need, e.g.
%     "incident"  no target  (includeTarget = false)
%     "total"     with target
%   The imaging scripts then choose which file builds the operator and
%   which pair (state - reference) forms the differential (scattered) data.
%
%   Inputs
%   ------
%   sim         : .f  frequency (Hz)
%   materials   : .background / .doi / .target (target optional), each with
%                   .epsr   relative permittivity eps'
%                   .sigma  conductivity (S/m)
%   geom        : scenario geometry: .doiRadius, .antennaRing, .nAntennas and,
%                 optionally, .targetRadius / .targetCenter. The outer square
%                 and the PML are NOT given: they are sized automatically from
%                 the geometry (see COMPUTEDOMAIN).
%   meshControl : element sizes (see CREATESCENARIOMESH)
%   opts        : (optional) struct with fields
%                   .name           scenario name / file name   [""  -> not saved]
%                   .outputDir      folder of the .mat file     ['results']
%                   .includeTarget  false -> the target region gets the
%                                   DOI material (no scatterer) [true]
%                   .current        line-source current I (A)   [1e-3]
%                   .pml            square/PML overrides: .squareFactor
%                                   (side / max radius) [4], .pmlFraction
%                                   (PML share of the half-size) [0.25],
%                                   .R, .n, .kappaMax (see COMPUTEDOMAIN)
%
%   Outputs
%   -------
%   fields   : FIELDS struct (see SOLVE_FIELDS) plus .geom, .materials
%              (with .epsc), .meshControl, .includeTarget and .domain
%              (square size, PML, default plot limits)
%   scenario : mesh/geometry struct from CREATESCENARIOMESH (PDE model and
%              .domain, for PLOTGEOMETRY / PLOTMESH)
%
%   Material model: eps_c = eps' - j*sigma/(omega*eps0)   (exp(+j*omega*t)).
%
%   See also COMPUTEDOMAIN, SOLVE_FIELDS, SAVE_FIELDS, LOAD_FIELDS, PLOTFIELD

if nargin < 5, opts = struct(); end
if ~isfield(opts, 'name'),          opts.name          = "";        end
if ~isfield(opts, 'outputDir'),     opts.outputDir     = 'results'; end
if ~isfield(opts, 'includeTarget'), opts.includeTarget = true;      end
if ~isfield(opts, 'current'),       opts.current       = 1e-3;      end
if ~isfield(opts, 'pml'),           opts.pml           = struct();  end

eps0  = 8.854187817e-12;
c0    = 299792458;
omega = 2*pi*sim.f;

%% Complex permittivity of every region
for region = string(fieldnames(materials))'
    materials.(region).epsc = materials.(region).epsr ...
        - 1j*materials.(region).sigma/(omega*eps0);
end

hasTarget = isfield(geom, 'targetRadius') && ~isempty(geom.targetRadius) ...
            && geom.targetRadius > 0;
if hasTarget && ~isfield(materials, 'target')
    error('generate_fields:target', 'geom defines a target but materials.target is missing.');
end

matUsed = materials;
if hasTarget && ~opts.includeTarget
    matUsed.target = materials.doi;          % target region filled with DOI medium
end

%% Computational square and PML, sized from the geometry
if isfield(geom, 'squareSize')
    warning('generate_fields:squareSize', ...
        'geom.squareSize is ignored: the square and the PML are sized automatically (see opts.pml).');
    geom = rmfield(geom, 'squareSize');
end
lambda_bg = c0/(sim.f*real(sqrt(materials.background.epsc)));
domain    = computeDomain(geom, meshControl, lambda_bg, opts.pml);

%% Geometry, mesh, materials, antennas
scenario = createScenarioMesh(geom, meshControl, domain);
perm     = assignPermittivity(scenario.centroids, geom, matUsed);
probes   = findProbeNodes(scenario.mesh.Nodes, scenario.antennaPositions);

label = string(opts.name);
if label == "", label = "(unnamed)"; end
fprintf('[%s] geometry radius %.3f m -> square %.3f m, PML from %.3f m (%.3f m thick, gap %.3f m)\n', ...
    label, domain.radius, domain.squareSize, domain.pmlStart, domain.pml.thickness, domain.pml.gap);
fprintf('[%s] mesh: %d nodes, %d triangles; solving %d sources ...\n', ...
    label, size(scenario.mesh.Nodes,2), size(scenario.mesh.Elements,2), numel(probes));

%% FEM solution
fields = solve_fields(scenario.mesh.Nodes', scenario.mesh.Elements', perm.complex, ...
    sim.f, probes, materials.background.epsc, opts.current, scenario.cellsDOI, ...
    opts.name, domain.pml);

fields.geom          = geom;
fields.materials     = matUsed;
fields.meshControl   = meshControl;
fields.includeTarget = hasTarget && opts.includeTarget;
fields.domain        = domain;

%% Save
if strlength(string(opts.name)) > 0
    save_fields(fields, opts.name, opts.outputDir);
end

end
