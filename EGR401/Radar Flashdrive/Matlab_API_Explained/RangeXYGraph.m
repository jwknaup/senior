%% Range-Doppler Plotter

% Functions needed in the Matlab path: 
% usbcheckchip.mexw64
% usbsetinterface1.mexw64
% usbfindendpoint.mexw64
% usbdownload.mexw64
% SDR_USB_FW.hex
% miniradargetdata.mexw64
% miniradarputdata.mexw64

%% USB device initialization
[device_coun, vID, pID] = usbcheckchip;
interface_no = usbsetinterface1;
handles.endpoint2_no = usbfindendpoint(2);
handles.endpoint6_no = usbfindendpoint(134);
fid = fopen('SDR_USB_FW.hex');
i=0; 
while 1
    tline = fgetl(fid);
    if tline == -1
        disp('Hex file read error');
        return
    end
    if tline(2:3) == '00'
        break
    end
    i = i+1;
    codedata{i,1} = int64(hex2dec(tline(2:3)));
    codedata{i,2} = uint16(hex2dec(tline(4:7)));
    bincode = uint8([]);
    for j = 10:2:(size(tline,2)-2)
        bincode((j-8)/2) = uint8(hex2dec(tline(j:(j+1))));
    end
    codedata{i,3} = bincode;
end
fclose(fid);
linesdone = usbdownload(codedata);

%% Radar parameters to send to the device
% MD (waveform): 
% fmcw_sawtooth: MD = 0;
% fmcw_triangle: MD = 1;
% fsk: MD = 2;
% cw: MD = 3

% SN (sampling number): 
% 128 samples/sweep: SN = 0;
% 256: SN = 1;
% 512: SN = 2;
% 1024: SN = 3;

% BW (bandwidth): (except for 24GHz products)
% 400 MHz: BW = 0;
% 100 MHz: BW = 1;
% 150 MHz: BW = 2;
% 300 MHz: BW = 3;

% For 24GHz products:
% 2000 MHz: BW = 0;
% 500 MHz: BW = 1;
% 750 MHz: BW = 2;
% 1500 MHz: BW = 3;

% ST (sweep time) for B series:
% 0.5ms: ST = 0;
% 1ms: ST = 1;
% 4ms: ST = 2;
% 10ms: ST = 3;

% ST (sweep time) in AD series:
% 1ms: ST = 0;
% 2ms: ST = 1;
% 4ms: ST = 2;
% 10ms: ST = 3;

% example: fmcw, 128 samples/sweep, 400MHz, 0.5ms sweep duration in B series
% or fmcw, 128 samples/sweep, 400MHz, 1ms sweep duration in AD series
% or fmcw, 128 samples/sweep, 2000MHz, 1ms sweep duration in 2400AD2
MD = 0; SN = 1; BW = 0; ST = 2;
%SN=0 => sweep length = 128
instruction = MD+SN*4+BW*16+ST*64+40960;
forwarddata = zeros(512,1)+instruction;
outdata = uint16(forwarddata);

%% Settings to request data from the device
% 128 samples/sweep
SPS = 256; 

% number of sweeps to request; for 0.5ms sweep duration, 10000 pulses -> 5s of data
NS = 100; 

% I&Q, so multiply by 2; 
% Request extra 2048 samples everytime and discard them.
% They are leftover in the internal buffer.
data_length = 4*(ceil(NS*SPS/512)*512+1024)+2048;

% for AD2, dual-receiving channel models:
% data_length = NTS * NP * 2 * 2 + 2048;

% fft settings
sweep_length=256;
fft_interp_factor_range = 4;
fft_interp_factor_doppler = 1;

%radar cinfiguration properties
sweep_period = 1.0e-3;
f_bandwidth = 400e6;
f_carrier = 5.8e9;
% Perform max range/velocity calculations
min_range = 5.9667e-09 * 3e8;
min_range = 0.5;
max_range = ((3e8 * sweep_length / 4 / f_bandwidth) + min_range) / 2;
max_velocity = 3e8 / sweep_period / 4 / f_carrier;

samp_rate =1/sweep_period*SPS;

lightspeed = 3e8;

rd_axes = axes;

% Exmaple code structure:
%
% Radar device initialization  
%
%% while loop start 
while(1)
    
    % device interface
    % use miniradarpuetdata() to send an instruction to the
    % radar, regardless of whether the radar parameters need to be changed
    outlength = miniradarputdata(outdata, handles.endpoint2_no);
    %
    % use miniradargetdata() to request data from the device
    tic;
    [data,inlength] = miniradargetdata(handles.endpoint6_no,data_length);
    toc;
    
    %% signal processing
    %strip off the excess leftover data we requested
    rawdata = double(data(2049:end));
    % find data section start
    index = find(rawdata>=32768);
    % remove flag from data starts
    rawdata(index) = rawdata(index) - 32768;
    %make sure we got valid amount of data
    if (length(rawdata) ~= data_length-2048)
        disp(length(data));    
        break;
    end;
    
    Filename = sprintf('training_data/raw/datas_%s.mat', datestr(now,'HH-MM-SS'));
    save(Filename,'rawdata');
    
    %% Iterate through the two channels
    for channel = 1:1

        %% Prepare general signal processing
        channel_index = (channel - 1) * 2 + 1;

        %define upper and lower cutoff frequencies
        notchfreq = 1;
        if notchfreq >= samp_rate/2.5
            notchfreq = samp_rate/2.5;
        end
        F1 = 2*notchfreq/samp_rate;
        F2 = 2*samp_rate/2.1/samp_rate;
        F12 = [F1,F2];
        %generate (2*N)th order Butterworth band-pass filter
        %with upper and lower frequencies F1 and F2
        N = 8;
        [BF,AF] = butter(N,F12);

        %% RangeDoppler Specific Signal Processing
        %get the data from all the sweeps we requested and all the samples
        %in each sweep and for both channels and I & Q data
        Rawdata = rawdata(index(1):index(1)+NS*SPS*4-1);
        % get just the Q (imaginary) data for one channel
        % arbitrary choice, could use real data instead
        A = Rawdata(channel_index:4:end);

        %reshape into 2D array with dimensions samplesPerSweep x #sweeps
        B = reshape(A,SPS,NS);                   
        DOPPLER_FFT_SIZE = 128;
        RANGE_FFT_SIZE = 512;
        DOPP_FREQ = 1/sweep_period;
        
        %normalize every sweep of B
        B = B - mean(B);
        %apply butterworth bandpass filter created above
        B = filter(BF,AF,B,[],1); % maybe take this out?

        %extract frequency
        C = fft(B,RANGE_FFT_SIZE,1);
        %take just the first half of each sweep?
        D = C(1:RANGE_FFT_SIZE/2,:);
        %normalize each sample across all sweeps
        D = D - mean(D,2);

        notch_vr = 0.01;
        notch_doppler = 2*notch_vr/(lightspeed/f_carrier);                      
        stopfreq = notch_doppler;
        if stopfreq > DOPP_FREQ/3
            stopfreq = DOPP_FREQ/3.1;
        end
        passfreq = 1.5*stopfreq;
        ws = stopfreq/(DOPP_FREQ/2);
        wp = passfreq/(DOPP_FREQ/2);
        Rp = 2;
        Rs = 30;
        [N,Wn] = buttord(wp,ws,Rp,Rs);
        [num,den] = butter(N,Wn,'high'); % Highpass filter

        VrNotch = 0;                   
        if VrNotch == 1
            D = filter(num,den,D,[],2); % Doppler Notch filter
        end

        % find the frequency of the frequencies (across the rows)
        E = fft(D,DOPPLER_FFT_SIZE,2);
        % then shift to center around zero component and scale
        final_range_doppler_data = abs(fftshift(E,2)).^2/DOPPLER_FFT_SIZE;  
        indices = find(abs(final_range_doppler_data)<6000);
%         final_range_doppler_data(indices) = 0;

        [RngIdx,DopplerIdx] = find(final_range_doppler_data==max(max(final_range_doppler_data)));
        surfX = linspace(-DOPP_FREQ/2,DOPP_FREQ/2,DOPPLER_FFT_SIZE)*(lightspeed)/f_carrier/2;
        surfY = linspace(0,samp_rate/2,RANGE_FFT_SIZE/2)*lightspeed*sweep_period/(2*f_bandwidth);
        RangeInfo = surfY(RngIdx(1));
        VeloInfo = surfX(DopplerIdx(1));                              
%             set(handles.PeakValue,'String',num2str(RangeInfo),'Foregroundcolor','blue');
%             set(handles.VeValue,'String',num2str(VeloInfo),'Foregroundcolor','blue');

        tic;
%             axes2 = axes;    
        cla(rd_axes,'reset');
        %plot the data corresponding to the x and y coordinates defined by
        %surfX and surfY, and height (color) defined by range doppler data
        surface(surfX, surfY, final_range_doppler_data, 'EdgeColor', 'none');
        DopplerX = 10;
        DopplerY = 20;
        axis([-DopplerX DopplerX 0 DopplerY]);
        xlabel('Velocity(m/s)');
        ylabel('Range(m)');
        toc;
        range_doppler_results(channel) = final_range_doppler_data;

    % End Channel Iteration    
    end;
    
    %% 2D
    
    for channel = 1:2
        distances(channel) = sum(range_doppler_results(channel), 2);
        maximum = max(distances);
        distances(distances<maximum/5) = 0;
        groups(channel) = bwconncomp(distances);

        total = sum(distances);
        weights = 1:size(distances, 1);
        average = sum(distances .* weights')/total

        numGroups = size(groups.PixelIdxList, 2);
    end
    
    groupData = zeros(numGroups, 4);
    i=1;
    
    for group = groups.PixelIdxList
        group = cell2mat(group);
        weights = group(1):group(end);
        total = sum(distances(weights));
        average = sum(distances(weights) .* weights')/total;
        weight = sum(distances(weights)) / size(weights,2);
        
            A = [-0.5 0]; %# center of the first circle
            B = [0.5 0]; %# center of the second circle
            a = surfY(int32(average)) %# radius of the SECOND circle
            b = surfY(int32(average)); %# radius of the FIRST circle
            c = norm(A-B); %# distance between circles

            cosAlpha = (b^2+c^2-a^2)/(2*b*c);

            u_AB = (B - A)/c; %# unit vector from first to second center
            pu_AB = [u_AB(2), -u_AB(1)]; %# perpendicular vector to unit vector

            %# use the cosine of alpha to calculate the length of the
            %# vector along and perpendicular to AB that leads to the
            %# intersection point
            intersection = A + u_AB * (b*cosAlpha) + pu_AB * (b*sqrt(1-cosAlpha^2));
            if (intersection(1,2) < 0)
                intersection = A + u_AB * (b*cosAlpha) - pu_AB * (b*sqrt(1-cosAlpha^2));             
            end
            
        groupData(i,:) = [average, weight/1e6, intersection];    
        i=i+1;
    end
    
    groupData
    
    distance = groupData(1,1);


    tic;
    %% Display the figure
    drawnow limitrate;
    Filename = sprintf('training_data/images/fig_%s.png', datestr(now,'HH-MM-SS'));
    saveas(rd_axes, Filename);
    toc;

    % Check if the user want's to quit
    if isvalid(rd_axes) == 0
        return;
    end;

% while loop end
end;

%near and far, static and moving, which waveform, then deep learning
