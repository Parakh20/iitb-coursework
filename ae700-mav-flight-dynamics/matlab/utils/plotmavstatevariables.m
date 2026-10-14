function plotMAVStateVariables(uu)
    % 1. Data Padding
    if length(uu) < 54
        uu = [uu; zeros(54 - length(uu), 1)];
    end
    
    % 2. Extract Data
    t = uu(54);
    pn = uu(1); pe = uu(2); h = -uu(3);
    Va = uu(13); alpha = 180/pi*uu(14); beta = 180/pi*uu(15);
    phi = 180/pi*uu(7); theta = 180/pi*uu(8); r = 180/pi*uu(12);
    delta_e = 180/pi*uu(50); delta_t = uu(53);
    
    % 3. Persistent Handles & Timer
    persistent fig_h pn_h pe_h h_h Va_h alpha_h beta_h phi_h theta_h r_h de_h dt_h last_t
    
    % 4. Initialization (t=0)
    if t == 0 || isempty(fig_h) || ~isgraphics(fig_h)
        last_t = t;
        fig_h = figure(2);
        set(fig_h, 'Name', 'Pioneer MAV States', 'NumberTitle', 'off');
        clf(fig_h);
        
        subplot(4,3,1); pn_h = plot(t, pn, 'b'); ylabel('p_n (m)'); grid on;
        subplot(4,3,2); pe_h = plot(t, pe, 'b'); ylabel('p_e (m)'); grid on;
        subplot(4,3,3); h_h = plot(t, h, 'b'); ylabel('h (m)'); grid on;
        subplot(4,3,4); Va_h = plot(t, Va, 'r'); ylabel('V_a (m/s)'); grid on;
        subplot(4,3,5); alpha_h = plot(t, alpha, 'r'); ylabel('\alpha (deg)'); grid on;
        subplot(4,3,6); beta_h = plot(t, beta, 'r'); ylabel('\beta (deg)'); grid on;
        subplot(4,3,7); phi_h = plot(t, phi, 'g'); ylabel('\phi (deg)'); grid on;
        subplot(4,3,8); theta_h = plot(t, theta, 'g'); ylabel('\theta (deg)'); grid on;
        subplot(4,3,9); r_h = plot(t, r, 'g'); ylabel('yaw rate (deg/s)'); grid on;
        subplot(4,3,10); de_h = plot(t, delta_e, 'k'); ylabel('\delta_e (deg)'); grid on;
        subplot(4,3,11); dt_h = plot(t, delta_t, 'k'); ylabel('\delta_t'); grid on;
        return;
    end

    % --- THE FOCUS FIX: Drop frames to allow 3D animation to breathe ---
    if (t - last_t) < 0.1 
        return; 
    end
    last_t = t;

    % 5. Fast Update
    update_line(pn_h, t, pn); update_line(pe_h, t, pe); update_line(h_h, t, h);
    update_line(Va_h, t, Va); update_line(alpha_h, t, alpha); update_line(beta_h, t, beta);
    update_line(phi_h, t, phi); update_line(theta_h, t, theta); update_line(r_h, t, r);
    update_line(de_h, t, delta_e); update_line(dt_h, t, delta_t);
    
    drawnow limitrate;
end

function update_line(h, t, y)
    if isgraphics(h)
        xdata = get(h,'XData');
        ydata = get(h,'YData');
        
        % Append
        xdata(end+1) = t;
        ydata(end+1) = y;
        
        % --- THE LAG FIX: 15-Second Sliding Window ---
        window = 15;
        if (t - xdata(1)) > window
            idx = find(xdata >= (t - window), 1, 'first');
            xdata = xdata(idx:end);
            ydata = ydata(idx:end);
        end
        
        set(h, 'XData', xdata, 'YData', ydata);
        
        % Silently update axes
        ax = h.Parent;
        ax.XLim = [max(0, t - window), max(window, t)];
    end
end