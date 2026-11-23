function fields = load_fields(name, outputDir)
% LOAD_FIELDS  Load a FIELDS struct saved by SAVE_FIELDS / GENERATE_FIELDS.
%
%   fields = load_fields(name)                 reads results/<name>.mat
%   fields = load_fields(name, outputDir)      reads <outputDir>/<name>.mat
%   fields = load_fields(fullPathToMatFile)
%
%   See also SAVE_FIELDS, SOLVE_FIELDS

if nargin < 2 || isempty(outputDir), outputDir = 'results'; end

name = string(name);
if isfile(name)
    file = name;
else
    if ~endsWith(name, ".mat"), name = name + ".mat"; end
    file = fullfile(outputDir, name);
end

if ~isfile(file)
    error('load_fields:notFound', ...
        'Fields file "%s" not found. Run the forward script first.', file);
end

S = load(file, 'fields');
fields = S.fields;

end
