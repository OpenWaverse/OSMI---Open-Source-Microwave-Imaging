%% Multi-Frequency Bi-Fpocusing (MFBF) Microwave Imaging
% This script performs imaging reconstruction using
% measurement data from a circular antenna array. The algorithm processes
% scattering parameter (S-parameter) measurements across multiple frequencies
% and reconstructs qualitative imagiong of changes within the imaging domain.

clc; close all; clear;

%% 1. Load Measurement Data

meas_t1 = load('Meas/meas_MT_24.mat');  % Target state measurement
meas_t0 = load('Meas/meas_MT_25.mat');  % Baseline/reference measurement

Sm_t0 = meas_t0.Sm;           % S-parameter matrix at baseline (reference)
Sm_t1 = meas_t1.Sm;           % S-parameter matrix at target state
Delta_Sm = Sm_t0 - Sm_t1;     % Difference matrix (scattered field)
freq_vec = meas_t1.freq;      % Frequency vector (Hz)

fprintf('Loaded measurements from %d frequencies\n', length(freq_vec));

%% 2. Define Antenna Positions
% The antenna array is circular with 12 antennas arranged symmetrically.
% Positions are given in millimeters, then converted to meters.

points = [
    0.00      -110.3;      % Antenna 1
    55.15      -95.52;     % Antenna 2
    95.52      -55.15;     % Antenna 3
    110.3       -1.421e-14; % Antenna 4
    95.52       55.15;      % Antenna 5
    55.15       95.52;      % Antenna 6
    3.553e-14  110.3;       % Antenna 7
    -55.15       95.52;     % Antenna 8
    -95.52       55.15;     % Antenna 9
    -110.3        4.974e-14; % Antenna 10
    -95.52      -55.15;     % Antenna 11
    -55.15      -95.52      % Antenna 12
];

% Convert from millimeters to meters
points_ant = points ./ 1000;
Nant = size(points_ant, 1);

fprintf('Antenna array: %d elements arranged in circle\n', Nant);

%% 3. Define Imaging Grid
% Create a regular grid within the antenna array aperture for image reconstruction.

y_vec = linspace(min(points_ant(:,1)), max(points_ant(:,1)), 100);
z_vec = linspace(min(points_ant(:,2)), max(points_ant(:,2)), 100);

% Initialize image accumulation arrays
MFBF_image_freq = zeros(length(z_vec), length(y_vec)); % Single frequency image
MFBF_image_mf = zeros(length(z_vec), length(y_vec));   % Multi-frequency accumulated image

fprintf('Imaging grid: %d x %d pixels\n', length(y_vec), length(z_vec));

%% 4. Multi-Frequency Beamforming Algorithm
% Process each frequency independently, then combine results for robust reconstruction.
% For each frequency, compute synthetic focusing using Green's function for 2D
% wave propagation in a lossy medium.

for freq_idx = 1:length(freq_vec)

    % Extract S-parameter difference for current frequency
    Delta_Sm_inv = squeeze(Delta_Sm(:,:,freq_idx));
    % Remove diagonal elements (Tx-Rx coupling terms)
    Delta_Sm_inv = Delta_Sm_inv - diag(diag(Delta_Sm_inv));

    % Calculate wavenumber in medium
    freq = freq_vec(freq_idx);
    c0 = 299792458;              % Speed of light in vacuum (m/s)
    eps_r_bg = 45;               % Relative permittivity of background medium
    lambda_medium = (c0/freq) / sqrt(eps_r_bg);  % Wavelength in medium (m)
    k = 2*pi / lambda_medium;    % Wavenumber (rad/m)

    % Reset frequency-specific image
    MFBF_image_freq = zeros(length(z_vec), length(y_vec));

    % Beamforming: iterate over each pixel in the imaging domain
    for iy = 1:length(y_vec)
        for iz = 1:length(z_vec)

            % Current pixel coordinates
            pixel = [y_vec(iy), z_vec(iz)];

            % Calculate distance from pixel to each antenna
            dist_to_probes = sqrt(sum((points_ant - pixel).^2, 2));

            % Build transmit and receive distance matrices for all Tx-Rx pairs
            dist_matrix_tx = dist_to_probes;           % Tx distances (column vector)
            dist_matrix_rx = dist_to_probes.';         % Rx distances (row vector)

            % Compute Green's function (cylindrical wave propagation)
            Gtx = -1i/4 * besselh(0, 1, k*dist_matrix_tx);
            Grx = -1i/4 * besselh(0, 1, k*dist_matrix_rx);

            % Combine transmit and receive Green's functions (Born approximation)
            propagation = Gtx .* Grx;

            % Multiply by measurement data and sum over all Tx-Rx pairs
            corrected_terms = Delta_Sm_inv .* propagation;
            MFBF_image_freq(iz, iy) = sum(corrected_terms, 'all');
        end
    end

    % Normalize by maximum value and accumulate
    MFBF_image_mf = MFBF_image_mf + abs(MFBF_image_freq) ./ max(abs(MFBF_image_freq(:)));

    if mod(freq_idx, 5) == 0
        fprintf('  Processed %d/%d frequencies\n', freq_idx, length(freq_vec));
    end
end

fprintf('Multi-frequency beamforming complete\n');

%% 5. Apply Spatial Mask
% Mask the image to only show pixels within a circular region defined by
% the antenna array aperture.

[Y, Z] = meshgrid(y_vec, z_vec);

% Calculate antenna array radius (mean distance from center)
R = mean(sqrt(points_ant(:,1).^2 + points_ant(:,2).^2));

% Create circular mask (80% of array radius for conservative masking)
mask = (Y.^2 + Z.^2) <= (0.8*R)^2;

% Normalize image and apply mask
MFBF_image_masked = MFBF_image_mf;
MFBF_image_masked_normalized_mag = abs(MFBF_image_masked) ./ max(abs(MFBF_image_masked(:)));
MFBF_image_masked_normalized_mag(~mask) = NaN;  % Set masked regions to NaN for transparency

fprintf('Masking applied: radius = %.3f m, mask radius = %.3f m\n', R, 0.8*R);

%% 6. Visualization

figure;
hold on;
A = abs(MFBF_image_masked_normalized_mag);
A(isnan(A)) = -1;
imagesc(y_vec, z_vec, A);
cmap = jet(256);
cmap(1,:) = [1 1 1];       % First color = white
colormap(cmap)
colorbar;
clim([0 1]);
axis equal;
axis xy;
xlabel('Y (m)', 'FontSize', 12);
ylabel('Z (m)', 'FontSize', 12);
title('Multi-Frequency Beamforming Microwave Image', 'FontSize', 14);
scatter(points_ant(:,1),points_ant(:,2),40,'k','filled')





