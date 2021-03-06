%% ************************************************************************
%  GPSPlots (nested function)
%  ************************************************************************
%  Display the gps data from the log file. Assumes that successfully GPS
%  data was logged.
%  TODO: - properly scale the axes, maybe convert it to a local Cartesian
%          frame or plot it in spherical coordinates.
%        - Add a callback to get position and extra information (airspeed,
%          gps velocity from a certain point in the plot.

function GPSPlots(sysvector, topics, fconv_gpsalt, fconv_gpslatlong, plotvector)
% 3D plot of the gps position
fig1 = figure(1);
fig1.Name = 'GPS Position 3D';

if plotvector.colorModeGPS == 2
    plot3(double(sysvector('vehicle_gps_position.lat').Data)*fconv_gpslatlong, ...
        double(sysvector('vehicle_gps_position.lon').Data)*fconv_gpslatlong, ...
        double(sysvector('vehicle_gps_position.alt').Data)*fconv_gpsalt,'r', ...
        'Linewidth', 2);
    title('GPS Position Data');
else
    lat = sysvector('vehicle_gps_position.lat').Data*fconv_gpslatlong;
    lon = sysvector('vehicle_gps_position.lon').Data*fconv_gpslatlong;
    alt = sysvector('vehicle_gps_position.alt').Data*fconv_gpsalt;
    
    if plotvector.colorModeGPS == 1
        gps_vel = CalcGPSHorizontalVelocity(sysvector, topics);
        color = gps_vel.Data;
        title('GPS Position Data (Colored by the horizontal GPS velocity [m/s])');
    elseif plotvector.colorModeGPS == 3
        color = sysvector('vehicle_gps_position.vel').Data;
        title('GPS Position Data (Colored by the GPS velocity [m/s])');
    elseif plotvector.colorModeGPS == 4
        if ~topics.airspeed.logged
           error('The airspeed topic is not logged which is required for plotvector.colorModeGPS == 4')
        end
        
        title('GPS Position Data (Colored by the GPS velocity [m/s])');
        % interpolate airspeed
        airspeed = sysvector('airspeed.true_airspeed');
        if (airspeed.Time(1) > sysvector('vehicle_gps_position.lat').Time(1))
            airspeed = addsample(airspeed, 'Data', airspeed.Data(1), 'Time', ...
                sysvector('vehicle_gps_position.lat').Time(1));
        end
        if (airspeed.Time(end) < sysvector('vehicle_gps_position.lat').Time(end))
            airspeed = addsample(airspeed, 'Data', airspeed.Data(end), 'Time', ...
                sysvector('vehicle_gps_position.lat').Time(end));
        end
        airspeed = resample(airspeed, sysvector('vehicle_gps_position.lat').Time);
        color = airspeed.Data;
    else
        color = alt;
        title('GPS Position Data (Colored by the GPS altitude [m])');
    end

    surface([lat(:),lat(:)],[lon(:),lon(:)],[alt(:),alt(:)],[color(:),color(:)],...
            'FaceColor','no',...
            'EdgeColor','interp',...
            'LineWidth',2);
    colorbar
end
xlabel('Latitude [deg]');
ylabel('Longitude [deg]');
zlabel('Altitude above MSL [m]');
grid on

% set axis limits
min_lat = min(sysvector('vehicle_gps_position.lat').Data)*fconv_gpslatlong;
min_lon = min(sysvector('vehicle_gps_position.lon').Data)*fconv_gpslatlong;
max_lat = max(sysvector('vehicle_gps_position.lat').Data)*fconv_gpslatlong;
max_lon = max(sysvector('vehicle_gps_position.lon').Data)*fconv_gpslatlong;
diff_plot = max(max_lat-min_lat, max_lon-min_lon);
axis([min_lat+0.5*(max_lat-min_lat-diff_plot) min_lat+0.5*(max_lat-min_lat+diff_plot)...
    min_lon+0.5*(max_lon-min_lon-diff_plot) min_lon+0.5*(max_lon-min_lon+diff_plot) -inf inf])

% GPS velocity plot
fig2 = figure(2);
fig2.Name = 'GPS Velocity';
hold on;
plot(sysvector('vehicle_gps_position.vel_n').Time,sysvector('vehicle_gps_position.vel_n').Data);
plot(sysvector('vehicle_gps_position.vel_e').Time,sysvector('vehicle_gps_position.vel_e').Data);
plot(sysvector('vehicle_gps_position.vel_d').Time,sysvector('vehicle_gps_position.vel_d').Data);
hold off;
title('GPS Velocity (NED frame) [m/sec]');
legend('V_N','V_E','V_D');
grid on;

fig3 = figure(3);
fig3.Name = 'GPS Accuracy/DOP';
raw(1)=subplot(5,2,1);
plot(sysvector('vehicle_gps_position.eph').Time,sysvector('vehicle_gps_position.eph').Data);
title('GPS horizontal position accuracy (eph) [m]');

raw(2)=subplot(5,2,2);
plot(sysvector('vehicle_gps_position.epv').Time,sysvector('vehicle_gps_position.epv').Data);
title('GPS vertical position accuracy (epv) [m]');

raw(3)=subplot(5,2,3);
plot(sysvector('vehicle_gps_position.hdop').Time,sysvector('vehicle_gps_position.hdop').Data);
title('Horizontal dilution of precision (hdop)');

raw(4)=subplot(5,2,4);
plot(sysvector('vehicle_gps_position.vdop').Time,sysvector('vehicle_gps_position.vdop').Data);
title('Vertical dilution of precision (vdop)');

raw(5)=subplot(5,2,5);
plot(sysvector('vehicle_gps_position.fix_type').Time,sysvector('vehicle_gps_position.fix_type').Data);
title('GPS fix type');

raw(6)=subplot(5,2,6);
plot(sysvector('vehicle_gps_position.satellites_used').Time,sysvector('vehicle_gps_position.satellites_used').Data);
title('GPS number of used satellites');

raw(7)=subplot(5,2,7);
plot(sysvector('vehicle_gps_position.s_variance').Time,sysvector('vehicle_gps_position.s_variance').Data);
title('GPS estimated speed variance');

raw(8)=subplot(5,2,8);
plot(sysvector('vehicle_gps_position.c_variance').Time,sysvector('vehicle_gps_position.c_variance').Data);
title('GPS Estimated course variance');

raw(9)=subplot(5,2,9);
plot(sysvector('vehicle_gps_position.noise_per_ms').Time,sysvector('vehicle_gps_position.noise_per_ms').Data);
title('GPS Noise per ms');

raw(10)=subplot(5,2,10);
plot(sysvector('vehicle_gps_position.jamming_indicator').Time,sysvector('vehicle_gps_position.jamming_indicator').Data);
title('GPS Jamming Indicator');

linkaxes(raw(:),'x');
set(raw(:),'XGrid','on','YGrid','on','ZGrid','on');   
end