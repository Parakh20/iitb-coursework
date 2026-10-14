function logs = simulate_closed_loop(P, x0, t, wind_cfg, mode)
%SIMULATE_CLOSED_LOOP Run closed-loop nonlinear simulation.
%   Uses steady NED + Dryden gust wind model via gust_model().

    if nargin < 4 || isempty(wind_cfg)
        wind_cfg = struct();
    end
    if nargin < 5
        mode = 'altitude_hold';
    end

    x = x0(:);
    n = numel(t);

    logs.t = t(:);
    logs.x = zeros(n, 12);
    logs.delta = zeros(n, 4);
    logs.wind = zeros(n, 6);
    logs.Va = zeros(n, 1);
    logs.alpha = zeros(n, 1);
    logs.beta = zeros(n, 1);
    logs.chi = zeros(n, 1);
    logs.phi_c = zeros(n, 1);
    logs.theta_c = zeros(n, 1);
    logs.course_c = zeros(n, 1);
    logs.altitude_c = zeros(n, 1);
    logs.Va_c = zeros(n, 1);

    lat_mem = [];
    lon_mem = [];

    for k = 1:n
        tk = t(k);

        cmd = command_profile(tk, P, mode);

        wind_cfg_k = wind_cfg;
        if k == 1
            wind_cfg_k.reset = true;
        end
        wind_k = gust_model(tk, P, wind_cfg_k);

        fm_tmp = forces_moments(x, [P.trim_delta_e; P.trim_delta_a; P.trim_delta_r; P.trim_delta_t], wind_k, P);

        state = struct();
        state.phi = x(7);
        state.theta = x(8);
        state.psi = x(9);
        state.p = x(10);
        state.q = x(11);
        state.r = x(12);
        [state.chi, ~, ~] = course_from_state(x, wind_k);
        state.h = -x(3);
        state.Va = fm_tmp(7);
        state.beta = fm_tmp(9);

        [delta_a, delta_r, lat_cmd, lat_mem] = lateral_autopilot( ...
            struct('course_c', cmd.course_c, 'beta_c', cmd.beta_c), state, P, lat_mem);

        [delta_e, delta_t, lon_cmd, lon_mem] = longitudinal_autopilot( ...
            struct('altitude_c', cmd.altitude_c, 'Va_c', cmd.Va_c, 'mode', mode), state, P, lon_mem);

        delta = [delta_e; delta_a; delta_r; delta_t];

        x = rk4_step(x, delta, wind_k, P, P.Ts);
        x(9) = wrap_pi(x(9));

        fm = forces_moments(x, delta, wind_k, P);
        [chi_k, ~, ~] = course_from_state(x, wind_k);

        logs.x(k, :) = x.';
        logs.delta(k, :) = delta.';
        logs.wind(k, :) = wind_k.';
        logs.Va(k) = fm(7);
        logs.alpha(k) = fm(8);
        logs.beta(k) = fm(9);
        logs.chi(k) = chi_k;
        logs.phi_c(k) = lat_cmd.phi_c;
        logs.theta_c(k) = lon_cmd.theta_c;
        logs.course_c(k) = lat_cmd.course_c;
        logs.altitude_c(k) = lon_cmd.altitude_c;
        logs.Va_c(k) = lon_cmd.Va_c;

        if strcmpi(mode, 'altitude_hold') && mod(k, 10) == 1
            draw_aircraft(x, tk);
        end
    end
end

function cmd = command_profile(t, P, mode)
    cmd = struct();

    h0 = 100;
    if isfield(P, 'trim_altitude')
        h0 = P.trim_altitude;
    end
    Va0 = P.u0;
    if isfield(P, 'trim_Va')
        Va0 = P.trim_Va;
    end

    % Moderate command steps to stay in the linear operating region
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

function x_next = rk4_step(x, delta, wind, P, dt)
    k1 = local_dyn(x, delta, wind, P);
    k2 = local_dyn(x + 0.5*dt*k1, delta, wind, P);
    k3 = local_dyn(x + 0.5*dt*k2, delta, wind, P);
    k4 = local_dyn(x + dt*k3, delta, wind, P);
    x_next = x + dt*(k1 + 2*k2 + 2*k3 + k4)/6;
end

function xdot = local_dyn(x, delta, wind, P)
    fm = forces_moments(x, delta, wind, P);
    xdot = eom_6dof(x, fm(1:6), P);
end

function [chi, Vn, Ve] = course_from_state(x, wind)
    u = x(4); v = x(5); w = x(6);
    phi = x(7); theta = x(8); psi = x(9);
    wn = wind(1); we = wind(2);

    cphi = cos(phi); sphi = sin(phi);
    cth = cos(theta); sth = sin(theta);
    cpsi = cos(psi); spsi = sin(psi);

    Rbi = [
        cth*cpsi,  sphi*sth*cpsi - cphi*spsi,  cphi*sth*cpsi + sphi*spsi;
        cth*spsi,  sphi*sth*spsi + cphi*cpsi,  cphi*sth*spsi - sphi*cpsi;
        -sth,      sphi*cth,                   cphi*cth
    ];

    Vi = Rbi*[u; v; w] + [wn; we; wind(3)];
    Vn = Vi(1);
    Ve = Vi(2);
    chi = atan2(Ve, Vn);
end

function ang = wrap_pi(ang)
    while ang > pi
        ang = ang - 2*pi;
    end
    while ang < -pi
        ang = ang + 2*pi;
    end
end
