function fg = gravity(phi, theta, P)
%GRAVITY Gravity force vector in body coordinates.
    fg = [
        -P.mass*P.gravity*sin(theta);
         P.mass*P.gravity*cos(theta)*sin(phi);
         P.mass*P.gravity*cos(theta)*cos(phi)
    ];
end
