%% AE700 MAV simulation script
clear; clc; close all;

% Robustly locate AE700 project root even when MATLAB executes from /tmp.
script_file = mfilename('fullpath');
if isempty(script_file)
    script_file = which('run_simulation.m');
end
if isempty(script_file)
    script_file = which('run_simulation');
end

root = '';
if ~isempty(script_file)
    candidate_root = fileparts(fileparts(fileparts(script_file)));
    if isfile(fullfile(candidate_root, 'matlab', 'data', 'aircraft_parameters.m'))
        root = candidate_root;
    end
end

if isempty(root)
    root = locate_ae700_project_root(pwd);
end

if isempty(root)
    error('run_simulation:RootNotFound', ...
        ['Could not find AE700_Project root folder. ', ...
         'Please set current folder to AE700_Project/matlab/main and rerun.']);
end

addpath(genpath(fullfile(root, 'matlab')));
if isfolder(fullfile(root, 'simulink'))
    addpath(genpath(fullfile(root, 'simulink')));
end

P = aircraft_parameters();

% Trim for level flight
Va_trim = 25.0;
gamma_trim = 0.0;
R_trim = Inf;
[x_trim, u_trim, trim_info] = compute_trim(Va_trim, gamma_trim, R_trim, P); %#ok<NASGU>

P.trim_delta_e = u_trim(1);
P.trim_delta_a = u_trim(2);
P.trim_delta_r = u_trim(3);
P.trim_delta_t = u_trim(4);
P.trim_phi = x_trim(7);
P.trim_theta = x_trim(8);
P.trim_beta = 0;
P.trim_altitude = -x_trim(3);
P.trim_Va = Va_trim;

fprintf('Trim state (x_trim):\n');
disp(x_trim.');
fprintf('Trim input (u_trim):\n');
disp(u_trim.');

% Verify trim consistency with open-loop hold
trim_drift = verify_trim_hold(P, x_trim, u_trim, 15.0);
fprintf('Trim hold drift over %.1f s: |dphi|=%.3f deg, |dtheta|=%.3f deg, |dh|=%.3f m, |dVa|=%.3f m/s\n', ...
    trim_drift.T, trim_drift.dphi_deg, trim_drift.dtheta_deg, trim_drift.dh, trim_drift.dVa);

% Linearization around trim
[A, B, C, D] = linearize_model(x_trim, u_trim, P); %#ok<ASGLU>
fprintf('Linear model dimensions: A(%dx%d), B(%dx%d), C(%dx%d), D(%dx%d)\n', ...
    size(A,1), size(A,2), size(B,1), size(B,2), size(C,1), size(C,2), size(D,1), size(D,2));

% Closed-loop nonlinear simulation with steady NED + Dryden gusts
T_end = 80;
t = 0:P.Ts:T_end;
wind_cfg = struct('enable_gust', P.wind_enable_gust, ...
                  'seed', P.wind_seed, ...
                  'Ts', P.Ts, ...
                  'gust_scale', P.wind_gust_scale);
assignin('base', 'wind_cfg', wind_cfg);
logs = simulate_closed_loop(P, x_trim, t, wind_cfg, 'altitude_hold');

% Additional run for airspeed hold using pitch
t_ap = 0:P.Ts:35;
logs_ap = simulate_closed_loop(P, x_trim, t_ap, wind_cfg, 'airspeed_pitch');

% Required report plots
plot_required_responses(logs);
plot_airspeed_pitch_mode(logs_ap);
plot_control_inputs(logs);

results_dir = fullfile(root, 'results');
if ~isfolder(results_dir)
    mkdir(results_dir);
end
save(fullfile(results_dir, 'ae700_results.mat'), ...
    'logs', 'logs_ap', 'x_trim', 'u_trim', 'trim_info', 'A', 'B', 'C', 'D', 'P');
fprintf('Saved results to %s\n', fullfile(results_dir, 'ae700_results.mat'));

function drift = verify_trim_hold(P, x_trim, u_trim, T)
    dt = P.Ts;
    N = floor(T/dt);
    x = x_trim;

    trim_wind_cfg = struct('enable_gust', false, 'Ts', dt);

    for k = 1:N
        trim_wind_cfg.reset = (k == 1);
        wind = gust_model((k-1)*dt, P, trim_wind_cfg);

        k1 = local_dyn(x, u_trim, wind, P);
        k2 = local_dyn(x + 0.5*dt*k1, u_trim, wind, P);
        k3 = local_dyn(x + 0.5*dt*k2, u_trim, wind, P);
        k4 = local_dyn(x + dt*k3, u_trim, wind, P);
        x = x + dt*(k1 + 2*k2 + 2*k3 + k4)/6;
        x(9) = wrap_to_pi_local(x(9));
    end

    wind_ref = [P.wind_steady_n; P.wind_steady_e; P.wind_steady_d; 0; 0; 0];
    fm0 = forces_moments(x_trim, u_trim, wind_ref, P);
    fmf = forces_moments(x, u_trim, wind_ref, P);

    drift.T = T;
    drift.dphi_deg = abs(rad2deg(x(7) - x_trim(7)));
    drift.dtheta_deg = abs(rad2deg(x(8) - x_trim(8)));
    drift.dh = abs((-x(3)) - (-x_trim(3)));
    drift.dVa = abs(fmf(7) - fm0(7));
end

function xdot = local_dyn(x, delta, wind, P)
    fm = forces_moments(x, delta, wind, P);
    xdot = eom_6dof(x, fm(1:6), P);
end

function a = wrap_to_pi_local(a)
    while a > pi
        a = a - 2*pi;
    end
    while a < -pi
        a = a + 2*pi;
    end
end

function plot_required_responses(logs)
    t = logs.t;
    phi = logs.x(:,7);
    theta = logs.x(:,8);
    chi = logs.chi;
    h = -logs.x(:,3);

    figure('Name', 'AE700 Required Tracking Plots', 'Color', 'w');

    subplot(3,2,1);
    plot(t, rad2deg(phi), 'b', 'LineWidth', 1.4); hold on;
    plot(t, rad2deg(logs.phi_c), 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('\phi [deg]');
    title('Roll vs Commanded Roll'); legend('Roll', 'Command');

    subplot(3,2,2);
    plot(t, rad2deg(chi), 'b', 'LineWidth', 1.4); hold on;
    plot(t, rad2deg(logs.course_c), 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('\chi [deg]');
    title('Course vs Commanded Course'); legend('Course', 'Command');

    subplot(3,2,3);
    plot(t, rad2deg(theta), 'b', 'LineWidth', 1.4); hold on;
    plot(t, rad2deg(logs.theta_c), 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('\theta [deg]');
    title('Pitch vs Commanded Pitch'); legend('Pitch', 'Command');

    subplot(3,2,4);
    plot(t, h, 'b', 'LineWidth', 1.4); hold on;
    plot(t, logs.altitude_c, 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('Altitude [m]');
    title('Altitude vs Commanded Altitude'); legend('Altitude', 'Command');

    subplot(3,2,5);
    plot(t, logs.Va, 'b', 'LineWidth', 1.4); hold on;
    plot(t, logs.Va_c, 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('V_a [m/s]');
    title('Airspeed vs Commanded Airspeed (Throttle)'); legend('Airspeed', 'Command');

    subplot(3,2,6);
    plot(t, logs.beta, 'b', 'LineWidth', 1.4); hold on;
    yline(0, 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('\beta [rad]');
    title('Sideslip vs Commanded Sideslip'); legend('Sideslip', 'Command');
end

function plot_airspeed_pitch_mode(logs)
    t = logs.t;
    figure('Name', 'Airspeed Hold via Pitch Command', 'Color', 'w');
    plot(t, logs.Va, 'b', 'LineWidth', 1.4); hold on;
    plot(t, logs.Va_c, 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('V_a [m/s]');
    title('Airspeed vs Commanded Airspeed (Pitch Mode)');
    legend('Airspeed', 'Command');
end

function plot_control_inputs(logs)
    t = logs.t;
    delta = logs.delta;

    figure('Name', 'Control Inputs', 'Color', 'w');
    subplot(4,1,1);
    plot(t, rad2deg(delta(:,1)), 'LineWidth', 1.2); grid on;
    ylabel('\delta_e [deg]'); title('Control Inputs');

    subplot(4,1,2);
    plot(t, rad2deg(delta(:,2)), 'LineWidth', 1.2); grid on;
    ylabel('\delta_a [deg]');

    subplot(4,1,3);
    plot(t, rad2deg(delta(:,3)), 'LineWidth', 1.2); grid on;
    ylabel('\delta_r [deg]');

    subplot(4,1,4);
    plot(t, delta(:,4), 'LineWidth', 1.2); grid on;
    ylabel('\delta_t [-]'); xlabel('Time [s]');
end

function root = locate_ae700_project_root(start_dir)
    root = '';
    d = start_dir;

    for k = 1:12
        % Case 1: current folder is AE700_Project
        if isfile(fullfile(d, 'matlab', 'main', 'run_simulation.m')) && ...
           isfile(fullfile(d, 'matlab', 'data', 'aircraft_parameters.m'))
            root = d;
            return;
        end

        % Case 2: current folder is repository root containing AE700_Project
        ae = fullfile(d, 'AE700_Project');
        if isfile(fullfile(ae, 'matlab', 'main', 'run_simulation.m')) && ...
           isfile(fullfile(ae, 'matlab', 'data', 'aircraft_parameters.m'))
            root = ae;
            return;
        end

        parent = fileparts(d);
        if strcmp(parent, d)
            break;
        end
        d = parent;
    end

    % Machine-local fallback
    default_root = '/home/parakh/Desktop/AE700_PROJECT/AE700_Project';
    if isfile(fullfile(default_root, 'matlab', 'main', 'run_simulation.m'))
        root = default_root;
    end
end
