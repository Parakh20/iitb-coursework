function [x_trim, u_trim, info] = compute_trim(Va, gamma, R, P)
%COMPUTE_TRIM Compute steady trim state and controls.
%   [x_trim, u_trim, info] = compute_trim(Va, gamma, R, P)
%
%   Primary method: Simulink trim().
%   Fallback method: nonlinear search only when trim() is unavailable.

    if nargin < 1 || isempty(Va)
        Va = 35.0;
    end
    if nargin < 2 || isempty(gamma)
        gamma = 0.0;
    end
    if nargin < 3 || isempty(R)
        R = Inf;
    end
    if nargin < 4 || isempty(P)
        P = aircraft_parameters();
    end

    if ~isfinite(R) || abs(R) <= 1
        R = Inf;
    end

    has_trim = exist('trim', 'file') == 2 || exist('trim', 'builtin') == 5;
    model_path = resolve_trim_model_path();

    [x0, u0] = initial_trim_guess(Va, gamma, R, P);

    if has_trim
        if ~isfile(model_path)
            error('compute_trim:ModelMissing', 'Trim model not found: %s', model_path);
        end
        [x_trim, u_trim, info] = compute_trim_with_simulink_trim(Va, gamma, R, P, x0, u0, model_path);
    else
        warning('compute_trim:TrimUnavailableFallback', ...
            'trim() not available. Using nonlinear-search fallback trim.');
        [x_trim, u_trim, info] = compute_trim_with_search(Va, gamma, R, P, x0, u0);
    end

    x_trim = x_trim(:);
    u_trim = u_trim(:);
    assignin('base', 'x_trim', x_trim);
    assignin('base', 'u_trim', u_trim);

    [residual, xdot, air_data] = trim_residual_summary(x_trim, u_trim, Va, gamma, R, P);
    alpha_deg = rad2deg(atan2(x_trim(6), x_trim(4)));
    throttle = u_trim(4);
    cost = residual.' * residual;

    fprintf('Trim alpha: %.3f deg\n', alpha_deg);
    fprintf('Trim throttle: %.3f\n', throttle);
    fprintf('Trim cost: %.6e\n', cost);

    if alpha_deg < 5 || alpha_deg > 7
        warning('compute_trim:AlphaOutOfRange', ...
            'Trim alpha %.3f deg is outside recommended [5, 7] deg.', alpha_deg);
    end
    if throttle > 0.8
        warning('compute_trim:ThrottleHigh', ...
            'Trim throttle %.3f is higher than recommended maximum 0.8.', throttle);
    end

    info.cost = cost;
    info.residual = residual;
    info.state_derivative = xdot;
    info.air_data = air_data;
    info.model_path = model_path;
    info.initial_guess = struct('x0', x0, 'u0', u0);
    info.alpha_deg = alpha_deg;
    info.throttle = throttle;
end

function [x_trim, u_trim, info] = compute_trim_with_simulink_trim(Va, gamma, R, P, x0, u0, model_path)
    dx0 = desired_trim_derivative(Va, gamma, R);

    % Root outputs are [x_out(12); y_out(12)].
    % Constrain Va and beta using y(19)=Va and y(21)=0.
    y0 = zeros(24, 1);
    y0(19) = Va;
    y0(21) = 0;

    [ix, iu] = trim_index_sets(R);
    iy = [19; 21];
    idx = [3; 4; 5; 6; 7; 8; 9; 10; 11; 12];

    assignin('base', 'P', P);
    assignin('base', 'x_trim', x0);
    assignin('base', 'u_trim', u0);

    [~, model_id, ~] = fileparts(model_path);
    if bdIsLoaded(model_id)
        close_system(model_id, 0);
    end
    load_system(model_path);
    cleanup_obj = onCleanup(@() close_if_needed(model_id)); %#ok<NASGU>

    try
        [x_trim, u_trim, y_trim, dx_trim] = trim(model_id, x0, u0, y0, ix, iu, iy, dx0, idx);
    catch ME
        error('compute_trim:TrimFailed', ...
            'Simulink trim failed for %s\n%s', model_path, ME.message);
    end

    info = struct();
    info.method = 'simulink_trim';
    info.output = struct('y_trim', y_trim, 'dx_trim', dx_trim);
    info.indices = struct('ix', ix, 'iu', iu, 'iy', iy, 'idx', idx);
end

function [x_trim, u_trim, info] = compute_trim_with_search(Va, gamma, R, P, x0, u0)
    z0 = [atan2(x0(6), x0(4)); x0(7); x0(8); u0(1); u0(2); u0(3); u0(4)];
    [lb, ub] = trim_search_bounds(R, P);

    cost_fn = @(z) trim_residual_cost(z, Va, gamma, R, P);
    if exist('fmincon', 'file') == 2
        opts = optimoptions('fmincon', ...
            'Display', 'off', ...
            'Algorithm', 'sqp', ...
            'MaxFunctionEvaluations', 2e4, ...
            'MaxIterations', 300, ...
            'ConstraintTolerance', 1e-9, ...
            'StepTolerance', 1e-10);
        [z_opt, fval, exitflag, output] = fmincon(cost_fn, z0, [], [], [], [], lb, ub, [], opts);
    else
        penalty = @(z) trim_residual_cost(apply_box(z, lb, ub), Va, gamma, R, P);
        opts = optimset('Display', 'off', 'MaxIter', 2e4, 'MaxFunEvals', 6e4, ...
            'TolX', 1e-9, 'TolFun', 1e-9);
        z_opt = fminsearch(penalty, z0, opts);
        z_opt = apply_box(z_opt, lb, ub);
        fval = cost_fn(z_opt);
        exitflag = 0;
        output = struct('message', 'fminsearch fallback used');
    end

    [x_trim, u_trim] = reconstruct_trim(z_opt, Va, gamma, R);
    info = struct();
    info.method = 'nonlinear_search_fallback';
    info.output = struct('optimizer', output, 'exitflag', exitflag, 'fval', fval, 'z_opt', z_opt);
end

function [x0, u0] = initial_trim_guess(Va, gamma, R, P)
    alpha0 = 6*pi/180;

    if isfinite(R)
        phi0 = atan2(Va^2, P.gravity*abs(R));
        phi0 = min(max(phi0, -45*pi/180), 45*pi/180);
        if R < 0
            phi0 = -phi0;
        end
        da0 = 2*pi/180*sign(phi0);
    else
        phi0 = 0;
        da0 = 0;
    end

    theta0 = alpha0 + gamma;

    cmde_safe = P.Cmde;
    if abs(cmde_safe) < 1e-3
        cmde_safe = -1e-3;
    end
    de0 = -(P.Cm0 + P.Cma*alpha0)/cmde_safe;
    de0 = min(max(de0, -P.delta_e_max), P.delta_e_max);

    dr0 = 0;
    dt0 = min(max(0.55, P.delta_t_min), min(0.60, P.delta_t_max));

    psi_dot = desired_turn_rate(Va, gamma, R);
    if isfinite(R)
        p0 = -psi_dot*sin(theta0);
        q0 = psi_dot*sin(phi0)*cos(theta0);
        r0 = psi_dot*cos(phi0)*cos(theta0);
    else
        p0 = 0;
        q0 = 0;
        r0 = 0;
    end

    x0 = [0; 0; -100; Va*cos(alpha0); 0; Va*sin(alpha0); phi0; theta0; 0; p0; q0; r0];
    u0 = [de0; da0; dr0; dt0];
end

function [ix, iu] = trim_index_sets(R)
    if isfinite(R)
        ix = [5];
        iu = [];
    else
        ix = [2; 5; 7; 9; 10; 11; 12];
        iu = [2; 3];
    end
end

function J = trim_residual_cost(z, Va, gamma, R, P)
    [x_trim, u_trim] = reconstruct_trim(z, Va, gamma, R);
    [residual, ~, ~] = trim_residual_summary(x_trim, u_trim, Va, gamma, R, P);

    w = [2.0; 2.0; 2.0; 2.0; 2.0; 2.0; 2.0; 2.0; 2.0; 1.0; 4.0; 4.0];
    r = w .* residual;
    ctrl = [u_trim(1); u_trim(2); u_trim(3); (u_trim(4) - 0.55)];
    J = r.' * r + 0.02 * (ctrl.' * ctrl);
end

function [x_trim, u_trim] = reconstruct_trim(z, Va, gamma, R)
    alpha = z(1);
    phi = z(2);
    theta = z(3);
    delta_e = z(4);
    delta_a = z(5);
    delta_r = z(6);
    delta_t = z(7);

    u = Va*cos(alpha);
    v = 0;
    w = Va*sin(alpha);

    psi_dot = desired_turn_rate(Va, gamma, R);
    if isfinite(R)
        p = -psi_dot*sin(theta);
        q = psi_dot*sin(phi)*cos(theta);
        r = psi_dot*cos(phi)*cos(theta);
    else
        phi = 0;
        delta_a = 0;
        delta_r = 0;
        p = 0;
        q = 0;
        r = 0;
    end

    x_trim = [0; 0; -100; u; v; w; phi; theta; 0; p; q; r];
    u_trim = [delta_e; delta_a; delta_r; delta_t];
end

function [lb, ub] = trim_search_bounds(R, P)
    if isfinite(R)
        phi_lb = -45*pi/180;
        phi_ub = 45*pi/180;
        da_lb = -P.delta_a_max;
        da_ub = P.delta_a_max;
        dr_lb = -P.delta_r_max;
        dr_ub = P.delta_r_max;
    else
        phi_lb = 0;
        phi_ub = 0;
        da_lb = 0;
        da_ub = 0;
        dr_lb = 0;
        dr_ub = 0;
    end

    lb = [2*pi/180; phi_lb; -5*pi/180; -P.delta_e_max; da_lb; dr_lb; P.delta_t_min];
    ub = [15*pi/180; phi_ub; 20*pi/180; P.delta_e_max; da_ub; dr_ub; P.delta_t_max];
end

function z_box = apply_box(z, lb, ub)
    z_box = min(max(z, lb), ub);
end

function [residual, xdot, air_data] = trim_residual_summary(x_trim, u_trim, Va, gamma, R, P)
    fm = forces_moments(x_trim, u_trim, zeros(6, 1), P);
    xdot = eom_6dof(x_trim, fm(1:6), P);
    dx_des = desired_trim_derivative(Va, gamma, R);
    air_data = fm(7:9);

    residual = [
        xdot(3) - dx_des(3);
        xdot(4:8);
        xdot(9) - dx_des(9);
        xdot(10:12);
        air_data(1) - Va;
        air_data(3)
    ];
end

function dx_des = desired_trim_derivative(Va, gamma, R)
    dx_des = zeros(12, 1);
    dx_des(3) = -Va*sin(gamma);
    dx_des(9) = desired_turn_rate(Va, gamma, R);
end

function psi_dot = desired_turn_rate(Va, gamma, R)
    if isfinite(R)
        psi_dot = Va*cos(gamma)/R;
    else
        psi_dot = 0;
    end
end

function close_if_needed(model_id)
    if bdIsLoaded(model_id)
        close_system(model_id, 0);
    end
end

function model_path = resolve_trim_model_path()
    trim_dir = fileparts(mfilename('fullpath'));
    project_root = fileparts(fileparts(trim_dir));

    candidates = {
        fullfile(project_root, 'simulink', 'main_models', 'mavsim_trim.slx'), ...
        fullfile(project_root, 'simulink', 'main_models', 'mav_trim_model.slx'), ...
        fullfile(trim_dir, '..', 'models', 'mav_trim_model.slx')
    };

    model_path = candidates{1};
    for k = 1:numel(candidates)
        if isfile(candidates{k})
            model_path = candidates{k};
            return;
        end
    end
end
