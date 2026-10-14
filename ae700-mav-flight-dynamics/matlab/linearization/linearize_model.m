function [A, B, C, D] = linearize_model(x_trim, u_trim, P, model_name)
%LINEARIZE_MODEL Linearize the trim model using linmod with fallback.
%   [A,B,C,D] = linearize_model(x_trim, u_trim, P)

    if nargin < 4 || isempty(model_name)
        model_name = resolve_trim_model_path();
    end
    if nargin < 3 || isempty(P)
        P = aircraft_parameters();
    end

    if contains(model_name, filesep)
        model_path = model_name;
    else
        linearization_dir = fileparts(mfilename('fullpath'));
        project_root = fileparts(fileparts(linearization_dir));
        model_path = fullfile(project_root, 'simulink', 'main_models', model_name);
    end

    if ~endsWith(model_path, '.slx') && ~endsWith(model_path, '.mdl')
        model_path = [model_path, '.slx'];
    end

    [~, model_id, ~] = fileparts(model_path);

    assignin('base', 'P', P);
    assignin('base', 'x_trim', x_trim);
    assignin('base', 'u_trim', u_trim);

    try
        if bdIsLoaded(model_id)
            close_system(model_id, 0);
        end
        load_system(model_path);
        cleanup_obj = onCleanup(@() close_if_loaded(model_id)); %#ok<NASGU>
        [A, B, C, D] = linmod(model_id, x_trim, u_trim);
    catch ME
        warning('linearize_model:linmodFailed', ...
            'linmod failed (%s). Using finite-difference fallback.', ME.message);
        [A, B, C, D] = finite_difference_linearization(x_trim, u_trim, P);
    end
end

function [A, B, C, D] = finite_difference_linearization(x0, u0, P)
    n = numel(x0);
    m = numel(u0);
    dyn = @(x, u) local_dynamics(x, u, P);

    eps_x = 1e-6;
    eps_u = 1e-6;

    A = zeros(n, n);
    B = zeros(n, m);

    for i = 1:n
        dx = zeros(n, 1);
        dx(i) = eps_x;
        fp = dyn(x0 + dx, u0);
        fm = dyn(x0 - dx, u0);
        A(:, i) = (fp - fm)/(2*eps_x);
    end

    for j = 1:m
        du = zeros(m, 1);
        du(j) = eps_u;
        fp = dyn(x0, u0 + du);
        fm = dyn(x0, u0 - du);
        B(:, j) = (fp - fm)/(2*eps_u);
    end

    C = eye(n);
    D = zeros(n, m);
end

function xdot = local_dynamics(x, u, P)
    fm = forces_moments(x, u, zeros(6, 1), P);
    xdot = eom_6dof(x, fm(1:6), P);
end

function model_path = resolve_trim_model_path()
    linearization_dir = fileparts(mfilename('fullpath'));
    project_root = fileparts(fileparts(linearization_dir));

    candidates = {
        fullfile(project_root, 'simulink', 'main_models', 'mavsim_trim.slx'), ...
        fullfile(project_root, 'simulink', 'main_models', 'mav_trim_model.slx'), ...
        fullfile(linearization_dir, '..', 'models', 'mav_trim_model.slx')
    };

    model_path = candidates{1};
    for k = 1:numel(candidates)
        if isfile(candidates{k})
            model_path = candidates{k};
            return;
        end
    end
end

function close_if_loaded(model_id)
    if bdIsLoaded(model_id)
        close_system(model_id, 0);
    end
end
