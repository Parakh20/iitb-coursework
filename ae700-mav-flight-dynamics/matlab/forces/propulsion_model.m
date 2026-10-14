function [thrust_prop, torque_prop] = propulsion_model(Va, delta_t, P)
%PROPULSION_MODEL Simplified propeller thrust and roll torque model.

    delta_t = min(max(delta_t, P.delta_t_min), P.delta_t_max);

    thrust_prop = 0.5 * P.rho * P.S_prop * P.C_prop * ((P.k_motor*delta_t)^2 - Va^2);
    torque_prop = -P.k_T_P * (P.k_omega*delta_t)^2;
end
