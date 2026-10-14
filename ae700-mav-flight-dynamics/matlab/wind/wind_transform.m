function [wind_b, v_air, air_data] = wind_transform(x, wind)
%WIND_TRANSFORM Convert inertial wind to body frame and compute air data.
%   wind = [wn we wd u_g v_g w_g]' or [wn we wd]'.

    if numel(wind) == 3
        wind = [wind(:); 0; 0; 0];
    else
        wind = wind(:);
    end

    phi = x(7);
    theta = x(8);
    psi = x(9);
    [R_bi, R_ib] = rotation_matrices(phi, theta, psi);

    steady_i = wind(1:3);
    gust_b = wind(4:6);
    wind_b = R_ib*steady_i + gust_b;

    v_body = x(4:6);
    v_air = v_body - wind_b;

    Va = max(norm(v_air), 1e-6);
    alpha = atan2(v_air(3), v_air(1));
    beta = asin(max(min(v_air(2)/Va, 1), -1));

    air_data = [Va; alpha; beta; (steady_i + R_bi*gust_b)];
end
