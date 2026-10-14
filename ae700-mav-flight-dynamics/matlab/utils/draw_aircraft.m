function draw_aircraft(x, t)
%DRAW_AIRCRAFT Draw/update a detailed Pioneer-style aircraft animation.
%   x = [pn pe pd u v w phi theta psi p q r]'

    if nargin < 2
        t = 0;
    end

    if ~usejava('awt') || ~feature('ShowFigureWindows')
        return;
    end

    x = x(:);
    if numel(x) < 9
        error('draw_aircraft:StateSize', 'State vector must have at least 9 elements.');
    end

    pn = x(1);
    pe = x(2);
    pd = x(3);
    phi = x(7);
    theta = x(8);
    psi = x(9);

    persistent h_ax h_patch h_light h_light_fill h_ground V0 F C meta initialized
    persistent h_cs_ex h_cs_ny h_cs_uz h_cs_text

    need_init = isempty(initialized) || isempty(h_patch) || ~isgraphics(h_patch, 'patch') || ...
                isempty(h_ax) || ~isgraphics(h_ax, 'axes');

    if need_init
        initialized = true;
        [V0, F, C, meta] = aircraft_mesh(1.35);

        fig = figure(700); clf(fig);
        set(fig, 'Color', [0.00, 0.00, 0.00], 'Name', 'AE700 Pioneer Animation');

        h_ax = axes('Parent', fig); %#ok<LAXES>
        hold(h_ax, 'on');
        axis(h_ax, 'equal');
        grid(h_ax, 'on');
        set(h_ax, 'Color', [0.00, 0.00, 0.00], ...
                  'GridColor', [0.20, 0.20, 0.20], ...
                  'XColor', [1.00, 1.00, 1.00], ...
                  'YColor', [1.00, 1.00, 1.00], ...
                  'ZColor', [1.00, 1.00, 1.00], ...
                  'FontSize', 11, ...
                  'GridAlpha', 0.22, ...
                  'MinorGridAlpha', 0.16, ...
                  'Projection', 'orthographic');
        xlabel(h_ax, 'East [m]');
        ylabel(h_ax, 'North [m]');
        zlabel(h_ax, 'Up [m]');
        title(h_ax, 'AE700 Pioneer UAV Animation (Isometric View)', ...
              'Color', [1.00, 1.00, 1.00]);

        % Fixed isometric view
        view(h_ax, 45, 35.264);

        V_body = apply_prop_spin(V0, meta, t);
        V_plot = ned_to_plot(translate(rotate(V_body, phi, theta, psi), pn, pe, pd));

        h_patch = patch('Vertices', V_plot, ...
                        'Faces', F, ...
                        'FaceVertexCData', C, ...
                        'FaceColor', 'flat', ...
                        'EdgeColor', 'none', ...
                        'AmbientStrength', 0.40, ...
                        'DiffuseStrength', 0.75, ...
                        'SpecularStrength', 0.25, ...
                        'SpecularExponent', 18, ...
                        'Parent', h_ax);

        material(h_ax, [0.32, 0.72, 0.30]);
        lighting(h_ax, 'gouraud');
        h_light = camlight(h_ax, 'headlight');
        set(h_light, 'Color', [0.95, 0.97, 1.00]);
        h_light_fill = camlight(h_ax, 210, 20);
        set(h_light_fill, 'Color', [0.35, 0.35, 0.35]);

        % Subtle dark ground plane for depth cues
        [gx, gy] = meshgrid(-250:25:250, -250:25:250);
        gz = -35 * ones(size(gx));
        h_ground = surf(h_ax, gx, gy, gz, ...
                        'FaceColor', [0.02, 0.02, 0.02], ...
                        'EdgeColor', [0.16, 0.16, 0.16], ...
                        'FaceAlpha', 0.96, ...
                        'EdgeAlpha', 0.28);
        uistack(h_ground, 'bottom');

        axis(h_ax, [pe-45, pe+45, pn-45, pn+45, -pd-32, -pd+24]);

        [h_cs_ex, h_cs_ny, h_cs_uz, h_cs_text] = init_coordinate_system(h_ax, pe, pn, pd);
    else
        V_body = apply_prop_spin(V0, meta, t);
        V_plot = ned_to_plot(translate(rotate(V_body, phi, theta, psi), pn, pe, pd));
        set(h_patch, 'Vertices', V_plot, 'Faces', F);

        axis(h_ax, [pe-45, pe+45, pn-45, pn+45, -pd-32, -pd+24]);

        if ~isempty(h_light) && isgraphics(h_light)
            camlight(h_light, 'headlight');
        end
        if ~isempty(h_light_fill) && isgraphics(h_light_fill)
            camlight(h_light_fill, 210, 20);
        end

        update_coordinate_system(h_cs_ex, h_cs_ny, h_cs_uz, h_cs_text, pe, pn, pd);
    end

    if mod(round(t*120), 2) == 0
        drawnow limitrate;
    end
end

function [h_ex, h_ny, h_uz, h_txt] = init_coordinate_system(ax, pe, pn, pd)
    L = 9;
    base = [pe-35, pn-35, -pd-22];

    h_ex = quiver3(ax, base(1), base(2), base(3), L, 0, 0, 0, ...
        'LineWidth', 2.0, 'Color', [1.00, 1.00, 1.00], 'MaxHeadSize', 0.7);
    h_ny = quiver3(ax, base(1), base(2), base(3), 0, L, 0, 0, ...
        'LineWidth', 2.0, 'Color', [1.00, 1.00, 1.00], 'MaxHeadSize', 0.7);
    h_uz = quiver3(ax, base(1), base(2), base(3), 0, 0, L, 0, ...
        'LineWidth', 2.0, 'Color', [1.00, 1.00, 1.00], 'MaxHeadSize', 0.7);

    h_txt(1) = text(ax, base(1)+L+1.5, base(2), base(3), 'E', ...
        'Color', [1.00, 1.00, 1.00], 'FontWeight', 'bold', 'FontSize', 11);
    h_txt(2) = text(ax, base(1), base(2)+L+1.5, base(3), 'N', ...
        'Color', [1.00, 1.00, 1.00], 'FontWeight', 'bold', 'FontSize', 11);
    h_txt(3) = text(ax, base(1), base(2), base(3)+L+1.5, 'U', ...
        'Color', [1.00, 1.00, 1.00], 'FontWeight', 'bold', 'FontSize', 11);
end

function update_coordinate_system(h_ex, h_ny, h_uz, h_txt, pe, pn, pd)
    L = 9;
    base = [pe-35, pn-35, -pd-22];

    if isgraphics(h_ex)
        set(h_ex, 'XData', base(1), 'YData', base(2), 'ZData', base(3), ...
            'UData', L, 'VData', 0, 'WData', 0);
    end
    if isgraphics(h_ny)
        set(h_ny, 'XData', base(1), 'YData', base(2), 'ZData', base(3), ...
            'UData', 0, 'VData', L, 'WData', 0);
    end
    if isgraphics(h_uz)
        set(h_uz, 'XData', base(1), 'YData', base(2), 'ZData', base(3), ...
            'UData', 0, 'VData', 0, 'WData', L);
    end

    if numel(h_txt) >= 3
        if isgraphics(h_txt(1))
            set(h_txt(1), 'Position', [base(1)+L+1.5, base(2), base(3)]);
        end
        if isgraphics(h_txt(2))
            set(h_txt(2), 'Position', [base(1), base(2)+L+1.5, base(3)]);
        end
        if isgraphics(h_txt(3))
            set(h_txt(3), 'Position', [base(1), base(2), base(3)+L+1.5]);
        end
    end
end

function V_spin = apply_prop_spin(V, meta, t)
    V_spin = V;
    if ~isfield(meta, 'prop_idx') || isempty(meta.prop_idx)
        return;
    end

    omega = 2*pi*11; % ~11 revolutions/sec visual prop speed
    ang = omega * t;
    c = cos(ang);
    s = sin(ang);
    Rx = [1, 0, 0; 0, c, -s; 0, s, c];

    idx = meta.prop_idx(:);
    hub = meta.prop_center;

    p = V_spin(idx, :) - hub;
    p = (Rx * p.').';
    V_spin(idx, :) = p + hub;
end

function V_rot = rotate(V, phi, theta, psi)
    cphi = cos(phi); sphi = sin(phi);
    cth = cos(theta); sth = sin(theta);
    cpsi = cos(psi); spsi = sin(psi);

    R_bi = [
        cth*cpsi,  sphi*sth*cpsi - cphi*spsi,  cphi*sth*cpsi + sphi*spsi;
        cth*spsi,  sphi*sth*spsi + cphi*cpsi,  cphi*sth*spsi - sphi*cpsi;
        -sth,      sphi*cth,                   cphi*cth
    ];

    V_rot = (R_bi * V.').';
end

function V_t = translate(V, pn, pe, pd)
    V_t = V + repmat([pn, pe, pd], size(V, 1), 1);
end

function Vp = ned_to_plot(V)
    R = [0, 1, 0; 1, 0, 0; 0, 0, -1];
    Vp = V * R;
end
