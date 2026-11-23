function setup_osmi()
% SETUP_OSMI  Add the OSMI library folders to the MATLAB path.
%
%   Run once per MATLAB session (every example script calls it):
%       setup_osmi
%
%   Only library code is added (forward and inverse solvers, utilities).
%   Example-specific helpers stay local to each example folder.

root = fileparts(mfilename('fullpath'));

addpath(fullfile(root, 'Forward_solvers'));
addpath(fullfile(root, 'Forward_solvers', 'lib'));

inv = fullfile(root, 'Inverse_solvers');
addpath(fullfile(inv, 'common'));
addpath(fullfile(inv, 'Born_approximation_TSVD'));
addpath(fullfile(inv, 'Born_approximation_TSVD', 'lib'));
addpath(fullfile(inv, 'MultiFrequency_BiFocusing'));

addpath(fullfile(root, 'Utilities'));

% All figure text rendered with LaTeX
set_latex_figures;

end
