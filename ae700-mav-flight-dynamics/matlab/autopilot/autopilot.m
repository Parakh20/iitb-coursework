function y = autopilot(u, AP)
%AUTOPILOT Simulink wrapper for chapter-6 architecture.
%   u  = [xhat(1:19); commands(20:22); t(23)]
%   AP = autopilot parameter struct
%
%   y  = [delta(4); x_command(12)]

    persistent lat_mem lon_mem

    % Estimated-state vector from true_states.m
    % [pn pe pd Va alpha beta phi theta psi chi p q r Vg wn we bx by bz]'
    xhat = u(1:19);
    t = u(23);

    mode = 'altitude_hold';
    if isfield(AP, 'longitudinal_mode') && ~isempty(AP.longitudinal_mode)
        mode = AP.longitudinal_mode;
    end

    cmd = struct();
    cmd.Va_c = u(20);
    cmd.altitude_c = u(21);
    cmd.course_c = u(22);
    cmd.beta_c = 0;

    if isfield(AP, 'use_ae700_command_profile') && AP.use_ae700_command_profile
        cmd = command_profile_ae700(t, AP, mode);
    end

    state = struct();
    state.phi = xhat(7);
    state.theta = xhat(8);
    state.psi = xhat(9);
    state.chi = xhat(10);
    state.p = xhat(11);
    state.q = xhat(12);
    state.r = xhat(13);
    state.h = -xhat(3);
    state.Va = xhat(4);
    state.beta = xhat(6);

    [delta_a, delta_r, lat_cmd, lat_mem] = lateral_autopilot( ...
        struct('course_c', cmd.course_c, 'beta_c', cmd.beta_c), state, AP, lat_mem);

    [delta_e, delta_t, lon_cmd, lon_mem] = longitudinal_autopilot( ...
        struct('altitude_c', cmd.altitude_c, 'Va_c', cmd.Va_c, 'mode', mode), ...
        state, AP, lon_mem);

    delta = [delta_e; delta_a; delta_r; delta_t];

    x_command = zeros(12, 1);
    x_command(3) = cmd.altitude_c;
    x_command(4) = cmd.Va_c;
    x_command(6) = cmd.beta_c;
    x_command(7) = lat_cmd.phi_c;
    x_command(8) = lon_cmd.theta_c;
    x_command(9) = cmd.course_c;

    y = [delta; x_command];
end

function cmd = command_profile_ae700(t, AP, mode)
    cmd = struct();

    h0 = 100;
    if isfield(AP, 'trim_altitude')
        h0 = AP.trim_altitude;
    end

    Va0 = 25;
    if isfield(AP, 'trim_Va')
        Va0 = AP.trim_Va;
    end

    cmd.course_c = 15*pi/180*(t >= 10) + (-10*pi/180)*(t >= 45);
    cmd.altitude_c = h0 + 10*(t >= 25) - 8*(t >= 60);
    cmd.Va_c = Va0 + 2*(t >= 45);
    cmd.beta_c = 0;

    if strcmpi(mode, 'airspeed_pitch')
        cmd.course_c = 0;
        cmd.altitude_c = h0;
        cmd.Va_c = Va0 + 3*(t >= 8);
    end
end
