function tf_models = compute_tf(A, B, C, D)
%COMPUTE_TF Build representative transfer functions from linearized model.
%   If A/B/C/D are not provided, trim and linearization are computed first.

    if nargin < 4
        P = aircraft_parameters();
        [x_trim, u_trim] = compute_trim(25, 0, Inf, P);
        [A, B, C, D] = linearize_model(x_trim, u_trim, P);
    end

    tf_models = struct();
    tf_models.A = A;
    tf_models.B = B;
    tf_models.C = C;
    tf_models.D = D;

    if exist('ss', 'file') ~= 2 || exist('tf', 'file') ~= 2
        warning('compute_tf:ControlToolboxMissing', ...
            'Control System Toolbox not found. Returning only A/B/C/D matrices.');
        return;
    end

    sys = ss(A, B, C, D);

    tf_models.T_phi_delta_a = minreal(tf(sys(7, 2)));
    tf_models.T_theta_delta_e = minreal(tf(sys(8, 1)));
    tf_models.T_psi_delta_r = minreal(tf(sys(9, 3)));
    tf_models.T_u_delta_t = minreal(tf(sys(4, 4)));
end
