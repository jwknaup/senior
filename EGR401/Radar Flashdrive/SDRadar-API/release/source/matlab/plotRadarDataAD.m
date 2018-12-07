%% Title:    UDP Doppler-Range Plotting Client for Ancortek's SDR
%
% Author:   Ancortek Inc.
% Contact:  info@Ancortek.com
%
% Description:
%   The SDR_API class provide a simple and intuitive way to pull data from any
%   of Ancortek's SDR kits over USB. Check out demo.cpp for a
%   simple demonstration.
%
%   This program instantiates a UDP port to receive datagrams from our C++
%   source. The source will stream datagrams to a specific IP address and
%   port number. Make sure the address and port match the parameters below.
%   Once instantiated, this will call plotRadarDataAD2 whenever this client
%   receives enough data to plot a Doppler-Range image. Make sure that the
%   radar imaging parameters inside plotRadarDataAD2.m match the output of
%   the radar (this is not handled automaticall to save bandwidth).
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

function plotRadarDataAD( u, eventStruct, radar_fig )

% Setup Radar Parameters
f_bandwidth = 400e6;
f_carrier = 5.8e9;
sweep_length = 128;
sweep_period = 0.983e-3;
fft_interp_factor_range = 4;
fft_interp_factor_doppler = 4;

% Perform max range/velocity calculations
min_range = 5.9667e-09 * 3e8;
max_range = ((3e8 * sweep_length / 4 / f_bandwidth) + min_range) / 2;
max_velocity = 3e8 / sweep_period / 4 / f_carrier;

% Grab a dataset from the UDP port
data = fread(u, 4096, 'ushort');

% Make sure we received enough for a sweep
if (length(data) == 4096)
    
    % Extract Signal Components
    aQ = data(1:2:end) - (32768 .* (data(1:2:end) > 32767));
    aI = data(2:2:end);
    
    % Perform IQ Correction on Channel A
    miux = mean(aI);
    miuy = mean(aQ);
    I2_bar = mean((aI-miux).^2);
    Q2_bar = mean((aQ-miuy).^2);
    IQ_bar = mean((aI-miux).*(aQ-miuy));
    D_bar = IQ_bar/I2_bar;
    C_bar = sqrt(Q2_bar/I2_bar-D_bar^2);
    d_ampImb = sqrt(C_bar^2+D_bar^2)-1;
    phi = atan(D_bar/C_bar);
    aI = aI - miux;
    aQ = ((aQ - miuy)/(1+d_ampImb) - aI*sin(phi))/cos(phi);
    chA = aI + 1i*aQ;
    
    % Break down total sweep into individual sweeps
    sweeps = reshape(chA, sweep_length, (length(chA) / sweep_length));
    
    % Background Subtraction
    sweeps = bsxfun(@minus, sweeps,  sweeps(:,1)); 
    
    % FFT Range Processing
    sweeps = bsxfun(@times, sweeps,  hamming(size(sweeps, 1))); % FFT Range Filtering
    sweeps = fft(sweeps, [sweep_length * fft_interp_factor_range], 1) ./ size(sweeps,1);
    
    % Perform Range Compensation
    range_int_size = size(sweeps,1) / 2;
    axis_range = linspace(min_range, max_range, size(sweeps,1));
    for range_bin = 1:range_int_size
        sweeps(range_bin,:) = sweeps(range_bin,:) .* (axis_range(range_bin).^(1/4));
    end;
    
    % FFT Doppler Processing
    sweeps = bsxfun(@minus, sweeps,  mean(sweeps, 2)); % DC Subtract Velocity
    sweeps = bsxfun(@times, sweeps,  hamming(size(sweeps, 2))'); % FFT Velocity Filtering
    sweeps = fft(sweeps, [sweep_length * fft_interp_factor_doppler], 2) ./ size(sweeps,2);
    
    % FFT-Shift so zero velocity is in the center
    sweeps = fftshift(sweeps, 2);
    
    % Build the axis
    axis_velocity = linspace(-max_velocity, max_velocity, size(sweeps,2));
    
    % Convert to ABS
    sweeps = abs(sweeps).^2;  
    
    % Convert to log scale
    sweeps = 10*log10(sweeps);
    
    % Adjust the dynamic range
    O1 = mean(max(sweeps(1:range_int_size,:))); % min range of values in img
    O2 = 0.0; %max(max(sweeps(1:range_int_size,:)));  % max range of values in img
    T1 = 0.0;  % min range of target value
    T2 = 30.0;  % max range of target value
    sweeps = (((sweeps - O1) * (T2 - T1)) / (O2 - O1)) + T1;
    %disp(['O1: ' num2str(O1) ', O2: ' num2str(O2)]);
    
    % Determine maximum range bin
    max_doppler_bins = max(sweeps,[],2);
    [~, max_range_bin] = max(max_doppler_bins);
    max_range_bins = max(sweeps,[],1);
    [~, max_doppler_bin] = max(max_range_bins);
    
    % Plot Figure
    imagesc(axis_velocity, axis_range, sweeps, [0 30]);
    axis([-max_velocity max_velocity min_range max_range / 2]);
    xlabel('Doppler Velocity (m/s)');
    ylabel('Range (m)');
    title(['Target Doppler Velocity: ' num2str(axis_velocity(max_doppler_bin)) ' m/s, Target Range: ' num2str(axis_range(max_range_bin)) ' m']);
    colorbar();   

    % Display the figure
    drawnow;
    
    % Check if the user want's to quit
    if ishandle(radar_fig)
        if get(radar_fig,'currentkey') == 'q'
            fclose(u);
            close radar_fig;
        end;
    end;
else
    disp (length(data));    
end;

% End Function
end



