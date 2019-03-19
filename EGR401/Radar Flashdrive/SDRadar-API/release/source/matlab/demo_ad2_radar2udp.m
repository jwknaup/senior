%% Title:    UDP Doppler-Range Plotting Client for Ancortek's SDR AD2
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

% Start fresh
clear all; close all;

% UDP Parameters - (These need to match the C++ end)
UDP_CLIENT_IP_ADDRESS = '10.0.0.120';
UDP_CLIENT_PORT = 9331;

% Setup the output figure
radar_fig = figure();

% Setup the UDP 0Network Port
u = udp(UDP_CLIENT_IP_ADDRESS);
set(u,'InputBufferSize', 8192);
set(u,'LocalPort', UDP_CLIENT_PORT);
set(u,'ByteOrder','littleEndian');
set(u,'Terminator','');
set(u,'Timeout',0.01);
set(u,'DatagramTerminateMode', 'On');
set(u,'DatagramReceivedFcn', {@plotRadarDataAD2, radar_fig});

% Open the port and flush the immedeate input
fopen(u);
flushinput(u);

% The program will now run until you press 'q'
%  in the open figure.
while (strcmp(u.Status, 'open'))
    pause(2);
end;

% Make sure the port is closed, then cleanup
fclose(u);
clear u;
