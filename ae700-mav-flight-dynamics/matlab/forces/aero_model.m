function [F_aero, M_aero, coeff] = aero_model(Va, alpha, beta, rates, delta, P)
%AERO_MODEL Aerodynamic force and moment model in body frame.
%   rates = [p q r]'
%   delta = [delta_e delta_a delta_r delta_t]'

    p = rates(1);
    q = rates(2);
    r = rates(3);

    delta_e = delta(1);
    delta_a = delta(2);
    delta_r = delta(3);

    Va_eff = max(Va, 0.1);
    qbar = 0.5 * P.rho * Va_eff^2;

    % Nonlinear lift blending function (post-stall model)
    sigma_num = (1 + exp(-P.M*(alpha - P.alpha0)) + exp(P.M*(alpha + P.alpha0)));
    sigma_den = (1 + exp(-P.M*(alpha - P.alpha0))) * (1 + exp(P.M*(alpha + P.alpha0)));
    sigma = sigma_num/sigma_den;

    CL_linear = P.CL0 + P.CLa*alpha;
    CL_nonlinear = 2*sign(alpha)*(sin(alpha)^2)*cos(alpha);
    CL = (1 - sigma)*CL_linear + sigma*CL_nonlinear;

    CD = P.CD_p + (CL_linear^2)/(pi*P.e_oswald*P.AR) + P.CD0 + P.CDa*alpha;

    Cx = -CD*cos(alpha) + CL*sin(alpha);
    Cxq = -P.CDq*cos(alpha) + P.CLq*sin(alpha);
    Cxde = -P.CDde*cos(alpha) + P.CLde*sin(alpha);

    Cz = -CD*sin(alpha) - CL*cos(alpha);
    Czq = -P.CDq*sin(alpha) - P.CLq*cos(alpha);
    Czde = -P.CDde*sin(alpha) - P.CLde*cos(alpha);

    Fx = qbar*P.S_wing * (Cx + Cxq*(P.c/(2*Va_eff))*q + Cxde*delta_e);
    Fy = qbar*P.S_wing * (P.CY0 + P.CYb*beta + P.CYp*(P.b/(2*Va_eff))*p ...
        + P.CYr*(P.b/(2*Va_eff))*r + P.CYda*delta_a + P.CYdr*delta_r);
    Fz = qbar*P.S_wing * (Cz + Czq*(P.c/(2*Va_eff))*q + Czde*delta_e);

    ell = qbar*P.S_wing*P.b * (P.Cl0 + P.Clb*beta + P.Clp*(P.b/(2*Va_eff))*p ...
        + P.Clr*(P.b/(2*Va_eff))*r + P.Clda*delta_a + P.Cldr*delta_r);
    m = qbar*P.S_wing*P.c * (P.Cm0 + P.Cma*alpha + P.Cmq*(P.c/(2*Va_eff))*q ...
        + P.Cmde*delta_e);
    n = qbar*P.S_wing*P.b * (P.Cn0 + P.Cnb*beta + P.Cnp*(P.b/(2*Va_eff))*p ...
        + P.Cnr*(P.b/(2*Va_eff))*r + P.Cnda*delta_a + P.Cndr*delta_r);

    F_aero = [Fx; Fy; Fz];
    M_aero = [ell; m; n];

    if nargout > 2
        coeff.CL = CL;
        coeff.CD = CD;
        coeff.sigma = sigma;
        coeff.Cx = Cx;
        coeff.Cz = Cz;
    end
end
