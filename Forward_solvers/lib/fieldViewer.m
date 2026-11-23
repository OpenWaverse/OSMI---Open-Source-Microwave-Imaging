function fig = fieldViewer(fields, ref, varargin)
% FIELDVIEWER  Interactive window to browse the fields of every transmitter.
%
%   fieldViewer(fields)
%   fieldViewer(fields, ref)                 adds the reference and the
%                                            difference (fields - ref, e.g.
%                                            the scattered field)
%   fieldViewer(..., 'Limits', [x1 x2 y1 y2])
%   fieldViewer(..., 'Overlay', polylines)
%   fieldViewer(..., 'CLim', struct('dB', [-40 0]))   initial colour limits
%                                                     per quantity
%
%   Controls
%   --------
%   Transmitter : antenna that radiates
%   Field       : state / reference / difference
%   Quantity    : |E|, dB (20 log10 |E|/max|E|), phase, Re, Im
%   Auto        : automatic colour limits; untick it and type Min / Max to
%                 fix them. The limits are remembered per quantity, so they
%                 are kept while browsing transmitters.
%
%   See also PLOTFIELD, FIELD_QUANTITY

if nargin < 2, ref = []; end
p = inputParser;
addParameter(p, 'Limits',  []);
addParameter(p, 'Overlay', {});
addParameter(p, 'CLim',    struct());
parse(p, varargin{:});
o = p.Results;

nAnt = size(fields.Ecells, 2);
quantities = {'abs', 'dB', 'phase', 'real', 'imag'};

% Manual colour limits per quantity ([] = auto)
manual = struct();
for q = quantities
    manual.(q{1}) = [];
    if isfield(o.CLim, q{1}), manual.(q{1}) = o.CLim.(q{1}); end
end

which = {char(fields.name)};
if isempty(which{1}), which{1} = 'Fields'; end
if ~isempty(ref)
    which = [which, {char(ref.name)}];
    if size(ref.Ecells, 1) == size(fields.Ecells, 1)
        which = [which, {'Difference'}];
    end
end

%% Layout
fig  = uifigure('Name', 'OSMI field viewer', 'Position', [100 100 780 680]);
main = uigridlayout(fig, [2 1]);
main.RowHeight = {70, '1x'};

% Controls: two rows of six columns
c = uigridlayout(main, [2 6]);
c.Padding     = [0 0 0 0];
c.RowHeight   = {28, 28};
c.ColumnWidth = {80, 90, 50, '1x', 70, '1x'};

txSpin  = uispinner(c, 'Limits', [1 nAnt], 'Value', 1, 'Step', 1, ...
                    'RoundFractionalValues', 'on');
fieldDD = uidropdown(c, 'Items', which, 'Value', which{end});
qDD     = uidropdown(c, 'Items', quantities, 'Value', 'abs');
autoCB  = uicheckbox(c, 'Text', 'Auto', 'Value', true);
minEF   = uieditfield(c, 'numeric', 'ValueDisplayFormat', '%.4g');
maxEF   = uieditfield(c, 'numeric', 'ValueDisplayFormat', '%.4g');

place(uilabel(c, 'Text', 'Transmitter', 'HorizontalAlignment', 'right'), 1, 1);
place(txSpin, 1, 2);
place(uilabel(c, 'Text', 'Field', 'HorizontalAlignment', 'right'), 1, 3);
place(fieldDD, 1, 4);
place(uilabel(c, 'Text', 'Quantity', 'HorizontalAlignment', 'right'), 1, 5);
place(qDD, 1, 6);
place(uilabel(c, 'Text', 'Colour limits', 'HorizontalAlignment', 'right'), 2, 1);
place(autoCB, 2, 2);
place(uilabel(c, 'Text', 'Min', 'HorizontalAlignment', 'right'), 2, 3);
place(minEF, 2, 4);
place(uilabel(c, 'Text', 'Max', 'HorizontalAlignment', 'right'), 2, 5);
place(maxEF, 2, 6);

ax = uiaxes(main);
ax.Layout.Row    = 2;
ax.Layout.Column = 1;

%% Callbacks
txSpin.ValueChangedFcn  = @(~,~) redraw();
fieldDD.ValueChangedFcn = @(~,~) redraw();
qDD.ValueChangedFcn     = @(~,~) redraw();
autoCB.ValueChangedFcn  = @(~,~) onAuto();
minEF.ValueChangedFcn   = @(~,~) onLimits();
maxEF.ValueChangedFcn   = @(~,~) onLimits();

redraw();

    function redraw()
        q    = qDD.Value;
        cl   = manual.(q);
        args = {'Parent', ax, 'Limits', o.Limits, 'Overlay', o.Overlay, 'CLim', cl};
        tx   = txSpin.Value;
        switch find(strcmp(which, fieldDD.Value), 1)
            case 1, plotField(fields, tx, q, args{:});
            case 2, plotField(ref,    tx, q, args{:});
            case 3, plotField(fields, tx, q, 'Reference', ref, args{:});
        end
        % show the limits in use
        autoCB.Value  = isempty(cl);
        minEF.Enable  = ~autoCB.Value;
        maxEF.Enable  = ~autoCB.Value;
        c = clim(ax);
        minEF.Value = c(1);
        maxEF.Value = c(2);
    end

    function onAuto()
        q = qDD.Value;
        if autoCB.Value
            manual.(q) = [];
        else
            manual.(q) = clim(ax);          % start from the current limits
        end
        redraw();
    end

    function onLimits()
        if minEF.Value >= maxEF.Value
            uialert(fig, 'Min must be smaller than Max.', 'Colour limits');
            c = clim(ax); minEF.Value = c(1); maxEF.Value = c(2);
            return
        end
        manual.(qDD.Value) = [minEF.Value, maxEF.Value];
        redraw();
    end
end

% -------------------------------------------------------------------------
function place(h, row, col)
h.Layout.Row    = row;
h.Layout.Column = col;
end
