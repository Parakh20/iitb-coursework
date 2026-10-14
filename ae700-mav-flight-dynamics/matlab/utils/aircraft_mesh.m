function [V, F, C, meta] = aircraft_mesh(scale)
%AIRCRAFT_MESH Build a detailed Pioneer-style twin-boom UAV mesh.
%   Body frame convention: x forward, y right, z down.

    if nargin < 1
        scale = 1.0;
    end

    % Material palette (face colors)
    col_body = [0.20, 0.86, 1.00];
    col_body_dark = [0.05, 0.50, 0.90];
    col_wing = [1.00, 0.52, 0.14];
    col_tail = [1.00, 0.70, 0.20];
    col_boom = [0.35, 0.98, 0.70];
    col_prop = [0.12, 0.12, 0.12];
    col_gear = [0.86, 0.88, 0.92];
    col_wheel = [0.10, 0.10, 0.10];
    col_sensor = [1.00, 0.95, 0.42];

    V = zeros(0, 3);
    F = zeros(0, 3);
    C = zeros(0, 3);

    prop_idx = zeros(0, 1);

    %---------------- Fuselage pod ----------------
    [v, f] = make_box([0.70, 0.00, 0.00], [1.60, 0.44, 0.32]);
    [V, F, C] = add_component(V, F, C, v, f, col_body);

    [v, f] = make_nosecone(2.15, 1.48, 0.20, 0.15, 14);
    [V, F, C] = add_component(V, F, C, v, f, col_body);

    [v, f] = make_frustum(-0.10, -1.25, 0.22, 0.16, 0.14, 0.11, 14);
    [V, F, C] = add_component(V, F, C, v, f, col_body_dark);

    [v, f] = make_box([0.86, 0.00, -0.18], [0.52, 0.30, 0.10]); % canopy fairing
    [V, F, C] = add_component(V, F, C, v, f, [0.84, 0.95, 1.00]);

    [v, f] = make_box([0.18, 0.00, 0.16], [0.36, 0.30, 0.18]); % belly payload pod
    [V, F, C] = add_component(V, F, C, v, f, col_body_dark);

    %---------------- Main wing (high wing) ----------------
    [v, f] = make_wing_panel(+1, 0.00, 2.58, 1.05, 0.62, 0.050, 1.00, 0.10, -0.14, 0.025);
    [V, F, C] = add_component(V, F, C, v, f, col_wing);

    [v, f] = make_wing_panel(-1, 0.00, 2.58, 1.05, 0.62, 0.050, 1.00, 0.10, -0.14, 0.025);
    [V, F, C] = add_component(V, F, C, v, f, col_wing);

    %---------------- Twin booms + support struts ----------------
    [v, f] = make_box([-1.25, 0.95, 0.02], [2.50, 0.09, 0.09]);
    [V, F, C] = add_component(V, F, C, v, f, col_boom);
    [v, f] = make_box([-1.25,-0.95, 0.02], [2.50, 0.09, 0.09]);
    [V, F, C] = add_component(V, F, C, v, f, col_boom);

    [v, f] = make_beam([0.30, 0.35, -0.05], [-1.80, 0.95, 0.02], 0.03, 0.03);
    [V, F, C] = add_component(V, F, C, v, f, col_boom);
    [v, f] = make_beam([0.30,-0.35, -0.05], [-1.80,-0.95, 0.02], 0.03, 0.03);
    [V, F, C] = add_component(V, F, C, v, f, col_boom);

    %---------------- Tailplane and twin fins ----------------
    [v, f] = make_wing_panel(+1, 0.00, 1.05, 0.45, 0.30, 0.030, -2.32, 0.02, -0.12, 0.00);
    [V, F, C] = add_component(V, F, C, v, f, col_tail);
    [v, f] = make_wing_panel(-1, 0.00, 1.05, 0.45, 0.30, 0.030, -2.32, 0.02, -0.12, 0.00);
    [V, F, C] = add_component(V, F, C, v, f, col_tail);

    [v, f] = make_vertical_fin(-2.56, 1.02, -0.14, 0.43, 0.62, 0.04);
    [V, F, C] = add_component(V, F, C, v, f, col_tail);
    [v, f] = make_vertical_fin(-2.56,-1.02, -0.14, 0.43, 0.62, 0.04);
    [V, F, C] = add_component(V, F, C, v, f, col_tail);

    [v, f] = make_vertical_fin(-2.78, 1.03, -0.14, 0.20, 0.54, 0.028); % rudder strip
    [V, F, C] = add_component(V, F, C, v, f, [1.00, 0.34, 0.34]);
    [v, f] = make_vertical_fin(-2.78,-1.03, -0.14, 0.20, 0.54, 0.028);
    [V, F, C] = add_component(V, F, C, v, f, [1.00, 0.34, 0.34]);

    %---------------- Engine + pusher prop ----------------
    [v, f] = make_cylinder_x([-1.55, 0.00, 0.00], 0.11, 0.24, 14);
    [V, F, C] = add_component(V, F, C, v, f, col_body_dark);

    [v, f] = make_cylinder_x([-1.73, 0.00, 0.00], 0.045, 0.055, 14);
    [V, F, C] = add_component(V, F, C, v, f, col_prop);

    [v, f] = make_beam([-1.73, -0.58, 0.00], [-1.73, 0.58, 0.00], 0.042, 0.015);
    [V, F, C, idx_local] = add_component(V, F, C, v, f, col_prop);
    prop_idx = [prop_idx; idx_local(:)]; %#ok<AGROW>

    [v, f] = make_beam([-1.73, 0.00, -0.58], [-1.73, 0.00, 0.58], 0.042, 0.015);
    [V, F, C, idx_local] = add_component(V, F, C, v, f, col_prop);
    prop_idx = [prop_idx; idx_local(:)]; %#ok<AGROW>

    %---------------- Landing gear ----------------
    [v, f] = make_beam([1.00, 0.00, 0.09], [1.16, 0.00, 0.36], 0.022, 0.022);
    [V, F, C] = add_component(V, F, C, v, f, col_gear);

    [v, f] = make_beam([-0.36, 0.72, 0.07], [-0.56, 0.92, 0.36], 0.024, 0.024);
    [V, F, C] = add_component(V, F, C, v, f, col_gear);
    [v, f] = make_beam([-0.36,-0.72, 0.07], [-0.56,-0.92, 0.36], 0.024, 0.024);
    [V, F, C] = add_component(V, F, C, v, f, col_gear);

    [v, f] = make_cylinder_y([1.20, 0.00, 0.39], 0.080, 0.055, 14);
    [V, F, C] = add_component(V, F, C, v, f, col_wheel);
    [v, f] = make_cylinder_y([-0.58, 0.93, 0.42], 0.115, 0.070, 14);
    [V, F, C] = add_component(V, F, C, v, f, col_wheel);
    [v, f] = make_cylinder_y([-0.58,-0.93, 0.42], 0.115, 0.070, 14);
    [V, F, C] = add_component(V, F, C, v, f, col_wheel);

    %---------------- Antenna / sensor mast ----------------
    [v, f] = make_beam([0.30, 0.00, -0.24], [0.27, 0.00, -0.46], 0.012, 0.012);
    [V, F, C] = add_component(V, F, C, v, f, col_sensor);
    [v, f] = make_cylinder_x([0.27, 0.00, -0.36], 0.03, 0.02, 12);
    [V, F, C] = add_component(V, F, C, v, f, col_sensor);

    V = scale * V;

    meta = struct();
    meta.prop_idx = prop_idx;
    meta.prop_center = scale * [-1.73, 0.00, 0.00];
end

function [V, F, C, idx_local] = add_component(V, F, C, v, f, color)
    if nargin < 7
        idx_local = [];
    end
    n0 = size(V, 1);
    V = [V; v];
    F = [F; f + n0];
    C = [C; repmat(color, size(f,1), 1)];
    idx_local = (n0 + (1:size(v,1))).';
end

function [v, f] = make_box(center, dims)
    hx = dims(1)/2;
    hy = dims(2)/2;
    hz = dims(3)/2;

    v = [
        center + [ hx, -hy, -hz];
        center + [ hx,  hy, -hz];
        center + [ hx,  hy,  hz];
        center + [ hx, -hy,  hz];
        center + [-hx, -hy, -hz];
        center + [-hx,  hy, -hz];
        center + [-hx,  hy,  hz];
        center + [-hx, -hy,  hz]
    ];

    f = [
        1 2 3; 1 3 4; ... % front
        5 7 6; 5 8 7; ... % back
        1 5 6; 1 6 2; ... % top
        4 3 7; 4 7 8; ... % bottom
        2 6 7; 2 7 3; ... % right
        1 4 8; 1 8 5  ... % left
    ];
end

function [v, f] = make_nosecone(x_apex, x_base, ry, rz, n)
    th = linspace(0, 2*pi, n+1).';
    th(end) = [];

    ring = [x_base*ones(n,1), ry*cos(th), rz*sin(th)];
    apex = [x_apex, 0, 0];
    base_center = [x_base, 0, 0];

    v = [ring; apex; base_center];
    ia = n + 1;
    ic = n + 2;

    f = zeros(2*n, 3);
    for i = 1:n
        j = i + 1;
        if j > n
            j = 1;
        end
        f(2*i-1, :) = [i, j, ia];
        f(2*i, :)   = [j, i, ic];
    end
end

function [v, f] = make_frustum(x_front, x_back, ry_front, rz_front, ry_back, rz_back, n)
    th = linspace(0, 2*pi, n+1).';
    th(end) = [];

    front = [x_front*ones(n,1), ry_front*cos(th), rz_front*sin(th)];
    back  = [x_back*ones(n,1),  ry_back*cos(th),  rz_back*sin(th)];

    v = [front; back; [x_front,0,0]; [x_back,0,0]];
    icf = 2*n + 1;
    icb = 2*n + 2;

    f = zeros(4*n, 3);
    for i = 1:n
        j = i + 1;
        if j > n
            j = 1;
        end

        % side
        f(4*i-3, :) = [i, j, n+j];
        f(4*i-2, :) = [i, n+j, n+i];

        % caps
        f(4*i-1, :) = [j, i, icf];
        f(4*i, :)   = [n+i, n+j, icb];
    end
end

function [v, f] = make_wing_panel(side, y_root, span, c_root, c_tip, t, x_le_root, sweep, z_root, dihedral)
    y_tip = y_root + side*span;
    x_le_tip = x_le_root - sweep*span;
    z_tip = z_root - dihedral*span;

    x_te_root = x_le_root - c_root;
    x_te_tip = x_le_tip - c_tip;

    v = [
        x_le_root, y_root, z_root - t/2;
        x_te_root, y_root, z_root - t/2;
        x_te_tip,  y_tip,  z_tip  - t/2;
        x_le_tip,  y_tip,  z_tip  - t/2;
        x_le_root, y_root, z_root + t/2;
        x_te_root, y_root, z_root + t/2;
        x_te_tip,  y_tip,  z_tip  + t/2;
        x_le_tip,  y_tip,  z_tip  + t/2
    ];

    f = [
        1 2 3; 1 3 4; ... % top
        5 7 6; 5 8 7; ... % bottom
        1 4 8; 1 8 5; ... % LE
        2 6 7; 2 7 3; ... % TE
        1 5 6; 1 6 2; ... % root
        4 3 7; 4 7 8  ... % tip
    ];
end

function [v, f] = make_vertical_fin(x_te, y0, z_root, chord, height, thick)
    % Fin extends upward, i.e., towards negative z in body frame.
    x_le = x_te + chord;
    z_tip = z_root - height;

    yL = y0 - thick/2;
    yR = y0 + thick/2;

    v = [
        x_le, yL, z_root;
        x_te, yL, z_root;
        x_te, yL, z_tip;
        x_le, yL, z_tip;
        x_le, yR, z_root;
        x_te, yR, z_root;
        x_te, yR, z_tip;
        x_le, yR, z_tip
    ];

    f = [
        1 2 3; 1 3 4;
        5 7 6; 5 8 7;
        1 5 6; 1 6 2;
        2 6 7; 2 7 3;
        3 7 8; 3 8 4;
        1 4 8; 1 8 5
    ];
end

function [v, f] = make_beam(p0, p1, w, h)
    d = p1 - p0;
    L = norm(d);
    ex = d / max(L, 1e-9);

    up = [0, 0, 1];
    if abs(dot(ex, up)) > 0.9
        up = [0, 1, 0];
    end

    ey = cross(ex, up);
    ey = ey / max(norm(ey), 1e-9);
    ez = cross(ex, ey);
    ez = ez / max(norm(ez), 1e-9);

    dy = (w/2)*ey;
    dz = (h/2)*ez;

    a = p0; b = p1;

    v = [
        a + dy + dz;
        a - dy + dz;
        a - dy - dz;
        a + dy - dz;
        b + dy + dz;
        b - dy + dz;
        b - dy - dz;
        b + dy - dz
    ];

    f = [
        1 2 3; 1 3 4; ...
        5 8 7; 5 7 6; ...
        1 5 6; 1 6 2; ...
        2 6 7; 2 7 3; ...
        3 7 8; 3 8 4; ...
        1 4 8; 1 8 5  ...
    ];
end

function [v, f] = make_cylinder_x(center, r, L, n)
    th = linspace(0, 2*pi, n+1).';
    th(end) = [];

    x1 = center(1) - L/2;
    x2 = center(1) + L/2;

    ring1 = [x1*ones(n,1), center(2) + r*cos(th), center(3) + r*sin(th)];
    ring2 = [x2*ones(n,1), center(2) + r*cos(th), center(3) + r*sin(th)];

    v = [ring1; ring2; [x1, center(2), center(3)]; [x2, center(2), center(3)]];
    ic1 = 2*n + 1;
    ic2 = 2*n + 2;

    f = zeros(4*n, 3);
    for i = 1:n
        j = i + 1;
        if j > n
            j = 1;
        end
        f(4*i-3, :) = [i, j, n+j];
        f(4*i-2, :) = [i, n+j, n+i];
        f(4*i-1, :) = [j, i, ic1];
        f(4*i, :)   = [n+i, n+j, ic2];
    end
end

function [v, f] = make_cylinder_y(center, r, L, n)
    th = linspace(0, 2*pi, n+1).';
    th(end) = [];

    y1 = center(2) - L/2;
    y2 = center(2) + L/2;

    ring1 = [center(1) + r*cos(th), y1*ones(n,1), center(3) + r*sin(th)];
    ring2 = [center(1) + r*cos(th), y2*ones(n,1), center(3) + r*sin(th)];

    v = [ring1; ring2; [center(1), y1, center(3)]; [center(1), y2, center(3)]];
    ic1 = 2*n + 1;
    ic2 = 2*n + 2;

    f = zeros(4*n, 3);
    for i = 1:n
        j = i + 1;
        if j > n
            j = 1;
        end
        f(4*i-3, :) = [i, j, n+j];
        f(4*i-2, :) = [i, n+j, n+i];
        f(4*i-1, :) = [j, i, ic1];
        f(4*i, :)   = [n+i, n+j, ic2];
    end
end
