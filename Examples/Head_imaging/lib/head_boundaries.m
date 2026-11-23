function curves = head_boundaries(file, firstContour)
% HEAD_BOUNDARIES  Tissue contours of the MRI slice, in mesh coordinates.
%
%   curves = head_boundaries(file)
%   curves = head_boundaries(file, firstContour)      (default firstContour = 100)
%
%   Loads the cell array 'boundaries' (K-by-2 polylines, m) and rotates it
%   by -90 deg to match the orientation of the FEM mesh. Contours before
%   firstContour are skipped (display choice). Use the result as the
%   'Overlay' option of PLOTFIELD / FIELDVIEWER.

if nargin < 2, firstContour = 100; end

S = load(file, 'boundaries');
theta = -pi/2;
Rot   = [cos(theta) -sin(theta); sin(theta) cos(theta)];

idx    = firstContour:numel(S.boundaries);
curves = cell(numel(idx), 1);
for k = 1:numel(idx)
    curves{k} = (Rot * S.boundaries{idx(k)}')';
end

end
