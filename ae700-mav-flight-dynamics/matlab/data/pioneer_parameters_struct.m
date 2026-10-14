function P = pioneer_parameters_struct()
%PIONEER_PARAMETERS_STRUCT Baseline AE700 parameter struct (no side effects).

    % Initial conditions (overwritten by trim in Simulink init script)
    P.pn0 = 0;
    P.pe0 = 0;
    P.pd0 = -100;
    P.u0 = 25;
    P.v0 = 0;
    P.w0 = 0;
    P.phi0 = 0;
    P.theta0 = 0;
    P.psi0 = 0;
    P.p0 = 0;
    P.q0 = 0;
    P.r0 = 0;

    % Physical parameters
    P.gravity = 9.81;
    % Bray / Selig data converted from imperial to SI units.
    P.mass = 190.5087954;          % 420 lbm
    P.Jx = 47.225850785319544;     % 34.832 slug-ft^2
    P.Jy = 90.9482679914801;       % 67.08 slug-ft^2
    P.Jz = 111.4753517331469;      % 82.22 slug-ft^2
    P.Jxz = -6.646219583992776;    % -4.902 slug-ft^2

    P.S_wing = 2.8261104768;       % 30.42 ft^2
    P.b = 5.15112;                 % 16.90 ft
    P.c = 0.54864;                 % 1.80 ft
    P.S_prop = 0.430;
    P.rho = 1.225;
    P.e_oswald = 0.9;
    P.AR = P.b^2/P.S_wing;

    % Longitudinal aero coefficients
    P.CL0 = 0.385;
    P.CLa = 4.78;
    P.CD0 = 0.060;
    P.CDa = 0.430;
    P.Cm0 = 0.194;
    P.Cma = -2.12;
    P.Cm_adot = -11.0;
    P.Cmq = -36.6;
    P.Cmde = -1.76;
    P.CL_adot = 2.42;
    P.CLq = 8.05;
    P.CDq = 0.0;
    P.CLde = 0.401;
    P.CDde = 0.0180;
    P.CD_p = 0.0;
    P.M = 50.0;
    P.alpha0 = 0.47;
    P.alpha_zero_lift = 0.0;
    P.epsilon = 0.16;

    % Lateral-directional coefficients
    P.CY0 = 0.0;
    P.CYb = -0.819;
    P.CYp = 0.0;
    P.CYr = 0.0;
    P.CYda = 0.0;
    P.CYdr = 0.191;

    P.Cl0 = 0.0;
    P.Clb = -0.023;
    P.Clp = -0.450;
    P.Clr = 0.265;
    P.Clda = -0.161;
    P.Cldr = -0.00229;

    P.Cn0 = 0.0;
    P.Cnb = 0.109;
    P.Cnp = -0.110;
    P.Cnr = -0.200;
    P.Cnda = 0.0200;
    P.Cndr = -0.0917;

    % Propulsion
    P.C_prop = 1.0;
    P.k_motor = 200;
    P.k_T_P = 0.0;
    P.k_omega = 1.0;

    % Wind/gust parameters
    P.wind_steady_n = 0.0;
    P.wind_steady_e = 0.0;
    P.wind_steady_d = 0.0;
    P.L_u = 200.0;
    P.L_v = 200.0;
    P.L_w = 50.0;
    P.sigma_u = 1.06;
    P.sigma_v = 1.06;
    P.sigma_w = 0.70;
    P.wind_Va0 = P.u0;
    P.wind_enable_gust = true;
    P.wind_seed = 7;
    P.wind_gust_scale = 1.0;

    % Actuator limits and default trim
    P.delta_e_max = 20*pi/180;
    P.delta_a_max = 20*pi/180;
    P.delta_r_max = 20*pi/180;
    P.delta_t_min = 0.0;
    P.delta_t_max = 1.0;
    P.trim_delta_e = 0.0;
    P.trim_delta_a = 0.0;
    P.trim_delta_r = 0.0;
    P.trim_delta_t = 0.5;
    P.trim_phi = 0.0;
    P.trim_theta = 0.0;
    P.trim_beta = 0.0;

    % Controller gains
    P.Ts = 0.01;
    P.roll_kp = -4.0;
    P.roll_kd = -1.8;
    P.course_kp = 0.45;
    P.course_ki = 0.06;
    P.sideslip_kp = 2.0;
    P.sideslip_ki = 0.50;
    P.sideslip_kd = 0.25;
    P.pitch_kp = -7.0;
    P.pitch_kd = -3.0;
    P.altitude_kp = 0.008;
    P.altitude_ki = 0.002;
    P.altitude_zone = 12.0;
    P.airspeed_throttle_kp = 0.10;
    P.airspeed_throttle_ki = 0.04;
    P.airspeed_pitch_kp = 0.08;
    P.airspeed_pitch_ki = 0.015;
    P.phi_max = 30*pi/180;
    P.theta_max = 20*pi/180;

    % Inertia coupling constants
    P = update_inertia_gammas(P);
end

function P = update_inertia_gammas(P)
    P.Gamma = P.Jx*P.Jz - P.Jxz^2;
    P.Gamma1 = (P.Jxz*(P.Jx - P.Jy + P.Jz))/P.Gamma;
    P.Gamma2 = (P.Jz*(P.Jz - P.Jy) + P.Jxz^2)/P.Gamma;
    P.Gamma3 = P.Jz/P.Gamma;
    P.Gamma4 = P.Jxz/P.Gamma;
    P.Gamma5 = (P.Jz - P.Jx)/P.Jy;
    P.Gamma6 = P.Jxz/P.Jy;
    P.Gamma7 = (P.Jx*(P.Jx - P.Jy) + P.Jxz^2)/P.Gamma;
    P.Gamma8 = P.Jx/P.Gamma;
end
