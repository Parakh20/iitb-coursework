function mav_dynamics(block)
    % Standard Level-2 Entry Point
    setup(block);
end

function setup(block)
    % --- 1. CONFIGURATION ---
    block.NumDialogPrms  = 1; % This is for your 'P' structure
    block.NumInputPorts  = 1;
    block.InputPort(1).Dimensions = 6; % [Fx Fy Fz l m n]
    block.InputPort(1).DirectFeedthrough = false;

    block.NumOutputPorts = 1;
    block.OutputPort(1).Dimensions = 12; % [pn pe pd u v w phi theta psi p q r]

    block.NumContStates = 12;
    block.SampleTimes = [0 0]; % Continuous time

    % --- 2. REGISTER METHODS ---
    block.RegBlockMethod('InitializeConditions', @InitializeConditions);
    block.RegBlockMethod('Outputs',              @Outputs);
    block.RegBlockMethod('Derivatives',          @Derivatives);
end

function InitializeConditions(block)
    % Pull P from the block parameters field
    P = block.DialogPrm(1).Data;
    
    % Set initial states exactly like your old x0
    block.ContStates.Data = [P.pn0; P.pe0; P.pd0; P.u0; P.v0; P.w0; ...
                             P.phi0; P.theta0; P.psi0; P.p0; P.q0; P.r0];
end

function Outputs(block)
    % Just like your old sys = x
    block.OutputPort(1).Data = block.ContStates.Data;
end

function Derivatives(block)
    % 1. Get current data
    P = block.DialogPrm(1).Data;
    u = block.InputPort(1).Data;
    x = block.ContStates.Data;
    
    % 2. Call your existing physics script
    % Ensure eom_6dof.m is in your current folder!
    sys = eom_6dof(x, u, P);
    
    % 3. Update the state derivatives
    block.Derivatives.Data = sys;
end