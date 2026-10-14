function y = animation_block(u)
%ANIMATION_BLOCK Simulink wrapper for animation side effects.
%   u = [state(12); t]

    x = u(1:12);
    t = u(13);
    persistent warned last_t

    if isempty(last_t)
        last_t = -inf;
    end

    % Decimate redraws to keep simulation responsive.
    if (t - last_t) < 0.1
        y = 0;
        return;
    end
    last_t = t;

    try
        draw_aircraft(x, t);
    catch ME
        if isempty(warned) || ~warned
            warning('animation_block:DrawFailed', ...
                'Animation disabled during simulation: %s', ME.message);
            warned = true;
        end
    end
    y = 0;
end
