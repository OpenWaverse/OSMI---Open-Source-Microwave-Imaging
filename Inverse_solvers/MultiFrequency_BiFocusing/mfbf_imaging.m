function img = mfbf_imaging(DeltaS, freq_vec, antPos, eps_r_bg, opts)
% MFBF_IMAGING  Multi-Frequency Bi-Focusing (MFBF) qualitative imaging.
%
%   img = mfbf_imaging(DeltaS, freq_vec, antPos, eps_r_bg)
%   img = mfbf_imaging(DeltaS, freq_vec, antPos, eps_r_bg, opts)
%
%   Differential multistatic data DeltaS(m,n,f) (e.g. S-parameters of a
%   reference state minus those of the state under test) are focused onto
%   every pixel r of a Cartesian grid by back-propagating from both the
%   transmitter n and the receiver m:
%
%       I_f(r) = sum_{m ~= n}  DeltaS(m,n,f) * Gb(r, r_n) * Gb(r, r_m)
%
%   with the back-propagator  Gb(r, r') = -(j/4) * H0^(1)(k_b |r - r'|),
%   k_b = 2*pi*f*sqrt(eps_r_bg)/c0. For exp(+j*omega*t) the outgoing 2-D
%   Green's function is G = -(j/4) H0^(2)(k_b rho), so Gb = -conj(G) for a
%   lossless background, i.e. a phase-conjugate (time-reversal) focusing.
%   The product of two propagators is not affected by this sign.
%
%   Frequencies are combined coherently, so the image is complex:
%
%       I_MF(r) = sum_f  I_f(r),     I(r) = I_MF(r) / max_r |I_MF(r)|
%
%   |I| locates the target; Re{I} and Im{I} keep the phase of the data. They
%   give the sign of the contrast only if the phase of the data is calibrated.
%
%   Monostatic terms (m = n) are discarded (antenna reflection dominated).
%
%   Inputs
%   ------
%   DeltaS   : Nant-by-Nant-by-Nf differential data.
%   freq_vec : Nf-by-1 frequencies (Hz).
%   antPos   : Nant-by-2 antenna coordinates (m).
%   eps_r_bg : (real) relative permittivity of the background medium.
%   opts     : (optional)
%                .nPixels     pixels per axis                [100]
%                .maskFactor  image mask radius / array radius [0.8]
%
%   Output
%   ------
%   img.x, img.y  : pixel coordinates (m)
%   img.I         : nPixels-by-nPixels complex image with max |I| = 1
%                   inside the mask, NaN outside the circular mask (rows = y, cols = x)
%   img.I_raw     : unmasked, not normalised (complex) image

if nargin < 5, opts = struct(); end
if ~isfield(opts, 'nPixels'),    opts.nPixels    = 100; end
if ~isfield(opts, 'maskFactor'), opts.maskFactor = 0.8; end

c0   = 299792458;
Nf   = numel(freq_vec);

%% Imaging grid (bounding box of the array)
x_vec = linspace(min(antPos(:,1)), max(antPos(:,1)), opts.nPixels);
y_vec = linspace(min(antPos(:,2)), max(antPos(:,2)), opts.nPixels);
I_mf  = zeros(numel(y_vec), numel(x_vec));

%% Per-frequency bi-focusing
for fi = 1:Nf
    D = squeeze(DeltaS(:,:,fi));
    D = D - diag(diag(D));                       % drop monostatic terms

    k_b = 2*pi*freq_vec(fi)*sqrt(eps_r_bg)/c0;   % background wavenumber
    I_f = zeros(numel(y_vec), numel(x_vec));

    for ix = 1:numel(x_vec)
        for iy = 1:numel(y_vec)
            rho = sqrt(sum((antPos - [x_vec(ix), y_vec(iy)]).^2, 2));  % |r - r_n|
            Gb  = -1j/4 * besselh(0, 1, k_b*rho);                      % Nant-by-1
            I_f(iy, ix) = sum(D .* (Gb * Gb.'), 'all');                % Gb(r_m) Gb(r_n)
        end
    end

    I_mf = I_mf + I_f;

    if mod(fi, 5) == 0
        fprintf('  MFBF: processed %d/%d frequencies\n', fi, Nf);
    end
end

%% Circular mask and normalisation
[X, Y] = meshgrid(x_vec, y_vec);
R_arr  = mean(sqrt(sum(antPos.^2, 2)));
mask   = (X.^2 + Y.^2) <= (opts.maskFactor*R_arr)^2;

% Divide by the maximum magnitude (a real number) to keep the phase
I = I_mf ./ max(abs(I_mf(mask)));
I(~mask) = NaN;

img.x     = x_vec;
img.y     = y_vec;
img.I     = I;
img.I_raw = I_mf;

end
