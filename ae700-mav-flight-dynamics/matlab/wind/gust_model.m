function wind = gust_model(t, P, wind_cfg)
%GUST_MODEL Dryden gust + steady NED wind model.
%   wind = gust_model(t, P, wind_cfg)
%   returns wind = [wn we wd u_g v_g w_g]'
%
% Inputs
%   t        - simulation time [s]
%   P        - parameter struct containing:
%              wind_steady_n/e/d, L_u/L_v/L_w, sigma_u/v/w, wind_Va0, Ts
%   wind_cfg - optional struct:
%              .enable_gust (default from P or true)
%              .seed        (default from P or 7)
%              .Ts          (default P.Ts)
%              .gust_scale  (default from P or 1.0)
%              .reset       (default false)
%
% Notes
%   - Gust components [u_g v_g w_g]' are in body axes.
%   - Steady wind [wn we wd]' is in NED inertial axes.

    if nargin < 3
        wind_cfg = struct();
    end

    t = double(t(1));
    cfg = local_default_cfg(P, wind_cfg);

    persistent S
    if isempty(S)
        S = local_init_state(cfg.seed);
    end

    % Reset when requested, on new run, or when time goes backwards.
    if cfg.reset || ~S.initialized || t < S.t_prev || t <= 0
        S = local_init_state(cfg.seed);
        S.t_prev = t;
    elseif S.seed ~= cfg.seed
        % If seed changes, restart stream so behavior is reproducible.
        S = local_init_state(cfg.seed);
        S.t_prev = t;
    end

    if S.initialized
        dt = t - S.t_prev;
    else
        dt = 0;
    end

    % Always output configured steady wind in NED.
    wn = P.wind_steady_n;
    we = P.wind_steady_e;
    wd = P.wind_steady_d;

    if cfg.enable_gust
        Va = max(abs(P.wind_Va0), 0.1);
        Lu = max(P.L_u, 1e-3);
        Lv = max(P.L_v, 1e-3);
        Lw = max(P.L_w, 1e-3);

        % Dryden shaping constants (UAV book section 4.4 form).
        au = Va/Lu;
        av = Va/Lv;
        aw = Va/Lw;

        bu = P.sigma_u*sqrt(2*Va/Lu);
        kv = P.sigma_v*sqrt(3*Va/Lv);
        kw = P.sigma_w*sqrt(3*Va/Lw);
        bv = Va/(sqrt(3)*Lv);
        bw = Va/(sqrt(3)*Lw);

        % Advance the Dryden states only when time actually advances.
        if dt > 0
            nu = randn(S.stream);
            nv = randn(S.stream);
            nw = randn(S.stream);

            % u-gust: first-order model
            S.xu = S.xu + dt*(-au*S.xu + bu*nu);

            % v-gust: second-order model with (s+b)/(s+a)^2 form
            xv1_dot = S.xv(2);
            xv2_dot = -av^2*S.xv(1) - 2*av*S.xv(2) + nv;
            S.xv(1) = S.xv(1) + dt*xv1_dot;
            S.xv(2) = S.xv(2) + dt*xv2_dot;

            % w-gust: second-order model with (s+b)/(s+a)^2 form
            xw1_dot = S.xw(2);
            xw2_dot = -aw^2*S.xw(1) - 2*aw*S.xw(2) + nw;
            S.xw(1) = S.xw(1) + dt*xw1_dot;
            S.xw(2) = S.xw(2) + dt*xw2_dot;

            S.t_prev = t;
        end

        % Output current gust states.
        u_g = S.xu;
        v_g = kv*(S.xv(2) + bv*S.xv(1));
        w_g = kw*(S.xw(2) + bw*S.xw(1));

        u_g = cfg.gust_scale*u_g;
        v_g = cfg.gust_scale*v_g;
        w_g = cfg.gust_scale*w_g;
    else
        u_g = 0;
        v_g = 0;
        w_g = 0;
        if dt > 0
            S.t_prev = t;
        end
    end

    S.initialized = true;
    wind = [wn; we; wd; u_g; v_g; w_g];
end

function cfg = local_default_cfg(P, wind_cfg)
    if isfield(P, 'wind_enable_gust')
        cfg.enable_gust = logical(P.wind_enable_gust);
    else
        cfg.enable_gust = true;
    end

    if isfield(P, 'wind_seed')
        cfg.seed = P.wind_seed;
    else
        cfg.seed = 7;
    end

    if isfield(P, 'wind_gust_scale')
        cfg.gust_scale = P.wind_gust_scale;
    else
        cfg.gust_scale = 1.0;
    end

    cfg.reset = false;

    if isfield(P, 'Ts')
        cfg.Ts = P.Ts;
    else
        cfg.Ts = 0.01;
    end

    if isempty(wind_cfg)
        return;
    end

    if isfield(wind_cfg, 'enable_gust')
        cfg.enable_gust = logical(wind_cfg.enable_gust);
    end
    if isfield(wind_cfg, 'seed')
        cfg.seed = wind_cfg.seed;
    end
    if isfield(wind_cfg, 'gust_scale')
        cfg.gust_scale = wind_cfg.gust_scale;
    end
    if isfield(wind_cfg, 'Ts')
        cfg.Ts = wind_cfg.Ts;
    end
    if isfield(wind_cfg, 'reset')
        cfg.reset = logical(wind_cfg.reset);
    end
end

function S = local_init_state(seed)
    S = struct();
    S.stream = RandStream('mt19937ar', 'Seed', seed);
    S.seed = seed;
    S.xu = 0;
    S.xv = [0; 0];
    S.xw = [0; 0];
    S.t_prev = 0;
    S.initialized = false;
end
