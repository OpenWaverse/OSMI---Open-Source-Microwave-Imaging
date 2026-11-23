function [E_sc, truth] = differential_data(state, reference, operator)
% DIFFERENTIAL_DATA  Differential (scattered) antenna data from two simulations.
%
%   E_sc          = differential_data(state, reference)
%   [E_sc, truth] = differential_data(state, reference, operator)
%
%       E_sc(m,n) = E_state(r_m; n) - E_reference(r_m; n)
%
%   (row = receiver m, column = transmitter n). With reference = incident
%   (no-target) simulation and state = total (with target), E_sc is the
%   scattered field. Any two states can be used (differential imaging).
%
%   Checks that frequency, current and antenna positions agree, and that the
%   operator simulation (if given) uses the same antennas and frequency.
%
%   truth (only if state and reference share the mesh):
%     .contrast  Delta_eps_r = eps_state - eps_reference on the DOI cells
%     .verts     mesh nodes
%     .cells     DOI triangles
%   Otherwise truth = [].
%
%   See also BORN_TSVD, LOAD_FIELDS

if nargin < 3, operator = []; end

checkCompatible(state, reference, 'state', 'reference');
if ~isempty(operator)
    checkCompatible(state, operator, 'state', 'operator');
end

E_sc = state.Eprobes - reference.Eprobes;

truth = [];
if isequal(size(state.mesh.cells), size(reference.mesh.cells)) && ...
        isequal(state.mesh.cells, reference.mesh.cells)
    doi = state.mesh.cellsDOI;
    truth.contrast = state.perm(doi) - reference.perm(doi);
    truth.verts    = state.mesh.verts;
    truth.cells    = state.mesh.cells(doi, :);
end

end

% -------------------------------------------------------------------------
function checkCompatible(a, b, na, nb)
if abs(a.freq - b.freq) > 1e-9*a.freq
    error('differential_data:freq', 'Frequency of %s (%g Hz) and %s (%g Hz) differ.', ...
        na, a.freq, nb, b.freq);
end
if abs(a.current - b.current) > 1e-12*abs(a.current)
    error('differential_data:current', 'Source current of %s and %s differ.', na, nb);
end
pa = a.mesh.verts(a.mesh.probeNodes, :);
pb = b.mesh.verts(b.mesh.probeNodes, :);
if ~isequal(size(pa), size(pb))
    error('differential_data:antennas', 'Number of antennas of %s and %s differ.', na, nb);
end
d = max(vecnorm(pa - pb, 2, 2));
if d > 5e-3     % different meshes snap antennas to slightly different nodes; flag only real mismatches
    warning('differential_data:antennas', ...
        'Antenna positions of %s and %s differ by up to %.2f mm (nearest mesh nodes).', ...
        na, nb, 1e3*d);
end
end
