function xdot = eom_6dof(x, fm, P)
%EOM_6DOF 6-DOF rigid-body equations using Euler-angle states.
%   x  = [pn pe pd u v w phi theta psi p q r]'
%   fm = [Fx Fy Fz l m n]'
%   P  = aircraft parameter struct
%
% Equations follow Beard & McLain Eqs. 3.14-3.17.

    if numel(x) ~= 12
        error('eom_6dof:StateSize', 'State vector must have 12 elements.');
    end
    if numel(fm) ~= 6
        error('eom_6dof:InputSize', 'Forces/moments vector must have 6 elements.');
    end

    x = x(:);
    fm = fm(:);

    pn = x(1);
    pe = x(2);
    pd = x(3);
    u = x(4);
    v = x(5);
    w = x(6);
    phi = x(7);
    theta = x(8);
    psi = x(9);
    p = x(10);
    q = x(11);
    r = x(12);

    Fx = fm(1);
    Fy = fm(2);
    Fz = fm(3);
    ell = fm(4);
    m = fm(5);
    n = fm(6);

    % Trigonometric short-hands
    cphi = cos(phi);   sphi = sin(phi);
    cth = cos(theta);  sth = sin(theta);
    cpsi = cos(psi);   spsi = sin(psi);

    % Protect the Euler kinematics near pitch singularity
    cth_safe = sign(cth)*max(abs(cth), 1e-6);
    tth = sth/cth_safe;

    % Inertial position kinematics (body velocities projected to NED)
    pndot = cth*cpsi*u + (sphi*sth*cpsi - cphi*spsi)*v + (cphi*sth*cpsi + sphi*spsi)*w;
    pedot = cth*spsi*u + (sphi*sth*spsi + cphi*cpsi)*v + (cphi*sth*spsi - sphi*cpsi)*w;
    pddot = -sth*u + sphi*cth*v + cphi*cth*w;

    % Body translational dynamics
    udot = r*v - q*w + Fx/P.mass;
    vdot = p*w - r*u + Fy/P.mass;
    wdot = q*u - p*v + Fz/P.mass;

    % Euler-angle kinematics
    phidot = p + q*sphi*tth + r*cphi*tth;
    thetadot = q*cphi - r*sphi;
    psidot = q*sphi/cth_safe + r*cphi/cth_safe;

    % Rotational dynamics with nonzero Jxz
    [Gamma1, Gamma2, Gamma3, Gamma4, Gamma5, Gamma6, Gamma7, Gamma8] = gamma_terms(P);

    pdot = Gamma1*p*q - Gamma2*q*r + Gamma3*ell + Gamma4*n;
    qdot = Gamma5*p*r - Gamma6*(p^2 - r^2) + m/P.Jy;
    rdot = Gamma7*p*q - Gamma1*q*r + Gamma4*ell + Gamma8*n;

    xdot = [pndot; pedot; pddot; udot; vdot; wdot; phidot; thetadot; psidot; pdot; qdot; rdot];
end

function [Gamma1, Gamma2, Gamma3, Gamma4, Gamma5, Gamma6, Gamma7, Gamma8] = gamma_terms(P)
    if isfield(P, 'Gamma1')
        Gamma1 = P.Gamma1;
        Gamma2 = P.Gamma2;
        Gamma3 = P.Gamma3;
        Gamma4 = P.Gamma4;
        Gamma5 = P.Gamma5;
        Gamma6 = P.Gamma6;
        Gamma7 = P.Gamma7;
        Gamma8 = P.Gamma8;
    else
        Gamma = P.Jx*P.Jz - P.Jxz^2;
        Gamma1 = (P.Jxz*(P.Jx - P.Jy + P.Jz))/Gamma;
        Gamma2 = (P.Jz*(P.Jz - P.Jy) + P.Jxz^2)/Gamma;
        Gamma3 = P.Jz/Gamma;
        Gamma4 = P.Jxz/Gamma;
        Gamma5 = (P.Jz - P.Jx)/P.Jy;
        Gamma6 = P.Jxz/P.Jy;
        Gamma7 = (P.Jx*(P.Jx - P.Jy) + P.Jxz^2)/Gamma;
        Gamma8 = P.Jx/Gamma;
    end
end
