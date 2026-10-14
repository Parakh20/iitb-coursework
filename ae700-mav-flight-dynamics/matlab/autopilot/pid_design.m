function gains = pid_design(wn, zeta, ki_ratio)
%PID_DESIGN Basic second-order PID gain template for quick controller setup.

    if nargin < 1 || isempty(wn)
        wn = 1.0;
    end
    if nargin < 2 || isempty(zeta)
        zeta = 0.707;
    end
    if nargin < 3 || isempty(ki_ratio)
        ki_ratio = 0.2;
    end

    gains = struct();
    gains.kp = wn^2;
    gains.kd = 2*zeta*wn;
    gains.ki = ki_ratio*wn*gains.kp;
end
