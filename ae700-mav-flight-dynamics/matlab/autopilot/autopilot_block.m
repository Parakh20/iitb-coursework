function y = autopilot_block(u)
%AUTOPILOT_BLOCK Simulink wrapper with persistent controller states.
%   u = [course_c altitude_c Va_c beta_c state(12)]
%   y = [delta_e delta_a delta_r delta_t phi_c theta_c]

    persistent lat_mem lon_mem

    P = evalin('base', 'P');

    cmd = struct();
    cmd.course_c = u(1);
    cmd.altitude_c = u(2);
    cmd.Va_c = u(3);
    cmd.beta_c = u(4);

    if numel(u) < 16
        error('autopilot_block:InputSize', ...
            'Expected input vector length >=16 ([4 commands + 12 states]), got %d.', numel(u));
    end

    x = u(5:16);

    state = struct();
    state.phi = x(7);
    state.theta = x(8);
    state.psi = x(9);
    state.p = x(10);
    state.q = x(11);
    state.r = x(12);
    state.h = -x(3);

    fm_tmp = forces_moments(x, [P.trim_delta_e; P.trim_delta_a; P.trim_delta_r; P.trim_delta_t], zeros(6, 1), P);
    state.Va = fm_tmp(7);
    state.beta = fm_tmp(9);
    state.chi = compute_chi(x);

    [delta_a, delta_r, lat_cmd, lat_mem] = lateral_autopilot( ...
        struct('course_c', cmd.course_c, 'beta_c', cmd.beta_c), state, P, lat_mem);

    [delta_e, delta_t, lon_cmd, lon_mem] = longitudinal_autopilot( ...
        struct('altitude_c', cmd.altitude_c, 'Va_c', cmd.Va_c, 'mode', 'altitude_hold'), ...
        state, P, lon_mem);

    y = [delta_e; delta_a; delta_r; delta_t; lat_cmd.phi_c; lon_cmd.theta_c];
end

function chi = compute_chi(x)
    u = x(4);
    v = x(5);
    w = x(6);
    phi = x(7);
    theta = x(8);
    psi = x(9);

    cphi = cos(phi);
    sphi = sin(phi);
    cth = cos(theta);
    sth = sin(theta);
    cpsi = cos(psi);
    spsi = sin(psi);

    Rbi = [
        cth*cpsi, sphi*sth*cpsi-cphi*spsi, cphi*sth*cpsi+sphi*spsi;
        cth*spsi, sphi*sth*spsi+cphi*cpsi, cphi*sth*spsi-sphi*cpsi;
        -sth, sphi*cth, cphi*cth
    ];

    Vi = Rbi*[u; v; w];
    chi = atan2(Vi(2), Vi(1));
end
