function probeNodes = findProbeNodes(nodes, antennaPositions)
% FINDPROBENODES  Find the mesh node closest to each antenna position.
%
%   probeNodes = findProbeNodes(nodes, antennaPositions)
%
%   For each antenna, this function searches all mesh nodes and returns the
%   index of the node with the smallest Euclidean distance to that antenna.
%   These indices are later used to sample the FEM solution (e.g. electric
%   field) at the antenna locations.
%
%   Inputs
%   ------
%   nodes             : 2-by-N matrix of mesh node coordinates [x; y],
%                       where N is the total number of nodes in the mesh.
%
%   antennaPositions  : nAnt-by-2 matrix of antenna (x, y) coordinates,
%                       where nAnt is the number of antennas.
%
%   Output
%   ------
%   probeNodes        : nAnt-by-1 vector of node indices. probeNodes(k) is
%                       the index (column of 'nodes') of the mesh node
%                       nearest to antenna k.
%
%   Example
%   -------
%   % Suppose the mesh has already been created:
%   nodes = scenario.mesh.Nodes;           % 2-by-N
%   probeNodes = findProbeNodes(nodes, scenario.antennaPositions);
%
%   See also CREATESCENARIOMESH, PLOTGEOMETRY

nAnt = size(antennaPositions,1);

probeNodes = zeros(nAnt,1);

for k=1:nAnt

    xa = antennaPositions(k,1);
    ya = antennaPositions(k,2);

    dist2 = (nodes(1,:) - xa).^2 + ...
            (nodes(2,:) - ya).^2;

    [~,idx] = min(dist2);

    probeNodes(k) = idx;

end

end