function probeNodes = findProbeNodes(nodes, antennaPositions)

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