function V = aircraft_vertices(scale)
%AIRCRAFT_VERTICES Vertex list for the detailed Pioneer-style mesh.

    if nargin < 1
        scale = 1.0;
    end

    [V, ~, ~] = aircraft_mesh(scale);
end
