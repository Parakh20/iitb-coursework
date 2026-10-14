function [sys, x0, str, ts, simStateCompliance] = mav_dynamics_sfunc(t, x, u, flag, P)
%MAV_DYNAMICS_SFUNC Simulink continuous-time S-function for 6-DOF MAV.
%   Inputs : [Fx Fy Fz l m n]'
%   States : [pn pe pd u v w phi theta psi p q r]'
%   Outputs: state vector

    switch flag
        case 0
            [sys, x0, str, ts, simStateCompliance] = mdlInitializeSizes(P);
        case 1
            sys = mdlDerivatives(x, u, P);
        case 2
            sys = mdlUpdate();
        case 3
            sys = mdlOutputs(x);
        case 4
            sys = mdlGetTimeOfNextVarHit(t);
        case 9
            sys = mdlTerminate();
        otherwise
            error('mav_dynamics_sfunc:UnhandledFlag', 'Unhandled flag: %d', flag);
    end
end

function [sys, x0, str, ts, simStateCompliance] = mdlInitializeSizes(P)
    sizes = simsizes;
    sizes.NumContStates = 12;
    sizes.NumDiscStates = 0;
    sizes.NumOutputs = 12;
    sizes.NumInputs = 6;
    sizes.DirFeedthrough = 0;
    sizes.NumSampleTimes = 1;
    sys = simsizes(sizes);

    x0 = [P.pn0; P.pe0; P.pd0; P.u0; P.v0; P.w0; P.phi0; P.theta0; P.psi0; P.p0; P.q0; P.r0];
    str = [];
    ts = [0 0];
    simStateCompliance = 'UnknownSimState';
end

function sys = mdlDerivatives(x, u, P)
    sys = eom_6dof(x, u, P);
end

function sys = mdlUpdate()
    sys = [];
end

function sys = mdlOutputs(x)
    sys = x;
end

function sys = mdlGetTimeOfNextVarHit(t)
    sys = t + 1;
end

function sys = mdlTerminate()
    sys = [];
end
