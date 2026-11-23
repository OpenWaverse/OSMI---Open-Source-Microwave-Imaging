function plotMesh(scenario)
% PLOTMESH  Display the finite-element mesh, with the start of the PML.
%
%   plotMesh(scenario)     scenario returned by GENERATE_FIELDS /
%                          CREATESCENARIOMESH (PML drawn dashed in red)
%   plotMesh(model)        PDEModel only
%   plotMesh(fields)       FIELDS struct (e.g. a pre-built mesh without a
%                          PDE model, as in the head example)
%
%   Useful to inspect the element size in each region (background, DOI,
%   target, antennas) and inside the PML before running the solver.
%
%   See also PLOTGEOMETRY, CREATESCENARIOMESH, PDEMESH

domain = [];
figure;
if isstruct(scenario) && isfield(scenario, 'model')
    pdemesh(scenario.model);
    if isfield(scenario, 'domain'), domain = scenario.domain; end
elseif isstruct(scenario) && isfield(scenario, 'mesh') && isfield(scenario.mesh, 'verts')
    v = scenario.mesh.verts;
    triplot(scenario.mesh.cells, v(:,1), v(:,2), 'Color', [0 0.45 0.74], 'LineWidth', 0.25);
    if isfield(scenario, 'domain'), domain = scenario.domain; end
else
    pdemesh(scenario);
end

if ~isempty(domain)
    hold on;
    s = domain.pmlStart;
    plot([-s s s -s -s], [-s -s s s -s], 'r--', 'LineWidth', 1.5);
    hold off;
end
axis equal;
grid on;
xlabel('$x$ (m)');
ylabel('$y$ (m)');
if isempty(domain), title('FEM mesh'); else, title('FEM mesh and PML'); end

end
