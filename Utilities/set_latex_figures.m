function set_latex_figures(enable)
% SET_LATEX_FIGURES  Use the LaTeX interpreter for all figure text by default.
%
%   set_latex_figures          LaTeX for titles, labels, tick labels, legends
%                              and colour bars of every new figure
%   set_latex_figures(false)   restore MATLAB's default (TeX)
%
%   Called automatically by SETUP_OSMI. The setting lasts for the MATLAB
%   session and only affects figures created afterwards.
%
%   With LaTeX, write math between dollar signs ('$|E_z|$') and escape the
%   special characters  _ % & # $  in plain text (e.g. 'Energy (\%)').
%   Use LATEX_TEXT to escape arbitrary strings such as file names.

if nargin < 1, enable = true; end
if enable, interp = 'latex'; else, interp = 'tex'; end

set(groot, 'defaultTextInterpreter',               interp);
set(groot, 'defaultAxesTickLabelInterpreter',      interp);
set(groot, 'defaultLegendInterpreter',             interp);
set(groot, 'defaultColorbarTickLabelInterpreter',  interp);
set(groot, 'defaultPolaraxesTickLabelInterpreter', interp);
set(groot, 'defaultTextarrowshapeInterpreter',     interp);
set(groot, 'defaultTextboxshapeInterpreter',       interp);

end
