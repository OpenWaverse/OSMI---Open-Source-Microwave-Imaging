"""Generate the two Gmsh meshes of the circular-domain example.

    data/circular_domain_target.msh     data mesh: DOI with the target region
                                        (used for the incident AND total field)
    data/circular_domain_operator.msh   operator mesh: no target, different
                                        element size (no inverse crime)

Usage:   pip install gmsh
         python generate_meshes.py

Physical groups: 1 background, 2 doi, 3 target, 4 antenna (surfaces),
                 5 antenna_centre (points).   Units: metres.
The format is MSH 2.2 ASCII, read in MATLAB by readGmshMesh.m.
"""
import math
from pathlib import Path

import gmsh

# ----------------------------------------------------------------- parameters
# Keep in sync with main_generate_fields.mlx
FREQ = 1e9                      # Hz
C0 = 299792458.0                # m/s
EPS_BG, EPS_DOI, EPS_TGT = 20.0, 20.0, 60.0   # eps'

R_DOI = 0.10                    # DOI radius
R_RING, N_ANT = 0.12, 24        # antenna ring radius, number of antennas
R_TGT, X_TGT, Y_TGT = 0.01, 0.03, 0.03        # target radius and centre

N_DATA = 12                     # data mesh:     h = lambda / 12
N_OPERATOR = 10                 # operator mesh: h = lambda / 10

LAMBDA_BG = C0 / (FREQ * math.sqrt(EPS_BG))
LAMBDA_DOI = C0 / (FREQ * math.sqrt(EPS_DOI))
LAMBDA_TGT = C0 / (FREQ * math.sqrt(EPS_TGT))
R_ANT = LAMBDA_BG / 15          # antenna disc radius
H_ANT = LAMBDA_BG / 15          # element size in the antenna discs
SIDE = 4 * (R_RING + R_ANT)     # square side: 4 x maximum radius (computeDomain.m)

DATA_DIR = Path(__file__).resolve().parent / "data"
TOL = 1e-6


def entities_in(x, y, r, dim):
    """Tags of the entities inside the bounding box of a disc."""
    return {tag for _, tag in gmsh.model.getEntitiesInBoundingBox(
        x - r - TOL, y - r - TOL, -TOL, x + r + TOL, y + r + TOL, TOL, dim)}


def build_mesh(filename, cells_per_lambda, with_target):
    """Build and save one mesh with element size h = lambda / cells_per_lambda."""
    gmsh.model.add(filename)
    occ = gmsh.model.occ

    # Shapes
    square = occ.addRectangle(-SIDE / 2, -SIDE / 2, 0, SIDE, SIDE)
    tools = [(2, occ.addDisk(0, 0, 0, R_DOI, R_DOI))]
    if with_target:
        tools.append((2, occ.addDisk(X_TGT, Y_TGT, 0, R_TGT, R_TGT)))
    centres = []
    for k in range(N_ANT):
        angle = 2 * math.pi * k / N_ANT
        x, y = R_RING * math.cos(angle), R_RING * math.sin(angle)
        centres.append((x, y))
        tools.append((2, occ.addDisk(x, y, 0, R_ANT, R_ANT)))
        tools.append((0, occ.addPoint(x, y, 0)))     # forces a node at the centre

    # Conforming partition: every shape becomes its own surface
    occ.fragment([(2, square)], tools)
    occ.synchronize()

    # Identify the regions by position
    target = entities_in(X_TGT, Y_TGT, R_TGT, 2) if with_target else set()
    antennas, points = set(), []
    for x, y in centres:
        antennas |= entities_in(x, y, R_ANT, 2)
        points += entities_in(x, y, 0, 0)
    # The diagonal antennas lie inside the bounding box of the DOI: exclude them
    doi = entities_in(0, 0, R_DOI, 2) - target - antennas
    everything = {tag for _, tag in gmsh.model.getEntities(2)}
    background = everything - doi - target - antennas
    assert len(antennas) == N_ANT and len(points) == N_ANT

    # Physical groups and element size of every region
    regions = [(1, "background", background, LAMBDA_BG / cells_per_lambda),
               (2, "doi", doi, LAMBDA_DOI / cells_per_lambda),
               (3, "target", target, LAMBDA_TGT / cells_per_lambda),
               (4, "antenna", antennas, H_ANT)]
    fields = []
    for tag, name, surfaces, size in regions:
        if not surfaces:
            continue
        gmsh.model.addPhysicalGroup(2, sorted(surfaces), tag, name)
        field = gmsh.model.mesh.field.add("Constant")
        gmsh.model.mesh.field.setNumber(field, "VIn", size)
        gmsh.model.mesh.field.setNumbers(field, "SurfacesList", sorted(surfaces))
        fields.append(field)
    gmsh.model.addPhysicalGroup(0, points, 5, "antenna_centre")
    smallest = gmsh.model.mesh.field.add("Min")
    gmsh.model.mesh.field.setNumbers(smallest, "FieldsList", fields)
    gmsh.model.mesh.field.setAsBackgroundMesh(smallest)

    # Mesh and export
    gmsh.model.mesh.generate(2)
    gmsh.write(str(DATA_DIR / filename))
    n_nodes = len(gmsh.model.mesh.getNodes()[0])
    n_triangles = sum(len(tags) for tags in gmsh.model.mesh.getElements(2)[1])
    print(f"{filename}: {n_nodes} nodes, {n_triangles} triangles")


def main():
    DATA_DIR.mkdir(exist_ok=True)
    gmsh.initialize()
    gmsh.option.setNumber("General.Terminal", 0)
    gmsh.option.setNumber("Mesh.MeshSizeFromPoints", 0)
    gmsh.option.setNumber("Mesh.MeshSizeFromCurvature", 0)
    gmsh.option.setNumber("Mesh.MeshSizeExtendFromBoundary", 0)
    gmsh.option.setNumber("Mesh.Algorithm", 6)        # Frontal-Delaunay
    gmsh.option.setNumber("Mesh.ElementOrder", 1)     # linear triangles (P1)
    gmsh.option.setNumber("Mesh.MshFileVersion", 2.2)
    build_mesh("circular_domain_target.msh", N_DATA, with_target=True)
    build_mesh("circular_domain_operator.msh", N_OPERATOR, with_target=False)
    gmsh.finalize()


if __name__ == "__main__":
    main()
