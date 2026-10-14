function [out, air_data] = forces_moments(x, delta, wind, P)
%FORCES_MOMENTS Total forces/moments with gravity, aero, and propulsion.
%   x     = [pn pe pd u v w phi theta psi p q r]'
%   delta = [delta_e delta_a delta_r delta_t]'
%   wind  = [wn we wd u_g v_g w_g]'
%
%   Single-output call:
%     out = [Fx Fy Fz l m n Va alpha beta wn we wd]'
%
%   Two-output call (Simulink chapter-6 compatibility):
%     out      = [Fx Fy Fz l m n]'
%     air_data = [Va alpha beta]'

    x = x(:);
    delta = delta(:);
    wind = wind(:);

    if numel(x) ~= 12
        error('forces_moments:StateSize', 'x must be 12x1.');
    end
    if numel(delta) ~= 4
        error('forces_moments:ControlSize', 'delta must be 4x1.');
    end
    if numel(wind) ~= 6
        error('forces_moments:WindSize', 'wind must be 6x1.');
    end

    u = x(4);
    v = x(5);
    w = x(6);
    phi = x(7);
    theta = x(8);
    psi = x(9);
    p = x(10);
    q = x(11);
    r = x(12);

    wn = wind(1);
    we = wind(2);
    wd = wind(3);
    gust_b = wind(4:6);

    delta_t = delta(4);

    % Wind conversion and air-relative velocity
    R_bi = euler_to_rotation(phi, theta, psi);
    R_ib = R_bi.';

    steady_i = [wn; we; wd];
    wind_b = R_ib*steady_i + gust_b;
    v_air = [u; v; w] - wind_b;

    ur = v_air(1);
    vr = v_air(2);
    wr = v_air(3);

    Va = max(norm(v_air), 1e-6);
    alpha = atan2(wr, ur);
    beta = asin(max(min(vr/Va, 1.0), -1.0));

    % Gravity force in body frame
    fg = [
        -P.mass*P.gravity*sin(theta);
         P.mass*P.gravity*cos(theta)*sin(phi);
         P.mass*P.gravity*cos(theta)*cos(phi)
    ];

    % Aerodynamic contributions
    [F_aero, M_aero] = aero_model(Va, alpha, beta, [p; q; r], delta, P);

    % Propulsion contributions
    [thrust_prop, torque_prop] = propulsion_model(Va, delta_t, P);
    F_prop = [thrust_prop; 0; 0];
    M_prop = [torque_prop; 0; 0];

    F_total = fg + F_aero + F_prop;
    M_total = M_aero + M_prop;

    % Wind reported in inertial frame includes transformed gust component
    wind_i = steady_i + R_bi*gust_b;

    if nargout <= 1
        out = [F_total; M_total; Va; alpha; beta; wind_i];
    else
        out = [F_total; M_total];
        air_data = [Va; alpha; beta];
    end
end

function R = euler_to_rotation(phi, theta, psi)
%EULER_TO_ROTATION Rotation matrix from body to NED inertial coordinates.
    cphi = cos(phi);
    sphi = sin(phi);
    cth = cos(theta);
    sth = sin(theta);
    cpsi = cos(psi);
    spsi = sin(psi);

    R = [
        cth*cpsi,  sphi*sth*cpsi - cphi*spsi,  cphi*sth*cpsi + sphi*spsi;
        cth*spsi,  sphi*sth*spsi + cphi*cpsi,  cphi*sth*spsi - sphi*cpsi;
        -sth,      sphi*cth,                   cphi*cth
    ];
end
