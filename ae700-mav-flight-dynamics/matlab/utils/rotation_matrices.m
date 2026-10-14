function [R_bi, R_ib] = rotation_matrices(phi, theta, psi)
%ROTATION_MATRICES Body-to-inertial and inertial-to-body rotation matrices.

    cphi = cos(phi);
    sphi = sin(phi);
    cth = cos(theta);
    sth = sin(theta);
    cpsi = cos(psi);
    spsi = sin(psi);

    R_bi = [
        cth*cpsi,  sphi*sth*cpsi - cphi*spsi,  cphi*sth*cpsi + sphi*spsi;
        cth*spsi,  sphi*sth*spsi + cphi*cpsi,  cphi*sth*spsi - sphi*cpsi;
        -sth,      sphi*cth,                   cphi*cth
    ];

    R_ib = R_bi.';
end
