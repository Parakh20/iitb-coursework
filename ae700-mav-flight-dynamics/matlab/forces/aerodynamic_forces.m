function [F_aero, M_aero, coeff] = aerodynamic_forces(Va, alpha, beta, rates, delta, P)
%AERODYNAMIC_FORCES Compatibility wrapper for aerodynamic model.
    [F_aero, M_aero, coeff] = aero_model(Va, alpha, beta, rates, delta, P);
end
