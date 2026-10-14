function cfg = init_params()
%INIT_PARAMS Initialize MATLAB path, parameters, and base-workspace variables.

    main_dir = fileparts(mfilename('fullpath'));
    project_root = fileparts(fileparts(main_dir));
    matlab_root = fullfile(project_root, 'matlab');
    simulink_root = fullfile(project_root, 'simulink');
    trim_model = fullfile(simulink_root, 'main_models', 'mavsim_trim.slx');

    addpath(genpath(matlab_root));
    addpath(genpath(simulink_root));

    P = aircraft_parameters();
    x0 = initial_conditions(P);

    SIM = struct();
    SIM.ts_simulation = P.Ts;
    SIM.ts_video = 0.1;
    SIM.ts_control = P.Ts;
    SIM.ts_plotting = 0.1;

    WIND = struct();
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

    AP = P;
    AP.longitudinal_mode = 'altitude_hold';
    AP.use_ae700_command_profile = true;
    AP.trim_altitude = -x0(3);
    AP.trim_Va = norm(x0(4:6));

    assignin('base', 'PROJECT_ROOT', project_root);
    assignin('base', 'P', P);
    assignin('base', 'x0', x0);
    assignin('base', 'SIM', SIM);
    assignin('base', 'WIND', WIND);
    assignin('base', 'AP', AP);
    assignin('base', 'TRIM_MODEL', trim_model);

    cfg = struct();
    cfg.project_root = project_root;
    cfg.matlab_root = matlab_root;
    cfg.simulink_root = simulink_root;
    cfg.trim_model = trim_model;
end
