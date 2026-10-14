function [delta_e, delta_t, cmd, mem] = longitudinal_autopilot(ref, state, P, mem)
%LONGITUDINAL_AUTOPILOT Pitch/altitude/airspeed autopilot loops.
%   ref fields:
%     altitude_c [m], Va_c [m/s], theta_c (optional), mode (optional)
%   modes:
%     'altitude_hold' (default): altitude->pitch, airspeed->throttle
%     'airspeed_pitch': airspeed->pitch, throttle fixed at trim

    if nargin < 4 || isempty(mem)
        mem.alt_int = 0;
        mem.alt_err_d1 = 0;
        mem.airspeed_t_int = 0;
        mem.airspeed_t_err_d1 = 0;
        mem.airspeed_p_int = 0;
        mem.airspeed_p_err_d1 = 0;
    end

    if ~isfield(ref, 'mode')
        ref.mode = 'altitude_hold';
    end

    Ts = P.Ts;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Pitch command generation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isfield(ref, 'theta_c')
        theta_c_unsat = ref.theta_c;

    elseif strcmpi(ref.mode, 'airspeed_pitch')
        Va_error = ref.Va_c - state.Va;
        mem.airspeed_p_int = mem.airspeed_p_int + 0.5*Ts*(Va_error + mem.airspeed_p_err_d1);

        % Positive Va error => command lower pitch (speed up)
        theta_corr = P.airspeed_pitch_kp*Va_error + P.airspeed_pitch_ki*mem.airspeed_p_int;
        theta_c_unsat = P.trim_theta - theta_corr;

        theta_c_tmp = saturate(theta_c_unsat, P.trim_theta - P.theta_max, P.trim_theta + P.theta_max);
        if abs(P.airspeed_pitch_ki) > 1e-8
            mem.airspeed_p_int = mem.airspeed_p_int + ...
                (Ts/P.airspeed_pitch_ki)*(theta_c_tmp - theta_c_unsat);
        end

        mem.airspeed_p_err_d1 = Va_error;

    else
        h_c = saturate(ref.altitude_c, state.h - P.altitude_zone, state.h + P.altitude_zone);
        h_error = h_c - state.h;
        mem.alt_int = mem.alt_int + 0.5*Ts*(h_error + mem.alt_err_d1);

        theta_corr = P.altitude_kp*h_error + P.altitude_ki*mem.alt_int;
        theta_c_unsat = P.trim_theta + theta_corr;

        theta_c_tmp = saturate(theta_c_unsat, P.trim_theta - P.theta_max, P.trim_theta + P.theta_max);
        if abs(P.altitude_ki) > 1e-8
            mem.alt_int = mem.alt_int + (Ts/P.altitude_ki)*(theta_c_tmp - theta_c_unsat);
        end
        mem.alt_err_d1 = h_error;
    end

    theta_c = saturate(theta_c_unsat, P.trim_theta - P.theta_max, P.trim_theta + P.theta_max);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Pitch --> elevator
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    delta_e_unsat = P.trim_delta_e + P.pitch_kp*(theta_c - state.theta) - P.pitch_kd*state.q;
    delta_e = saturate(delta_e_unsat, -P.delta_e_max, P.delta_e_max);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Airspeed --> throttle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmpi(ref.mode, 'airspeed_pitch')
        delta_t = P.trim_delta_t;
    else
        Va_error_t = ref.Va_c - state.Va;
        mem.airspeed_t_int = mem.airspeed_t_int + 0.5*Ts*(Va_error_t + mem.airspeed_t_err_d1);

        delta_t_unsat = P.trim_delta_t + P.airspeed_throttle_kp*Va_error_t + ...
            P.airspeed_throttle_ki*mem.airspeed_t_int;
        delta_t = saturate(delta_t_unsat, P.delta_t_min, P.delta_t_max);

        if abs(P.airspeed_throttle_ki) > 1e-8
            mem.airspeed_t_int = mem.airspeed_t_int + ...
                (Ts/P.airspeed_throttle_ki)*(delta_t - delta_t_unsat);
        end
        mem.airspeed_t_err_d1 = Va_error_t;
    end

    cmd = struct();
    cmd.theta_c = theta_c;
    cmd.altitude_c = ref.altitude_c;
    cmd.Va_c = ref.Va_c;
end

function out = saturate(in, low, high)
    out = min(max(in, low), high);
end
