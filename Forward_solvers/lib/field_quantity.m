function [values, label, units] = field_quantity(fields, tx, quantity, ref)
% FIELD_QUANTITY  Cell-wise real quantity of the field radiated by one transmitter.
%
%   [values, label, units] = field_quantity(fields, tx, quantity)
%   [values, label, units] = field_quantity(fields, tx, quantity, ref)
%
%   fields   : FIELDS struct (see SOLVE_FIELDS)
%   tx       : transmitter index (1..Nant)
%   quantity : 'abs' | 'dB' | 'phase' | 'real' | 'imag'
%   ref      : (optional) reference FIELDS struct on the SAME mesh. If given,
%              the difference E = E_fields - E_ref is used (e.g. scattered
%              field = total - incident).
%
%   values   : Nc-by-1 real vector (one value per triangle)
%   label    : LaTeX label of the quantity, e.g. '$|E_z|$'
%   units    : units string

if nargin < 4, ref = []; end

nAnt = size(fields.Ecells, 2);
if tx < 1 || tx > nAnt || tx ~= round(tx)
    error('field_quantity:tx', 'tx must be an integer between 1 and %d.', nAnt);
end

E = fields.Ecells(:, tx);
sym = 'E_z';
if ~isempty(ref)
    if ~isequal(size(ref.Ecells, 1), size(fields.Ecells, 1))
        error('field_quantity:mesh', ...
            'The reference fields are on a different mesh; differences need the same mesh.');
    end
    E   = E - ref.Ecells(:, tx);
    sym = '\Delta E_z';
end

% Labels are LaTeX (see SET_LATEX_FIGURES)
switch lower(quantity)
    case 'abs',   values = abs(E);                         label = ['$|' sym '|$'];                   units = 'V/m';
    case 'db',    values = 20*log10(abs(E)/max(abs(E)));   label = ['$|' sym '|/\max|' sym '|$'];     units = 'dB';
    case 'phase', values = angle(E);                       label = ['$\angle ' sym '$'];              units = 'rad';
    case 'real',  values = real(E);                        label = ['$\mathrm{Re}\{' sym '\}$'];      units = 'V/m';
    case 'imag',  values = imag(E);                        label = ['$\mathrm{Im}\{' sym '\}$'];      units = 'V/m';
    otherwise
        error('field_quantity:quantity', 'Unknown quantity "%s".', quantity);
end

end
