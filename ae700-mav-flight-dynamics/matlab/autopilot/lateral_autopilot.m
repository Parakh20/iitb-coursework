function [delta_a, delta_r, cmd, mem] = lateral_autopilot(ref, state, P, mem)
%LATERAL_AUTOPILOT Course/roll/sideslip autopilot loops.
%   ref fields: course_c [rad], beta_c [rad] (optional)
%   state fields: phi, p, chi, beta, r

    if nargin < 4 || isempty(mem)
        mem.course_int = 0;
        mem.course_err_d1 = 0;
        mem.beta_int = 0;
        mem.beta_err_d1 = 0;
    end

    if ~isfield(ref, 'beta_c')
        ref.beta_c = P.trim_beta;
    end
    Ts = P.Ts;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Course --> roll command
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    chi_ref = wrap_angle(ref.course_c, state.chi);
    chi_error = chi_ref - state.chi;
    mem.course_int = mem.course_int + 0.5*Ts*(chi_error + mem.course_err_d1);

    phi_c_unsat = P.trim_phi + P.course_kp*chi_error + P.course_ki*mem.course_int;
    phi_c = saturate(phi_c_unsat, P.trim_phi - P.phi_max, P.trim_phi + P.phi_max);

    if abs(P.course_ki) > 1e-8
        mem.course_int = mem.course_int + (Ts/P.course_ki)*(phi_c - phi_c_unsat);
    end

    mem.course_err_d1 = chi_error;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Roll --> aileron command
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    delta_a_unsat = P.trim_delta_a + P.roll_kp*(phi_c - state.phi) - P.roll_kd*state.p;
    delta_a = saturate(delta_a_unsat, -P.delta_a_max, P.delta_a_max);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Sideslip --> rudder command
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    beta_error = ref.beta_c - state.beta;
    mem.beta_int = mem.beta_int + 0.5*Ts*(beta_error + mem.beta_err_d1);

    % Match the AE700 reference controller: use a PI sideslip loop.
    % A direct yaw-rate term here is not part of the chapter-6 rudder loop
    % and can excite dutch-roll oscillations with this sign convention.
    delta_r_unsat = P.trim_delta_r + P.sideslip_kp*beta_error + ...
        P.sideslip_ki*mem.beta_int;
    delta_r = saturate(delta_r_unsat, -P.delta_r_max, P.delta_r_max);

    if abs(P.sideslip_ki) > 1e-8
        mem.beta_int = mem.beta_int + (Ts/P.sideslip_ki)*(delta_r - delta_r_unsat);
    end

    mem.beta_err_d1 = beta_error;

    cmd = struct();
    cmd.phi_c = phi_c;
    cmd.course_c = ref.course_c;
    cmd.beta_c = ref.beta_c;
end

function out = saturate(in, low, high)
    out = min(max(in, low), high);
end

function wrapped = wrap_angle(ang, ref)
%WRAP_ANGLE Wrap angle to be within +/- pi of reference.
    wrapped = ang;
    while wrapped - ref > pi
        wrapped = wrapped - 2*pi;
    end
    while wrapped - ref < -pi
        wrapped = wrapped + 2*pi;
    end
end
