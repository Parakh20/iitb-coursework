function [J, residual] = trim_cost_function(x_trim, u_trim, Va, gamma, R, P)
%TRIM_COST_FUNCTION Evaluate trim residual cost for a candidate trim point.

    if nargin < 6 || isempty(P)
        P = aircraft_parameters();
    end
    if nargin < 5 || isempty(R)
        R = Inf;
    end
    if nargin < 4 || isempty(gamma)
        gamma = 0;
    end

    fm = forces_moments(x_trim, u_trim, zeros(6, 1), P);
    xdot = equations_of_motion(x_trim, fm(1:6), P);

    if nargin < 3 || isempty(Va)
        Va = fm(7);
    end

    if isfinite(R)
        psi_dot_des = Va*cos(gamma)/R;
    else
        psi_dot_des = 0;
    end

    residual = [
        xdot(3) + Va*sin(gamma);
        xdot(4:8);
        xdot(9) - psi_dot_des;
        xdot(10:12);
        fm(7) - Va;
        fm(9)
    ];

    J = residual.' * residual;
end
