% pioneer_parameters.m
% Simulink init script for chapter 6, aligned with AE700 reference behavior.

script_file = mfilename('fullpath');
if ~isempty(script_file)
    data_dir = fileparts(script_file);
    matlab_root = fileparts(data_dir);
    addpath(genpath(matlab_root));
end

% Preserve external overrides (used by run_simulation_simulink)
mode_override = '';
profile_override = true;
if evalin('base', 'exist(''AP'', ''var'')')
    AP_prev = evalin('base', 'AP');
    if isstruct(AP_prev)
        if isfield(AP_prev, 'longitudinal_mode')
            mode_override = AP_prev.longitudinal_mode;
        end
        if isfield(AP_prev, 'use_ae700_command_profile')
            profile_override = AP_prev.use_ae700_command_profile;
        end
    end
end

% Baseline parameter set (no side effects)
P = pioneer_parameters_struct();

% Simulink timing parameters used by model blocks
SIM.ts_simulation = P.Ts;
SIM.ts_video = 0.1;
SIM.ts_control = P.Ts;
SIM.ts_plotting = 0.1;

% Wind struct consumed by Wind subsystem blocks
WIND.wind_n = P.wind_steady_n;
WIND.wind_e = P.wind_steady_e;
WIND.wind_d = P.wind_steady_d;
WIND.Va0 = P.wind_Va0;
WIND.L_u = P.L_u;
WIND.L_v = P.L_v;
WIND.L_w = P.L_w;
WIND.sigma_u = P.sigma_u;
WIND.sigma_v = P.sigma_v;
WIND.sigma_w = P.sigma_w;

% Trim target (same baseline used in AE700 script)
Va_trim = 35.0;
gamma_trim = 0.0;
R_trim = Inf;
[x_trim, u_trim, info] = compute_trim(Va_trim, gamma_trim, R_trim, P);

% Start simulation at trim state for clean closed-loop behavior
P.pn0 = x_trim(1);
P.pe0 = x_trim(2);
P.pd0 = x_trim(3);
P.u0 = x_trim(4);
P.v0 = x_trim(5);
P.w0 = x_trim(6);
P.phi0 = x_trim(7);
P.theta0 = x_trim(8);
P.psi0 = x_trim(9);
P.p0 = x_trim(10);
P.q0 = x_trim(11);
P.r0 = x_trim(12);

% Trim references for the autopilot inner/outer loops
P.trim_delta_e = u_trim(1);
P.trim_delta_a = u_trim(2);
P.trim_delta_r = u_trim(3);
P.trim_delta_t = u_trim(4);
P.trim_phi = x_trim(7);
P.trim_theta = x_trim(8);
P.trim_beta = 0;
P.trim_altitude = -x_trim(3);
P.trim_Va = Va_trim;

% Autopilot parameter struct consumed by MATLAB Function block
AP = P;
AP.use_ae700_command_profile = profile_override;
if ~isempty(mode_override)
    AP.longitudinal_mode = mode_override;
end

fprintf('Trim optimization cost: %.3e\n', info.cost);
fprintf('Trimmed alpha: %.2f deg\n', rad2deg(atan2(x_trim(6), x_trim(4))));
