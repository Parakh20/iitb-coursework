%% Test 6-DOF dynamics including Jxz coupling effect
clear; clc; close all;

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));

P = aircraft_parameters();
x0 = [P.pn0; P.pe0; P.pd0; P.u0; P.v0; P.w0; P.phi0; P.theta0; P.psi0; P.p0; P.q0; P.r0];

T = 12;
dt = P.Ts;
t = 0:dt:T;

% Apply pure roll+yaw moments to observe coupling
fm = [0; 0; 0; 300; 0; 300];

x_coupled = integrate_case(x0, fm, t, P);

P_unc = P;
P_unc.Jxz = 0;
P_unc = recompute_gammas(P_unc);
x_uncoupled = integrate_case(x0, fm, t, P_unc);

figure('Name', 'Jxz Coupling Test', 'Color', 'w');
subplot(2,1,1);
plot(t, rad2deg(x_coupled(:,10)), 'b', 'LineWidth', 1.3); hold on;
plot(t, rad2deg(x_uncoupled(:,10)), 'r--', 'LineWidth', 1.3);
grid on; ylabel('p [deg/s]');
legend('J_{xz} \neq 0', 'J_{xz} = 0');
title('Roll Rate Response');

subplot(2,1,2);
plot(t, rad2deg(x_coupled(:,12)), 'b', 'LineWidth', 1.3); hold on;
plot(t, rad2deg(x_uncoupled(:,12)), 'r--', 'LineWidth', 1.3);
grid on; ylabel('r [deg/s]'); xlabel('Time [s]');
legend('J_{xz} \neq 0', 'J_{xz} = 0');
title('Yaw Rate Response');

fprintf('Dynamics test completed.\n');

function X = integrate_case(x0, fm, t, P)
    X = zeros(numel(t), 12);
    x = x0;
    X(1,:) = x.';
    dt = t(2) - t(1);

    for k = 2:numel(t)
        k1 = eom_6dof(x, fm, P);
        k2 = eom_6dof(x + 0.5*dt*k1, fm, P);
        k3 = eom_6dof(x + 0.5*dt*k2, fm, P);
        k4 = eom_6dof(x + dt*k3, fm, P);
        x = x + dt*(k1 + 2*k2 + 2*k3 + k4)/6;
        X(k,:) = x.';
    end
end

function P = recompute_gammas(P)
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
