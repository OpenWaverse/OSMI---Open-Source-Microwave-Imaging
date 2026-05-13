function plot_svd_analysis(S)
%PLOT_SVD_ANALYSIS Plot singular values and cumulative energy
%
%   plot_svd_analysis(S)
%
%   Inputs:
%       S : matrix of singular values
    % Singular values
    s = diag(S);

    % Singular values in dB (normalized)
    s_db = 20 * log10(s / max(s));

    % Energy contribution
    energy = s.^2;
    cumulative_energy = cumsum(energy) / sum(energy);

    % Create figure
    figure;

    % ---- Singular values plot ----
    subplot(2,1,1);
    plot(s_db, 'o-', 'LineWidth', 1, 'MarkerSize', 6);
    grid on;

    xlabel('Singular Value Index');
    ylabel('Magnitude (dB)');
    title('Ordered Singular Values');

    % ---- Cumulative energy plot ----
    subplot(2,1,2);
    plot(cumulative_energy * 100, 's-', ...
         'LineWidth', 1, 'MarkerSize', 6);

    grid on;
    ylim([0 100]);

    xlabel('Number of Singular Values');
    ylabel('Cumulative Energy (%)');
    title('Cumulative Energy Content');

end