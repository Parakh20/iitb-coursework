%% Simulink chapter-6 runner with AE700-equivalent plots
clear; clc; close all;
bdclose('all');

script_file = mfilename('fullpath');
if isempty(script_file)
    script_file = which('run_simulation_simulink.m');
end
if isempty(script_file)
    error('run_simulation_simulink:ScriptPathUnknown', ...
        'Could not locate run_simulation_simulink.m');
end
addpath(fileparts(script_file));

cfg = init_params();

mdl = 'mavsim_autopilot';
T_end = 80;    % match the AE700 required tracking window
T_ap = 35;     % match the AE700 airspeed-via-pitch window

logs = run_case(mdl, T_end, 'altitude_hold', cfg);
logs_ap = run_case(mdl, T_ap, 'airspeed_pitch', cfg);

plot_required_responses(logs);
plot_airspeed_pitch_mode(logs_ap);
plot_control_inputs(logs);

out_file = fullfile(cfg.project_root, 'results', 'autopilot_results_simulink.mat');
save(out_file, 'logs', 'logs_ap');
fprintf('Saved results to %s\n', out_file);

function logs = run_case(mdl, T_end, mode, cfg)
    % Reset base-workspace params from init script and set mode for autopilot
    clear autopilot
    clear autopilot_block lateral_autopilot longitudinal_autopilot forces_moments
    assignin('base', 'AP', struct('longitudinal_mode', mode, 'use_ae700_command_profile', true));

    if bdIsLoaded(mdl)
        close_system(mdl, 0);
    end
    load_system(fullfile(cfg.project_root, 'simulink', 'main_models', [mdl, '.slx']));
    set_param(mdl, 'SignalLogging', 'on', 'SignalLoggingName', 'logsout');

    % Log required signals without permanently modifying the model
    Simulink.sdi.markSignalForStreaming([mdl '/MAV'], 1, 'on');
    Simulink.sdi.markSignalForStreaming([mdl '/Autopilot'], 1, 'on');
    Simulink.sdi.markSignalForStreaming([mdl '/Wind'], 1, 'on');
    Simulink.sdi.markSignalForStreaming([mdl '/Autopilot/autopilot'], 1, 'on');

    simOut = sim(mdl, 'StopTime', num2str(T_end), 'ReturnWorkspaceOutputs', 'on');
    logsout = simOut.logsout;

    sig_x = find_sig(logsout, [mdl '/MAV']);
    sig_delta = find_sig(logsout, [mdl '/Autopilot']);
    sig_wind = find_sig(logsout, [mdl '/Wind']);
    sig_apraw = find_sig(logsout, [mdl '/Autopilot/autopilot']);

    tx = sig_x.Values.Time(:);
    x_raw = sig_x.Values.Data;

    td = sig_delta.Values.Time(:);
    delta = sig_delta.Values.Data;

    tw = sig_wind.Values.Time(:);
    wind_raw = sig_wind.Values.Data;

    tap = sig_apraw.Values.Time(:);
    ap_raw_data = sig_apraw.Values.Data;

    % Use controller sample grid for plotting and command alignment
    t = td;
    x = interp1(tx, x_raw, t, 'linear', 'extrap');
    wind = interp1(tw, wind_raw, t, 'previous', 'extrap');
    ap_raw = interp1(tap, ap_raw_data, t, 'previous', 'extrap');

    P = evalin('base', 'P');

    n = numel(t);
    Va = zeros(n, 1);
    alpha = zeros(n, 1);
    beta = zeros(n, 1);
    chi = zeros(n, 1);

    for k = 1:n
        [~, air_data] = forces_moments(x(k, :).', delta(k, :).', wind(k, :).', P);
        Va(k) = air_data(1);
        alpha(k) = air_data(2);
        beta(k) = air_data(3);
        [chi(k), ~, ~] = course_from_state(x(k, :).', wind(k, :).');
    end

    % autopilot output format: [delta(1:4); x_command(1:12)]
    logs = struct();
    logs.t = t;
    logs.x = x;
    logs.delta = delta;
    logs.wind = wind;
    logs.Va = Va;
    logs.alpha = alpha;
    logs.beta = beta;
    logs.chi = chi;
    logs.phi_c = ap_raw(:, 11);
    logs.theta_c = ap_raw(:, 12);
    logs.course_c = ap_raw(:, 13);
    logs.altitude_c = ap_raw(:, 7);
    logs.Va_c = ap_raw(:, 8);

    Simulink.sdi.markSignalForStreaming([mdl '/MAV'], 1, 'off');
    Simulink.sdi.markSignalForStreaming([mdl '/Autopilot'], 1, 'off');
    Simulink.sdi.markSignalForStreaming([mdl '/Wind'], 1, 'off');
    Simulink.sdi.markSignalForStreaming([mdl '/Autopilot/autopilot'], 1, 'off');
    close_system(mdl, 0);
end

function sig = find_sig(logsout, block_path)
    sig = [];
    for i = 1:logsout.numElements
        s = logsout{i};
        bp = '';
        try
            bp = s.BlockPath.getBlock(1);
        catch
        end
        if strcmp(bp, block_path)
            sig = s;
            return;
        end
    end
    error('Signal for block path not found: %s', block_path);
end

function [chi, Vn, Ve] = course_from_state(x, wind)
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

    Vi = Rbi*[u; v; w] + [wind(1); wind(2); wind(3)];
    Vn = Vi(1);
    Ve = Vi(2);
    chi = atan2(Ve, Vn);
end

function plot_required_responses(logs)
    t = logs.t;
    phi = logs.x(:, 7);
    theta = logs.x(:, 8);
    chi = logs.chi;
    h = -logs.x(:, 3);

    figure('Name', 'AE700 Required Tracking Plots', 'Color', 'w');

    subplot(3, 2, 1);
    plot(t, rad2deg(phi), 'b', 'LineWidth', 1.4); hold on;
    plot(t, rad2deg(logs.phi_c), 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('\phi [deg]');
    title('Roll vs Commanded Roll'); legend('Roll', 'Command');

    subplot(3, 2, 2);
    plot(t, rad2deg(chi), 'b', 'LineWidth', 1.4); hold on;
    plot(t, rad2deg(logs.course_c), 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('\chi [deg]');
    title('Course vs Commanded Course'); legend('Course', 'Command');

    subplot(3, 2, 3);
    plot(t, rad2deg(theta), 'b', 'LineWidth', 1.4); hold on;
    plot(t, rad2deg(logs.theta_c), 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('\theta [deg]');
    title('Pitch vs Commanded Pitch'); legend('Pitch', 'Command');

    subplot(3, 2, 4);
    plot(t, h, 'b', 'LineWidth', 1.4); hold on;
    plot(t, logs.altitude_c, 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('Altitude [m]');
    title('Altitude vs Commanded Altitude'); legend('Altitude', 'Command');

    subplot(3, 2, 5);
    plot(t, logs.Va, 'b', 'LineWidth', 1.4); hold on;
    plot(t, logs.Va_c, 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time [s]'); ylabel('V_a [m/s]');
    title('Airspeed vs Commanded Airspeed (Throttle)'); legend('Airspeed', 'Command');

    subplot(3, 2, 6);
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
    subplot(4, 1, 1);
    plot(t, rad2deg(delta(:, 1)), 'LineWidth', 1.2); grid on;
    ylabel('\delta_e [deg]'); title('Control Inputs');

    subplot(4, 1, 2);
    plot(t, rad2deg(delta(:, 2)), 'LineWidth', 1.2); grid on;
    ylabel('\delta_a [deg]');

    subplot(4, 1, 3);
    plot(t, rad2deg(delta(:, 3)), 'LineWidth', 1.2); grid on;
    ylabel('\delta_r [deg]');

    subplot(4, 1, 4);
    plot(t, delta(:, 4), 'LineWidth', 1.2); grid on;
    ylabel('\delta_t [-]'); xlabel('Time [s]');
end
