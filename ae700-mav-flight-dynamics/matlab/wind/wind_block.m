function y = wind_block(u)
%WIND_BLOCK Simulink wrapper for steady NED + Dryden gust wind model.
%   u is expected to contain current simulation time, u(1)=t.
%   output y = [wn we wd u_g v_g w_g]'.

    if nargin < 1 || isempty(u)
        t = 0;
    else
        t = u(1);
    end

    P = evalin('base', 'P');

    if evalin('base', 'exist(''wind_cfg'',''var'')')
        wind_cfg = evalin('base', 'wind_cfg');
    else
        wind_cfg = struct();
    end

    y = gust_model(t, P, wind_cfg);
end
