function rec = born_tsvd(E_sc, E_inc_doi, dA, freq, current, opts)
% BORN_TSVD  Linear microwave imaging: Born approximation + truncated SVD.
%
%   rec = born_tsvd(E_sc, E_inc_doi, dA, freq, current)
%   rec = born_tsvd(E_sc, E_inc_doi, dA, freq, current, opts)
%
%   Model  (exp(+j*omega*t), TM_z, antennas are line sources of current I)
%   ---------------------------------------------------------------------
%   Under the first-order Born approximation the scattered field measured at
%   antenna m when antenna n transmits is
%
%       E_sc(m,n) = (j*omega*eps0 / I) * integral_DOI  E_inc(r; n) * E_inc(r; m)
%                                                      * Delta_eps_r(r) dA
%
%   where E_inc(r; n) is the incident field at r radiated by antenna n and
%   Delta_eps_r = eps_r - eps_r,b is the relative-permittivity contrast.
%   The receiver term follows from reciprocity: the Green's function from r
%   to antenna m is G(r_m, r) = E_inc(r; m) / (-j*omega*mu0*I).
%
%   Discretising over the DOI cells c (area dA_c) and keeping only the
%   reciprocal-unique pairs p = (n, m) with n <= m gives the linear system
%
%       e = K * x,   K(p,c) = (j*omega*eps0/I) * E_inc(r_c; n_p) E_inc(r_c; m_p) dA_c,
%                    x(c)   = Delta_eps_r(r_c)
%
%   Inversion: K = U*S*V^H (economy SVD), keep the Nt largest singular values
%   such that  sum_{i<=Nt} s_i^2 / sum_i s_i^2 >= threshold, and
%
%       x = V_Nt * S_Nt^{-1} * U_Nt^H * e.
%
%   Inputs
%   ------
%   E_sc      : Nant-by-Nant scattered field at the antennas
%               (row = receiver m, column = transmitter n).
%   E_inc_doi : Ncell-by-Nant incident field on the DOI cells, column n =
%               transmitter n (same antenna order as E_sc).
%   dA        : Ncell-by-1 cell areas (m^2).
%   freq      : frequency (Hz).
%   current   : line-source current I (A) used in the forward simulation.
%   opts      : (optional)
%                 .threshold  cumulative-energy threshold   [0.9999]
%                 .plotSVD    plot singular-value spectrum  [false]
%
%   Output
%   ------
%   rec.delta_eps : Ncell-by-1 recovered contrast Delta_eps_r (complex).
%   rec.Nt        : number of retained singular values.
%   rec.s         : singular values of K (descending).
%   rec.K         : data operator.
%
%   See also PLOT_SVD_ANALYSIS, PLOTCONTRAST
%
%   References
%   ----------
%   [1] N. K. Nikolova, Introduction to Microwave Imaging, Cambridge University
%       Press, 2017, doi: 10.1017/9781316084267.
%   [2] M. Bertero, P. Boccacci and C. De Mol, Introduction to Inverse Problems
%       in Imaging, 2nd ed., CRC Press, 2021, doi: 10.1201/9781003032755.

if nargin < 6, opts = struct(); end
if ~isfield(opts, 'threshold'), opts.threshold = 0.9999; end
if ~isfield(opts, 'plotSVD'),   opts.plotSVD   = false;  end

eps0  = 8.854187817e-12;
omega = 2*pi*freq;

%% Data operator K (reciprocal-unique pairs n <= m)
N_ant  = size(E_sc, 1);
[n, m] = find(triu(true(N_ant)));          % n = transmitter, m = receiver

E_tx = E_inc_doi(:, n);                    % Ncell-by-Npairs
E_rx = E_inc_doi(:, m);
K    = (1j*omega*eps0/current) * (E_tx.' .* E_rx.') .* dA(:).';

e = E_sc(sub2ind([N_ant, N_ant], m, n));   % E_sc(receiver, transmitter)

%% Truncated SVD
[U, S, V] = svd(K, 'econ');
s          = diag(S);
cum_energy = cumsum(s.^2) / sum(s.^2);
Nt         = find(cum_energy >= opts.threshold, 1, 'first');

fprintf('TSVD: retaining %d of %d singular values (%.4f%% energy)\n', ...
    Nt, numel(s), 100*opts.threshold);

if opts.plotSVD
    plot_svd_analysis(S);
end

x = V(:,1:Nt) * ((U(:,1:Nt)' * e) ./ s(1:Nt));

rec.delta_eps = x;
rec.Nt        = Nt;
rec.s         = s;
rec.K         = K;

end
