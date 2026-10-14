function xdot = equations_of_motion(x, fm, P)
%EQUATIONS_OF_MOTION Compatibility wrapper for 6-DOF dynamics.
    xdot = eom_6dof(x, fm, P);
end
