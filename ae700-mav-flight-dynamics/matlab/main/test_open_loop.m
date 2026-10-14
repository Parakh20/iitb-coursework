%% Open-loop dynamics validation (no autopilot)
clear; clc; close all;

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));

P = aircraft_parameters();
[x_trim, u_trim] = compute_trim(25, 0, inf, P);

T = 30;
t = 0:P.Ts:T;
N = numel(t);

% Constant control input perturbation around trim
u_const = u_trim + [(-2*pi/180); (3*pi/180); (1*pi/180); 0.05];
u_const(1) = min(max(u_const(1), -P.delta_e_max), P.delta_e_max);
u_const(2) = min(max(u_const(2), -P.delta_a_max), P.delta_a_max);
u_const(3) = min(max(u_const(3), -P.delta_r_max), P.delta_r_max);
u_const(4) = min(max(u_const(4), P.delta_t_min), P.delta_t_max);

x = x_trim;
X = zeros(N, 12);
Va = zeros(N,1);

for k = 1:N
    wind_cfg = struct('enable_gust', false, 'reset', k == 1, 'Ts', P.Ts);
    wind = gust_model(t(k), P, wind_cfg);
    fm = forces_moments(x, u_const, wind, P);
    Va(k) = fm(7);
    X(k,:) = x.';

    k1 = eom_6dof(x, fm(1:6), P);
    fm2 = forces_moments(x + 0.5*P.Ts*k1, u_const, wind, P);
    k2 = eom_6dof(x + 0.5*P.Ts*k1, fm2(1:6), P);
    fm3 = forces_moments(x + 0.5*P.Ts*k2, u_const, wind, P);
    k3 = eom_6dof(x + 0.5*P.Ts*k2, fm3(1:6), P);
    fm4 = forces_moments(x + P.Ts*k3, u_const, wind, P);
    k4 = eom_6dof(x + P.Ts*k3, fm4(1:6), P);

    x = x + P.Ts*(k1 + 2*k2 + 2*k3 + k4)/6;
end

figure('Name', 'Open-Loop Dynamics Check', 'Color', 'w');
subplot(3,1,1);
plot(t, rad2deg(X(:,7)), 'LineWidth', 1.3); hold on;
plot(t, rad2deg(X(:,8)), 'LineWidth', 1.3);
plot(t, rad2deg(X(:,9)), 'LineWidth', 1.3);
grid on; ylabel('Angles [deg]');
legend('\phi','\theta','\psi'); title('Attitude Response (Open Loop)');

subplot(3,1,2);
plot(t, -X(:,3), 'LineWidth', 1.3); hold on;
plot(t, Va, 'LineWidth', 1.3);
grid on; ylabel('h [m], V_a [m/s]');
legend('Altitude','Airspeed'); title('Altitude and Airspeed (Open Loop)');

subplot(3,1,3);
plot(t, rad2deg(X(:,10)), 'LineWidth', 1.3); hold on;
plot(t, rad2deg(X(:,11)), 'LineWidth', 1.3);
plot(t, rad2deg(X(:,12)), 'LineWidth', 1.3);
grid on; ylabel('Rates [deg/s]'); xlabel('Time [s]');
legend('p','q','r'); title('Body Rate Response (Open Loop)');

fprintf('Open-loop test completed with constant control inputs.\n');
fprintf('u_const = [de da dr dt] = [%.3f %.3f %.3f %.3f]\n', u_const(1), u_const(2), u_const(3), u_const(4));
