function out = conversions(mode, in)
%CONVERSIONS Common unit/frame conversion utility.
%   modes: 'deg2rad', 'rad2deg', 'ned2enu', 'enu2ned'

    switch lower(mode)
        case 'deg2rad'
            out = in*pi/180;
        case 'rad2deg'
            out = in*180/pi;
        case 'ned2enu'
            out = [in(2); in(1); -in(3)];
        case 'enu2ned'
            out = [in(2); in(1); -in(3)];
        otherwise
            error('conversions:UnsupportedMode', 'Unsupported conversion mode: %s', mode);
    end
end
