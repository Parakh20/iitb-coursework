function y = forces_block(u)
%FORCES_BLOCK Simulink wrapper: u=[x(12);delta(4);wind(6)] -> y=forces_moments.

    P = evalin('base', 'P');

    x = u(1:12);
    delta = u(13:16);
    wind = u(17:22);

    y = forces_moments(x, delta, wind, P);
end
