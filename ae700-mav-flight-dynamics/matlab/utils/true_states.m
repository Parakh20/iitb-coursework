function y = true_states(u)
% TRUE_STATES: Formats raw simulation data into an "Estimated State" vector.
%   u = [x(1:12); Va(13); alpha(14); beta(15); t(16)]
%   y = 19-element estimated state vector

    % 1. Extract raw states from the 16-element input
    pn    = u(1);
    pe    = u(2);
    pd    = u(3);
    u_b   = u(4);
    v_b   = u(5);
    w_b   = u(6);
    phi   = u(7);
    theta = u(8);
    psi   = u(9);
    p     = u(10);
    q     = u(11);
    r     = u(12);
    Va    = u(13);
    alpha = u(14);
    beta  = u(15);
    % t   = u(16); % Clock not used in this mapping

    % 2. Calculate Ground Speed (Vg) and Course (chi)
    % We need to project body velocities into the inertial (NED) frame
    cphi = cos(phi);   sphi = sin(phi);
    cth  = cos(theta); sth  = sin(theta);
    cpsi = cos(psi);   spsi = sin(psi);

    % Rotation matrix: Body to Inertial
    R_bi = [cth*cpsi, sphi*sth*cpsi-cphi*spsi, cphi*sth*cpsi+sphi*spsi;
            cth*spsi, sphi*sth*spsi+cphi*cpsi, cphi*sth*spsi-sphi*cpsi;
            -sth,     sphi*cth,                cphi*cth];
            
    V_inertial = R_bi * [u_b; v_b; w_b];
    Vn = V_inertial(1);
    Ve = V_inertial(2);
    
    Vg  = sqrt(Vn^2 + Ve^2);
    chi = atan2(Ve, Vn);

    % 3. Construct the 19-element output vector
    % Standard format for the Beard & McLain controller
    y = zeros(19, 1);
    y(1)  = pn;
    y(2)  = pe;
    y(3)  = pd;
    y(4)  = Va;
    y(5)  = alpha;
    y(6)  = beta;
    y(7)  = phi;
    y(8)  = theta;
    y(9)  = psi;
    y(10) = chi;
    y(11) = p;
    y(12) = q;
    y(13) = r;
    y(14) = Vg;
    y(15) = 0; % wn (Wind North estimate - set to 0 for now)
    y(16) = 0; % we (Wind East estimate - set to 0 for now)
    y(17) = 0; % bx (Gyro bias)
    y(18) = 0; % by (Gyro bias)
    y(19) = 0; % bz (Gyro bias)
end