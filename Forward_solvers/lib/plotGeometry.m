function plotGeometry(scenario)
% PLOTGEOMETRY  Plot the scenario geometry with face labels and the PML.
%
%   plotGeometry(scenario)     scenario returned by GENERATE_FIELDS /
%                              CREATESCENARIOMESH; the whole square is shown
%                              and the start of the PML is drawn dashed
%   plotGeometry(model)        PDEModel only (no PML outline)
%
%   Face labels help to check that the regions (background, DOI, target,
%   antennas) were built correctly.
%
%   See also PLOTMESH, CREATESCENARIOMESH, COMPUTEDOMAIN

[model, domain] = unpack(scenario);

figure;
pdegplot(model, 'FaceLabels', 'on', 'EdgeLabels', 'off');
hold on;
drawPML(domain);
hold off;
axis equal;
grid on;
xlabel('$x$ (m)');
ylabel('$y$ (m)');
title('Geometry, face labels and PML');

end

% -------------------------------------------------------------------------
function [model, domain] = unpack(s)
domain = [];
if isstruct(s)
    model = s.model;
    if isfield(s, 'domain'), domain = s.domain; end
else
    model = s;
end
end

function drawPML(domain)
if isempty(domain), return; end
s = domain.pmlStart;
plot([-s s s -s -s], [-s -s s s -s], 'r--', 'LineWidth', 1);
text(0, -s - domain.pml.thickness/2, 'PML', 'Color', 'r', ...
     'HorizontalAlignment', 'center');
end
