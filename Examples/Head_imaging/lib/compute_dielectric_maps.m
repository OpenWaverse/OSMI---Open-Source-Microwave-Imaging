function perm = ...
        compute_dielectric_maps(labels, freq, varargin)
% COMPUTE_DIELECTRIC_MAPS  Build a 2-D complex permittivity map from MRI tissue
%                          labels using the 4-Cole-Cole model (Gabriel 1996).
%
%   eps_map = compute_dielectric_maps(labels, freq)
%   eps_map = compute_dielectric_maps(labels, freq, 'verbose', false)
%
%   Returns a 2-D matrix of complex relative permittivity values, one entry
%   per pixel of the input label image.  The imaginary part is negative
%   (lossy convention):
%
%     eps*(r) = eps'(r)  +  j * eps''(r)
%
%   where eps'' < 0 encodes conductivity losses.
%
%   Inputs
%   ------
%   labels   : 2-D matrix of integer tissue labels in the range [0, 11].
%                 0  Background (air / coupling medium)
%                 1  CSF
%                 2  Gray Matter
%                 3  White Matter
%                 4  Fat (not infiltrated)
%                 5  Muscle
%                 6  Skin (wet)
%                 7  Skull (cortical bone)
%                 8  Blood (vessels)
%                 9  Infiltrated Fat
%                10  Dura Mater
%                11  Bone Marrow (not infiltrated)
%
%   freq     : Simulation frequency in Hz (e.g. 1e9 for 1 GHz).
%
%   Optional name-value pairs
%   -------------------------
%   'verbose'  : true/false — print a per-tissue summary table (default: true).
%
%   Output
%   ------
%   eps_complex_map : 2-D matrix (same size as labels) of complex relative
%                     permittivity values.  Pass to map_permittivity_to_mesh
%                     to obtain cell-wise values on the FEM mesh.
%
%   Model
%   -----
%   eps*(omega) = eps_inf
%               + sum_n { Delta_n / [1 + (j*omega*tau_n)^(1-alpha_n)] }
%               - j * sigma / (omega * eps0)
%
%   Reference
%   ---------
%   Gabriel et al. (1996). The dielectric properties of biological tissues.
%   https://niremf.ifac.cnr.it/docs/DIELECTRIC/AppendixC.html
%
%   See also MAP_PERMITTIVITY_TO_MESH


%% --- Parse optional arguments ---
p = inputParser;
addRequired(p,  'labels',   @isnumeric);
addRequired(p,  'freq',     @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'verbose',  true, @islogical);
parse(p, labels, freq, varargin{:});

do_verbose = p.Results.verbose;

%% --- Constants ---
eps0  = 8.854187817e-12;   % permittivity of free space [F/m]
omega = 2 * pi * freq;

%% --- Tissue names ---
tissue_names = {'Background', 'CSF', 'Gray Matter', 'White Matter', ...
                'Fat', 'Muscle', 'Muscle/Skin', 'Skull', ...
                'Vessels', 'Around Fat', 'Dura Mater', 'Bone Marrow'};

%% --- 4-Cole-Cole Parameters (Gabriel et al. 1996) ---
% Columns:
%   [ef, del1, tau1(ps), alf1,
%        del2, tau2(ns), alf2,
%        sig,
%        del3, tau3(us), alf3,
%        del4, tau4(ms), alf4]
%
% Row order: labels 0 through 11

params = [
% 0  Background (air)
   1,    0,      0,    0,      0,      0,    0,  0.000,      0,      0,    0,      0,      0,    0;
% 1  CSF
   4,   65,  7.958, 0.10,     40,  1.592, 0.00,  2.000,      0, 159.155, 0.00,      0, 15.915, 0.00;
% 2  Gray Matter
   4,   45,  7.958, 0.10,    400, 15.915, 0.15,  0.020,    2e5, 106.103, 0.22,  4.5e7,  5.305, 0.00;
% 3  White Matter
   4,   32,  7.958, 0.10,    100,  7.958, 0.10,  0.020,    4e4,  53.052, 0.30,  3.5e7,  7.958, 0.02;
% 4  Fat (Not Infiltrated)
 2.5,    3,  7.958, 0.20,     15, 15.915, 0.10,  0.010,  3.3e4, 159.155, 0.05,    1e7,  7.958, 0.01;
% 5  Muscle
   4,   50,  7.234, 0.10,   7000,353.678, 0.10,  0.200,  1.2e6, 318.310, 0.10,  2.5e7,  2.274, 0.00;
% 6  Muscle/Skin -> Skin (Wet)
   4,   39,  7.958, 0.10,    280, 79.577, 0.00,  0.000,    3e4,   1.592, 0.16,    3e4,  1.592, 0.20;
% 7  Skull -> Bone Cortical
 2.5,   10, 13.263, 0.20,    180, 79.577, 0.20,  0.020,    5e3, 159.155, 0.20,    1e5, 15.915, 0.00;
% 8  Vessels -> Blood
   4,   56,  8.377, 0.10,   5200,132.629, 0.10,  0.700,      0, 159.155, 0.20,      0, 15.915, 0.00;
% 9  Around Fat -> Fat (Infiltrated)
 2.5,    9,  7.958, 0.20,     35, 15.915, 0.10,  0.035,  3.3e4, 159.155, 0.05,    1e7, 15.915, 0.01;
%10  Dura Mater
   4,   40,  7.958, 0.15,    200,  7.958, 0.10,  0.500,    1e4, 159.155, 0.20,    1e6, 15.915, 0.00;
%11  Bone Marrow (Not Infiltrated)
 2.5,    3,  7.958, 0.20,     25, 15.915, 0.10,  0.001,    5e3,1591.549, 0.10,    2e6, 15.915, 0.10;
];

%% --- Compute complex permittivity for each tissue ---
num_tissues  = size(params, 1);
eps_complex  = zeros(num_tissues, 1);

for t = 1:num_tissues
    q    = params(t, :);
    ef   = q(1);
    del1 = q(2);  tau1 = q(3)  * 1e-12;  alf1 = q(4);
    del2 = q(5);  tau2 = q(6)  * 1e-9;   alf2 = q(7);
    sig  = q(8);
    del3 = q(9);  tau3 = q(10) * 1e-6;   alf3 = q(11);
    del4 = q(12); tau4 = q(13) * 1e-3;   alf4 = q(14);

    eps_complex(t) = ef ...
        + del1 / (1 + (1j*omega*tau1)^(1-alf1)) ...
        + del2 / (1 + (1j*omega*tau2)^(1-alf2)) ...
        + del3 / (1 + (1j*omega*tau3)^(1-alf3)) ...
        + del4 / (1 + (1j*omega*tau4)^(1-alf4)) ...
        - 1j * sig / (omega * eps0);
end

%% --- Build spatial maps ---
[rows, cols]  = size(labels);
eps_real_map  = zeros(rows, cols);
eps_imag_map  = zeros(rows, cols);
sigma_eff_map = zeros(rows, cols);

for t = 0:11
    mask = (labels == t);
    eps_real_map(mask)  = real(eps_complex(t+1));
    eps_imag_map(mask)  = imag(eps_complex(t+1));
    sigma_eff_map(mask) = -imag(eps_complex(t+1)) * omega * eps0;
end
eps_complex_map = eps_real_map + 1i*eps_imag_map;

perm = struct();
perm.real = permute(eps_real_map, [2 1 3]);
perm.imag = permute(eps_imag_map, [2 1 3]);
perm.complex = permute(eps_complex_map, [2 1 3]);


%% --- Optional: print summary table ---
if do_verbose
    fprintf('\nFrequency: %.4f MHz\n', freq/1e6);
    fprintf('%-15s  %10s  %10s  %14s\n', ...
            'Tissue', "eps'", "eps''", 'sigma_eff (S/m)');
    fprintf('%s\n', repmat('-', 1, 57));
    for t = 0:11
        fprintf('%-15s  %10.4f  %10.4f  %14.6f\n', ...
            tissue_names{t+1}, ...
            real(eps_complex(t+1)), ...
            imag(eps_complex(t+1)), ...
            -imag(eps_complex(t+1)) * omega * eps0);
    end
    fprintf('\n');
end

end