%% Test forces and moments model for control surface perturbations
clear; clc;

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));

P = aircraft_parameters();

x = [0; 0; -100; P.u0; 0; 0; 0; 0; 0; 0; 0; 0];
wind = gust_model(0, P, struct('enable_gust', false, 'reset', true));

tests = {
    'Neutral',           [0; 0; 0; 0.5];
    'Elevator +5 deg',   [deg2rad(5); 0; 0; 0.5];
    'Aileron +5 deg',    [0; deg2rad(5); 0; 0.5];
    'Rudder +5 deg',     [0; 0; deg2rad(5); 0.5];
    'Throttle 0.8',      [0; 0; 0; 0.8];
};

fprintf('Test case                         Fx        Fy        Fz        l         m         n         Va      alpha    beta\n');
fprintf('-------------------------------------------------------------------------------------------------------------------\n');

for i = 1:size(tests,1)
    name = tests{i,1};
    delta = tests{i,2};
    out = forces_moments(x, delta, wind, P);
    fprintf('%-30s %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %8.2f %8.3f %8.3f\n', ...
        name, out(1), out(2), out(3), out(4), out(5), out(6), out(7), out(8), out(9));
end

fprintf('\nForces/moments test completed.\n');
