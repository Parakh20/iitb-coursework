function x0 = initial_conditions(P)
%INITIAL_CONDITIONS Return the 12-state initial condition vector.

    if nargin < 1 || isempty(P)
        P = aircraft_parameters();
    end

    x0 = [
        P.pn0;
        P.pe0;
        P.pd0;
        P.u0;
        P.v0;
        P.w0;
        P.phi0;
        P.theta0;
        P.psi0;
        P.p0;
        P.q0;
        P.r0
    ];
end
