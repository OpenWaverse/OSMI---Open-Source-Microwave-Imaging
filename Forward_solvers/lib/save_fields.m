function file = save_fields(fields, name, outputDir)
% SAVE_FIELDS  Save a FIELDS struct as <outputDir>/<name>.mat.
%
%   file = save_fields(fields, name)
%   file = save_fields(fields, name, outputDir)      (default outputDir = 'results')
%
%   The file contains a single variable, FIELDS (see SOLVE_FIELDS), and
%   can be read back with LOAD_FIELDS. The name is also stored in
%   fields.name.
%
%   See also LOAD_FIELDS, GENERATE_FIELDS

if nargin < 3 || isempty(outputDir), outputDir = 'results'; end
if ~isfolder(outputDir), mkdir(outputDir); end

name = string(name);
fields.name = name; %#ok<STRNU>
file = fullfile(outputDir, name + ".mat");

info = whos('fields');
if info.bytes > 1.9e9
    save(file, 'fields', '-v7.3');
else
    save(file, 'fields');
end
fprintf('Saved "%s"  ->  %s\n', name, file);

end
