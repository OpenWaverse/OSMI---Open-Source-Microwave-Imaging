# OSMI — Open-Source Microwave Imaging

A MATLAB framework for 2-D microwave imaging: a finite-element forward solver
to synthesise multistatic data, and imaging algorithms to reconstruct the
dielectric contrast from them.

---

## Repository structure

```
OSMI---Open-Source-Microwave-Imaging/
│
├── setup_osmi.m                      Adds the library folders to the MATLAB path
│
├── Forward_solvers/                  ── library: forward problem
│   ├── generate_fields.m             Simulate ONE scenario and save it by name
│   └── lib/
│       ├── fem2d.p                   2-D FEM Helmholtz solver (TM_z, PML), compiled
│       ├── solve_fields.m            fem2d for all antennas -> FIELDS struct
│       ├── save_fields.m / load_fields.m   results/<name>.mat
│       ├── createScenarioMesh.m      Geometry + mesh (square, DOI, target, antennas)
│       ├── assignPermittivity.m      Material map on the mesh cells
│       ├── findProbeNodes.m          Antenna -> nearest mesh node
│       ├── plotField.m               Field of a chosen Tx (|E|, dB, phase, Re, Im, differences)
│       ├── fieldViewer.m             Interactive window: browse Tx / field / quantity
│       ├── readGmshMesh.m            Gmsh mesh (MSH 2.2) -> verts / cells / regions
│       └── plot*.m                   Geometry, mesh, permittivity plots
│
├── Inverse_solvers/                  ── library: inverse problem
│   ├── common/                       differential_data.m
│   ├── Born_approximation_TSVD/
│   │   ├── born_tsvd.m               Born-approximation operator + truncated SVD
│   │   └── lib/                      plot_svd_analysis.m, plotContrast.m
│   └── MultiFrequency_BiFocusing/
│       └── mfbf_imaging.m            Multi-frequency bi-focusing (qualitative)
│
└── Examples/                         ── runnable scenarios (scripts + data)
    ├── Circular_domain/              Fields in a circular DOI, no target
    │   └── main_generate_fields.mlx
    ├── Circular_domain_target/       Fields in a circular DOI with a target inclusion
    │   └── main_generate_fields.mlx
    ├── Circular_scattered_field/     Incident, total and scattered fields + imaging
    │   ├── main_generate_fields.mlx
    │   └── main_imaging_born_tsvd.mlx
    ├── Head_imaging/                 MRI-based head model with a haemorrhagic stroke
    │   ├── data/                     MRI labels, mesh
    │   ├── lib/                      Cole-Cole tissue model, pixel->mesh mapping, contours
    │   ├── main_generate_fields.mlx  results: healthy.mat, stroke.mat
    │   └── main_imaging_born_tsvd.mlx
    ├── Gmsh_circular_domain_target/  Circular_domain_target meshed with Gmsh
    │   ├── generate_meshes.py        Gmsh Python script: data mesh and operator mesh
    │   ├── data/                     meshes (.msh)
    │   └── main_generate_fields.mlx  incident, total, scattered field; operator
    └── Measured_MFBF/                MFBF on measured S-parameters
        ├── data/
        └── main_imaging_MFBF.mlx
```

**Library** folders (`Forward_solvers`, `Inverse_solvers`) contain only reusable
functions. **Examples** are live scripts (`.mlx`, with explanations and
equations) that define a scenario, call the library, and store their outputs
in `Examples/<name>/results/` (ignored by git; regenerate them by running the
scripts).

---

## Quick start

The circular examples build on each other:

1. `Examples/Circular_domain/main_generate_fields.mlx`: fields radiated by
   each antenna into a homogeneous circular DOI (no target).
2. `Examples/Circular_domain_target/main_generate_fields.mlx`: the same
   domain with a circular target inclusion.
3. `Examples/Circular_scattered_field/`:
   * `main_generate_fields.mlx`: incident (`incident`), total (`total`) and
     scattered field $E_{sc}=E_{tot}-E_{inc}$, plus the imaging operator
     (`operator`, incident field on a reconstruction mesh);
   * `main_imaging_born_tsvd.mlx`: Born/TSVD reconstruction from those files.

Two more forward examples show that any mesh can be used:

4. `Examples/Head_imaging/`: MRI-based head (Aubert-Broche et al., IEEE TMI
   2006) on an external structured mesh (two triangles per 0.5 mm pixel),
   healthy and with a haemorrhagic stroke.
5. `Examples/Gmsh_circular_domain_target/`: the scenario of example 2 meshed
   with [Gmsh](https://gmsh.info) (`generate_meshes.py`), read with
   `readGmshMesh`, permittivity assigned by physical group. Two meshes: one
   with the target region (`incident`, `total`) and one for the operator
   (`operator`).

### Using an external mesh

`fem2d` only needs arrays, so a mesh from any software can be used:

| Input | Size | Content |
|---|---|---|
| `verts` | Nv × 2 | node coordinates [x y] (m) |
| `cells` | Nc × 3 | triangle connectivity, 1-based rows of `verts` |
| `perm` | Nc × 1 | complex relative permittivity of every triangle |
| `probeNodes` | Nant × 1 | node index of every antenna |

```matlab
fields = solve_fields(verts, cells, perm, freq, probeNodes, eps_bg, current, cellsDOI, "name");
```

The FEM solves for $E_z$ at the nodes (`Everts`, Nv × Nant); `Ecells`
(Nc × Nant) is the mean of the three node values, i.e. the field at each
triangle centroid; `Eprobes` (Nant × Nant) is the field at the antennas.

Every example calls `setup_osmi` itself, so no manual `addpath` is needed.

### Named simulations

Each forward run is one scenario saved under a name you choose:

```matlab
opts.name = "target";  opts.includeTarget = true;
fields = generate_fields(sim, materials, geom, meshControl, opts);   % -> results/target.mat
```

The imaging script then chooses, by name, which simulation builds the
**operator** (its incident field on the DOI) and which pair forms the
**differential data** (`state - reference` at the antennas):

```matlab
operator  = load_fields("operator");
state     = load_fields("total");
reference = load_fields("incident");
[E_sc, truth] = differential_data(state, reference, operator);
```

Fields of any transmitter can be plotted with `plotField(fields, tx, 'abs')`
(add `'Reference', ref` for the scattered/differential field and
`'CLim', [min max]` to fix the colour range, e.g. `[-40 0]` for `'dB'`) or
browsed with `fieldViewer(state, reference)`, which has Min/Max boxes for the
colour range (remembered per quantity).

### Figures

`setup_osmi` calls `set_latex_figures`, so every figure uses the LaTeX
interpreter (titles, labels, ticks, colour bars, legends). Write math as
`'$|E_z|$'` and escape `_ % & #` in plain text (`latex_text` does it for you).
`set_latex_figures(false)` restores MATLAB's default.

---

## Conventions and notation

| Item | Convention |
|---|---|
| Time dependence | $e^{+j\omega t}$ |
| Complex permittivity | $\varepsilon_r = \varepsilon' - j\varepsilon''$, with $\varepsilon'' = \sigma/(\omega\varepsilon_0) \ge 0$ |
| Polarisation | TM$_z$: scalar field $E_z(x,y)$ |
| Antennas | Line sources of current $I$ |
| Contrast | $\Delta\varepsilon_r = \varepsilon_r - \varepsilon_{r,b}$ (object minus background) |
| Field matrices | `E(m, n)`: row = receiver $m$, column = transmitter $n$ |

---

## Forward solver

`fem2d` solves, for each transmitter $n$ located at $\mathbf r_n$,

$$
\nabla^2 E_z + k_0^2\,\varepsilon_r(\mathbf r)\,E_z = j\omega\mu_0 I\,\delta(\mathbf r-\mathbf r_n),
\qquad k_0=\omega\sqrt{\mu_0\varepsilon_0},
$$

with linear triangular elements and a polynomial PML (Perfectly Matched Layer). In a homogeneous medium its solution is
$E_z = -\tfrac{\omega\mu_0 I}{4} H_0^{(2)}(k\,|\mathbf r-\mathbf r_n|)$.

### Computational domain and PML (automatic)

The user defines only the physical geometry (DOI, antennas, targets). The
outer square and the PML are sized from it (`computeDomain`):

1. maximum radius of the geometry in $x$ and $y$: $a=\max(|x_{min}|,|x_{max}|,|y_{min}|,|y_{max}|)$, antenna discs included;
2. square side $L = 4a$;
3. PML = outer 25 % of the half-size: it starts at $s = 0.75\,L/2 = 1.5\,a$ and is $0.5\,a$ thick, leaving a clearance of $0.5\,a$ to the antennas.

Change the proportions with `opts.pml.squareFactor` (default 4) and
`opts.pml.pmlFraction` (default 0.25); `.R`, `.n`, `.kappaMax` set the PML
profile. An error is raised if the PML would overlap the geometry, and a
warning if it is thinner than half a background wavelength. Field and
permittivity plots show the whole region except the PML by default; geometry
and mesh plots draw the PML boundary.

`generate_fields` builds the mesh of one scenario, assigns the materials
(`opts.includeTarget = false` gives the target region the DOI material), solves
for every transmitter and saves a single `fields` struct in `results/<name>.mat`:

| Field | Content |
|---|---|
| `name`, `freq`, `current`, `eps_bg` | scenario name, frequency, source current, outer medium |
| `mesh.verts`, `mesh.cells`, `mesh.area` | mesh nodes, triangles, triangle areas |
| `mesh.probeNodes`, `mesh.cellsDOI` | antenna nodes, DOI triangles |
| `perm` | complex relative permittivity per triangle |
| `Ecells`, `Everts` | $E_z$ per triangle / node, column $n$ = transmitter $n$ |
| `Eprobes` | $E_z$ at the antennas (row = receiver, column = transmitter) |
| `geom`, `materials`, `meshControl` | scenario definition (when made by `generate_fields`) |

To avoid the *inverse crime*, simulate the operator and the data on different
meshes (as the default example does).

---

## Imaging algorithms

### Born approximation + TSVD (`born_tsvd`)

Under the first-order Born approximation and reciprocity,

$$
E_{sc}(m,n) = \frac{j\omega\varepsilon_0}{I}\int_{\mathrm{DOI}}
E_{inc}(\mathbf r; n)\,E_{inc}(\mathbf r; m)\,\Delta\varepsilon_r(\mathbf r)\,dA .
$$

Discretising on the DOI cells gives $\mathbf e = \mathbf K\,\mathbf x$ with
$K_{p,c} = \frac{j\omega\varepsilon_0}{I}E_{inc}(\mathbf r_c;n_p)E_{inc}(\mathbf r_c;m_p)\,\Delta A_c$
and $x_c=\Delta\varepsilon_r(\mathbf r_c)$, using the reciprocal-unique pairs $n\le m$.
With $\mathbf K=\mathbf U\mathbf S\mathbf V^H$, the $N_t$ largest singular values
that hold a fraction `threshold` of the energy $\sum s_i^2$ are kept:

$$
\mathbf x = \mathbf V_{N_t}\,\mathbf S_{N_t}^{-1}\,\mathbf U_{N_t}^H\,\mathbf e .
$$

### Multi-frequency bi-focusing (`mfbf_imaging`)

Qualitative imaging of differential data $\Delta S(m,n,f)$:

$$
I(\mathbf r)=\frac{\sum_f I_f(\mathbf r)}{\max\left|\sum_f I_f\right|},\qquad
I_f(\mathbf r)=\sum_{m\ne n}\Delta S(m,n,f)\,G_b(\mathbf r,\mathbf r_n)\,G_b(\mathbf r,\mathbf r_m),
$$

with the back-propagator $G_b = -\tfrac{j}{4}H_0^{(1)}(k_b\rho)$ (phase conjugate of the
outgoing Green's function for $e^{+j\omega t}$). The frequencies are summed coherently and
the image is complex: $|I|$ locates the target, while the real and imaginary parts give the
sign of the contrast only if the phase of the data is calibrated.

---

## Requirements

- MATLAB R2023b or later
- `fem2d.p` is distributed as compiled MATLAB P-code
- Partial Differential Equation Toolbox (geometry and mesh generation)

---

## License

MIT License. See `LICENSE`.
