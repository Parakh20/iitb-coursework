function [thrust_prop, torque_prop] = propulsion(Va, delta_t, P)
%PROPULSION Compatibility wrapper for propulsion model.
    [thrust_prop, torque_prop] = propulsion_model(Va, delta_t, P);
end
