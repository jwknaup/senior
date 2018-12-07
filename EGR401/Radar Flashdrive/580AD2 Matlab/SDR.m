%%%% Ancortek Matlab GUI for 1Tx, 2Rx 5.8GHz Radar.
% For any question, please contact at info@ancortek.com
% adjusted the code for the new firmware with longer buffer
%
% Note: ANCORTEK Inc fully supports any research work using
% SDR-KITs and provides MATLAB GUI and source codes upon request.
% The MATLAB GUI and MATLAB source codes are provided "as is", 
% with no guarantee whatsoever, and for non-commercial use only.  
% The ANCORTEK Inc will not be liable for any damage caused.


function varargout = SDR(varargin)
% SDR MATLAB code for SDR.fig
%      SDR, by itself, creates a new SDR or raises the existing
%      singleton*.
%
%      H = SDR returns the handle to a new SDR or the handle to
%      the existing singleton*.
%
%      SDR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SDR.M with the given input arguments.
%
%      SDR('Property','Value',...) creates a new SDR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SDR_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SDR_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SDR

% Last Modified by GUIDE v2.5 08-Apr-2016 14:33:30

% Begin initialization co de - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SDR_OpeningFcn, ...
                   'gui_OutputFcn',  @SDR_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SDR is made visible.
function SDR_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SDR (see VARARGIN)

% Choose default command line output for SDR
handles.cali_sig = 0;
handles.SettingChange = 0;
handles.recorded = 0;

set(handles.VrNotchFilter,'Value',0);
set(handles.NotchVrSlider,'Value',0);
set(handles.NotchVrDisplay,'String',0);

set(handles.butterfilter,'Value',1);
set(handles.NotchSlider,'Value',0);
set(handles.NotchDisplay,'String',0);

%% axis zoom begin
handles.StreamX = 0;
handles.StreamY = 0;
handles.WaterfallX = 0;
handles.WaterfallY = 0;
handles.RangeX = 0;
handles.RangeY = 0;
handles.DopplerX = 0;
handles.DopplerY = 0;
%% zoom end

set(handles.I_state,'Value',1);
set(handles.Q_state,'Value',1);
set(handles.rgb_state,'Value',1);
set(handles.color,'Visible','off');
set(handles.waterfallaxes,'Visible','off');

set(handles.record,'Enable','off');
set(handles.save,'Enable','off');
set(handles.record_time,'Enable','off');
set(handles.replay,'Enable','off');
set(findall(handles.waveform, '-property', 'enable'), 'enable', 'off');
set(findall(handles.ParameterPanel, '-property', 'enable'), 'enable', 'off');
set(findall(handles.WindowPanel, '-property', 'enable'), 'enable', 'off');

set(handles.info,'UserData',0);
set(handles.start,'UserData',0);

axes(handles.sawtooth);
plot([1 2 2 3 3],[0 1 0 1 0],'k');
axis off;
axes(handles.triangle);
plot([0 1 2 3 4],[0 1 0 1 0],'k');
axis off;
axes(handles.continuous);
plot([1 2 3],[1 1 1],'k');
axis off;
axes(handles.fskwave);
plot([0 1 1 2 2 3 3 4 4],[0 0 1 1 0 0 1 1 0],'k');
axis off;
axes(handles.I_Color);
sinewave_x = linspace(0,4*pi,20);
plot(sin(sinewave_x),'y');
axis off;
axes(handles.Q_Color);
plot(sin(sinewave_x),'g');
axis off;

handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SDR wait for user response (see UIRESUME)
% uiwait(handles.SDR);

% --- Outputs from this function are returned to the command line.
function varargout = SDR_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of start
handles.radarmodel = 5.8e9;
handles.lightspeed = 3e8;
handles.recorded = 0;
set(handles.message,'String',' ');

% try
    [device_count vID pID] = usbcheckchip;
    if (device_count > 1)
        set(handles.message,'String','More than one USB board','ForegroundColor','red');
        return
    elseif device_count == 0
        set(handles.message,'String','No USB board found','ForegroundColor','red');
        return
    end
    if (vID~=1204) || (pID~=34323)
        set(handles.message,'String','Wrong USB chip','ForegroundColor','red');
        return
    end
    interface_no = usbsetinterface1;
    if interface_no~=1
        set(handles.message,'String','Set interface failure','ForegroundColor','Green');
        return
    end
    handles.endpoint2_no = usbfindendpoint(2);
    if handles.endpoint2_no == 0
        set(handles.message,'String','Could not find endpoint 2','ForegroundColor','red');
        return
    end
    handles.endpoint6_no = usbfindendpoint(134);
    if handles.endpoint6_no == 0
        set(handles.message,'String','Could not find endpoint 6','ForegroundColor','red');
        return
    end
    fid = fopen('SDR_USB_FW.hex');
    if fid == -1
        set(handles.message,'String','Hex file error','ForegroundColor','red');
        return
    end
    i=0;
    while 1
        tline = fgetl(fid);
        if tline == -1
            set(handles.message,'String','Hex file read     error','ForegroundColor','red');
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
    if linesdone~=(i-1)
        set(handles.message,'String','Firmware download error','ForegroundColor','red');
        return
    end
       
    if (get(handles.start,'Value')) == (get(handles.start,'Max'))
        set(handles.start, 'String', 'Stop');
        set(handles.start,'UserData',1);
        set(handles.record_time,'Enable','off');
        set(handles.record,'Enable','Off');
        set(handles.save,'Enable','Off');
        set(handles.replay,'Enable','off');
        set(handles.info,'Enable','off');
        set(findall(handles.waveform, '-property', 'enable'), 'enable', 'on');
        set(findall(handles.ParameterPanel, '-property', 'enable'), 'enable', 'on');
        set(findall(handles.WindowPanel, '-property', 'enable'), 'enable', 'on');
    else
        set(handles.start, 'String', 'Start');
        set(handles.start,'UserData',0);
        set(handles.record_time,'Enable','on');    
        set(handles.record,'Enable','On');
        set(handles.save,'Enable','On');
        set(handles.replay,'Enable','on');
        set(handles.info,'Enable','on');
        set(findall(handles.waveform, '-property', 'enable'), 'enable', 'off');
        set(findall(handles.ParameterPanel, '-property', 'enable'), 'enable', 'off');
        set(findall(handles.WindowPanel, '-property', 'enable'), 'enable', 'off');
    end  

    guidata(hObject,handles);

    m = 100;
    CWWF_flag = 0;
    CWHx_flag = 0;
    FMCWWF_flag = 0;
    TriRng_flag = 0;
    TriV_flag = 0;
    FskRng_flag = 0;
    FskV_flag = 0;
    start_up = 1;
    
    while (get(handles.start,'Value')) == (get(handles.start,'Max'))
        
        select = get(handles.waveform,'SelectedObject');
        switch get(select,'tag')
            case 'fmcw_sawtooth'
                MD = 0;
            case 'fmcw_triangle'
                MD = 1;
            case 'fsk'
                MD = 2; 
            case 'cw'
                MD = 3;
            otherwise
                MD = 0;
        end

        contents1 = get(handles.DurationSelection,'Value');
        switch contents1
            case 1
                ST = 0; SweepTime = 1; PN = 32;
            case 2
                ST = 1; SweepTime = 2; PN = 32;
            case 3
                ST = 2; SweepTime = 4; PN = 32;
            case 4
                ST = 3; SweepTime = 10; PN = 32;                
            otherwise
                ST = 0; SweepTime = 1; PN = 32;
        end

        contents2 = get(handles.SNSelection,'Value');
        switch contents2
            case 1                       
                SN = 0; NTS = 128;
            case 2                       
                SN = 1; NTS = 256;
            case 3
                SN = 2; NTS = 512;
            case 4
                SN = 3; NTS = 1024;                
            otherwise
                SN = 0; NTS = 128;
        end

        contents3 = get(handles.BWSelection,'Value');
        switch contents3
            case 1
                BW = 0;
                BandWidth = 400e6;
            case 2
                BW = 1;
                BandWidth = 100e6;
            case 3
                BW = 2;
                BandWidth = 150e6;
            case 4
                BW = 3;
                BandWidth = 300e6;    
            otherwise
                BW = 0;
                BandWidth = 400e6;
        end
        
%=======================  added below 02/23/2017 ==========================
            instruction = MD+SN*4+BW*16+ST*64+40960; 
            forwarddata = zeros(512,1)+instruction;
            outdata = uint16(forwarddata); 
            outlength = miniradarputdata(outdata, handles.endpoint2_no);
            if outlength == 0
                set(handles.message,'String','data transfer error','ForegroundColor','red');
                return
            end              
            set(handles.message,'String','Connected','ForegroundColor','Green');
%====================== added above 02/23/2017 ============================
   
%%%%%%%% FMCW Data Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%
        if (MD == 0) %% Sawtooth
            
            handles.CarrierFreq = handles.radarmodel;
            set(handles.RangeProfile,'String','Range Profile');
            set(handles.RangeDoppler,'String','Range Doppler');
            set(handles.freqshow,'String',[num2str(handles.CarrierFreq/1e9-BandWidth/2e9)...
                '-' num2str(handles.CarrierFreq/1e9+BandWidth/2e9)]);
            samp_rate =1/SweepTime*NTS*1000;

%=======================  added below 02/23/2017 ==========================
            instruction = MD+SN*4+BW*16+ST*64+40960; 
            forwarddata = zeros(512,1)+instruction;
            outdata = uint16(forwarddata); 
            outlength = miniradarputdata(outdata, handles.endpoint2_no);
            if outlength == 0
                set(handles.message,'String','data transfer error','ForegroundColor','red');
                return
            end              
            set(handles.message,'String','Connected','ForegroundColor','Green');
%====================== added above 02/23/2017 ============================

            data_length = 4*(ceil(PN*NTS/512)*512+1024)+2048;
            %1024->2048 02/23/2017
            [data,inlength] = miniradargetdata(handles.endpoint6_no,data_length);
            if inlength == 0
                set(handles.message,'String','No data 1','ForegroundColor','red');
                return
            end
            datatrump = double(data(2049:end)); %1025->2049 02/23/2017
            index = find(datatrump>=32768);
            datatrump(index) = datatrump(index) - 32768;

            N_avg = 5; %Averaging
            datatrump; %20480
            datastream = datatrump(index(1):index(1)+N_avg*NTS*4-1);
            switch get(handles.CHSelection,'Value')
                case 1
                    IData = datastream(2:4:end); % I data of channel 1
                    QData = datastream(1:4:end); % Q data of channel 1
                case 2
                    IData = datastream(4:4:end); % I data of channel 2
                    QData = datastream(3:4:end); % Q data of channel 2
                otherwise
                    IData = datastream(2:4:end); % I data of channel 1
                    QData = datastream(1:4:end); % Q data of channel 1
            end
            IMatrix = reshape(IData,NTS,N_avg);
            QMatrix = reshape(QData,NTS,N_avg);
            I_rawdata = mean(IMatrix,2);
            Q_rawdata = mean(QMatrix,2);

            if handles.SettingChange == 0
                handles.MD = MD;
                handles.ST = ST;
                handles.SN = SN;
                handles.BW = BW;
                handles.SettingChange = 1;
                setappdata(handles.StreamX,'Xlimit',NTS);
                setappdata(handles.StreamY,'Ylimit',800);
                setappdata(handles.WaterfallX,'WXlimit',samp_rate/2*handles.lightspeed*SweepTime/1000/(2*BandWidth));
                setappdata(handles.WaterfallY,'WYlimit',m-1);
                setappdata(handles.RangeX,'RXlimit',samp_rate/2*handles.lightspeed*SweepTime/1000/(2*BandWidth));
                setappdata(handles.RangeY,'RYlimit',55);
                setappdata(handles.DopplerX,'DXlimit',1/SweepTime*1000/2*(handles.lightspeed)/handles.CarrierFreq/2);
                setappdata(handles.DopplerY,'DYlimit',samp_rate/2*handles.lightspeed*SweepTime/1000/(2*BandWidth));
            end

            if (handles.MD ~= MD) || (handles.ST ~= ST)...
                    || (handles.SN ~= SN) || (handles.BW ~= BW)
                handles.SettingChange = 0;
                handles.cali_sig = 0;
            end

            if handles.cali_sig == 0
                BKGD = I_rawdata; % background collection
                handles.cali_sig = 1;
            end
            
            noisecancellation = get(handles.noisecancel,'Value');            
            if noisecancellation == 1  % background subtraction
                sgn = I_rawdata - BKGD;
            else % Range Notch Filter (A bandpass filter)
                handles.cali_sig = 0; 
                notchfreq = get(handles.NotchSlider,'Value')+1;
                if notchfreq >= samp_rate/2.5
                    notchfreq = samp_rate/2.5;
                end
                F1 = 2*notchfreq/samp_rate;
                F2 = 2*samp_rate/2.1/samp_rate;
                F12 = [F1,F2];
                N = 8;
                [BF,AF] = butter(N,F12);
                I_rawdata = I_rawdata - mean(I_rawdata);
                sgn = filter(BF,AF,I_rawdata);
            end  

            FFT_size = 1024;
            sgn = sgn.*hamming(NTS); 
            
            fsignal1 = fft(sgn,FFT_size);
            fsignal = fsignal1(1:FFT_size/2+1);
            psdx = (1/FFT_size).*abs(fsignal).^2;
            psdx(2:end-1) = 2*psdx(2:end-1);
            psd = 10*log10(psdx+eps); % power spectral density                        
            Rng = linspace(0,samp_rate/2,FFT_size/2+1)*handles.lightspeed*SweepTime/1000/(2*BandWidth);

            selection1 = get(handles.FirstDisplay,'SelectedObject');
            switch get(selection1,'tag')
                case 'stream'
                    set(handles.color,'Visible','off');
                    set(handles.waterfallaxes,'Visible','off');
                    drawnow;
                    set(handles.source,'Visible','on'); 
                    set(handles.streamaxes,'Visible','on');
                    
                    axes(handles.axes1);
                    cla;
                    set(handles.scopepanel,'Title',' Stream  ');
                    set(handles.axes1,'Color','Black');
                    if (get(handles.I_state,'Value') == get(handles.I_state,'Max'))
                        set(handles.I_state,'backgroundcolor','yellow');
                        plot(I_rawdata-mean(I_rawdata),'y');
                    else
                        set(handles.I_state,'backgroundcolor',[0.94 0.94 0.94]);
                    end
                    hold on;
                    if (get(handles.Q_state,'Value') == get(handles.Q_state,'Max'))
                        set(handles.Q_state,'backgroundcolor','green');
                        plot(Q_rawdata-mean(Q_rawdata),'g');
                    else
                        set(handles.Q_state,'backgroundcolor',[0.94 0.94 0.94]);
                    end

                    StreamX = getappdata(handles.StreamX,'Xlimit');
                    StreamY = getappdata(handles.StreamY,'Ylimit');
                    axis([0 StreamX -StreamY StreamY]);
                    xlabel('Sampling Number Per Sweep');
                    ylabel('Amplitude');

                    xtick=get(gca,'XTick'); 
                    ylim=get(gca,'Ylim'); 
                    X=repmat(xtick,2,1);
                    Y=repmat(ylim',1,size(xtick,2));
                    plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');              
                    ytick=get(gca,'YTick');
                    xlim=get(gca,'Xlim');
                    Y_=repmat(ytick,2,1);
                    X_=repmat(xlim',1,size(ytick,2));
                    plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');

                case 'waterfall'
                    set(handles.source,'Visible','off');
                    set(handles.streamaxes,'Visible','off');
                    drawnow;
                    set(handles.color,'Visible','on');
                    set(handles.waterfallaxes,'Visible','on');
                    
                    axes(handles.axes1);    
                    cla;
                    set(handles.scopepanel,'Title','Waterfall');
                    if FMCWWF_flag == 0
                        FMCWWF = zeros(m,FFT_size/2+1);
                        FMCWWF_flag = 1;
                    end
                    FMCWWF(2:m,:) = FMCWWF(1:m-1,:); 
                    FMCWWF(1,:) = psd; 
                    if (get(handles.gray_state,'Value') == get(handles.gray_state,'Max'))
                        set(handles.gray_state,'backgroundcolor','green');
                        set(handles.rgb_state,'backgroundcolor',[0.94 0.94 0.94]);
                        colormap(gray);
                    end
                    if (get(handles.rgb_state,'Value') == get(handles.rgb_state,'Max'))
                        set(handles.rgb_state,'backgroundcolor','green');
                        set(handles.gray_state,'backgroundcolor',[0.94 0.94 0.94]);
                        colormap('default');
                    end
                    surf(Rng,(0:m-1),FMCWWF);
                    set(handles.axes1,'view',[0 90]);
                    WaterfallX = getappdata(handles.WaterfallX,'WXlimit');
                    WaterfallY = getappdata(handles.WaterfallY,'WYlimit');
                    axis([0 WaterfallX 0 WaterfallY]);
                    shading(handles.axes1,'interp');
                    xlabel('Range(m)');
                    ylabel('Frame');
            end

            selection2 = get(handles.SecondDisplay,'SelectedObject');
            switch get(selection2,'tag')
                case 'RangeProfile'  
                    set(handles.Doppleraxes,'Visible','off');
                    drawnow;
                    set(handles.rangeaxes,'Visible','on');

                    axes(handles.axes2); 
                    cla;
                    set(handles.fftpanel,'Title','Range Profile');                
                    set(handles.axes2,'Color','Black');
                    plot(Rng,psd,'-g');
                    RangeX = getappdata(handles.RangeX,'RXlimit');
                    RangeY = getappdata(handles.RangeY,'RYlimit');
                    axis([0 RangeX 0 RangeY]);
                    xlabel('Range(m)');
                    ylabel('Power/Frequency(dB/Hz)');

                    [~,index] = max(psd);
                    RangeInfo = Rng(index);
                    set(handles.PeakValue,'String',num2str(RangeInfo),'Foregroundcolor','blue');
                    set(handles.VeValue,'String','N/A','Foregroundcolor','blue');

                    hold on;
                    xtick=get(gca,'XTick');
                    ylim=get(gca,'Ylim');
                    X=repmat(xtick,2,1);
                    Y=repmat(ylim',1,size(xtick,2));
                    plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');
                    ytick=get(gca,'YTick');
                    xlim=get(gca,'Xlim');
                    Y_=repmat(ytick,2,1);
                    X_=repmat(xlim',1,size(ytick,2));
                    plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');

%%%%%%%%%%%%%%%%range doppler bit for fmcw sawtooth%%%%%%%%%%%%%%%%%%
                case 'RangeDoppler'
                    set(handles.rangeaxes,'Visible','off');
                    drawnow;
                    set(handles.Doppleraxes,'Visible','on');
                    set(handles.fftpanel,'Title','Range Doppler');
                                     
                    Rawdata = datatrump(index(1):index(1)+PN*NTS*4-1);
                    switch get(handles.CHSelection,'Value')
                        case 1
                            A = Rawdata(2:4:end); % I data 1
                        case 2
                            A = Rawdata(4:4:end); % I data 2
                        otherwise
                            A = Rawdata(2:4:end); % I data 1
                    end
                    B = reshape(A,NTS,PN);                   
                    DOPPLER_FFT_SIZE = 128;
                    RANGE_FFT_SIZE = 512;
                    DOPP_FREQ = 1/SweepTime*1000;

                    if noisecancellation == 1
                        B = bsxfun(@minus, B, BKGD);
                    else
                        B = bsxfun(@minus, B, mean(B));
                        B = filter(BF,AF,B,[],1);
                    end

                    C = fft(B,RANGE_FFT_SIZE,1);
                    D = C(1:RANGE_FFT_SIZE/2,:);
                    D = bsxfun(@minus, D, mean(D,2));
                    
                    notch_vr = get(handles.NotchVrSlider,'Value')+0.01;
                    notch_doppler = 2*notch_vr/(handles.lightspeed/handles.CarrierFreq);                      
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

                    VrNotch = get(handles.VrNotchFilter,'Value')                  
                    if VrNotch == 1
                        D = filter(num,den,D,[],2); % Doppler Notch filter
                    end

                    E = abs(fftshift(fft(D,DOPPLER_FFT_SIZE,2),2)).^2/DOPPLER_FFT_SIZE;                   
                    
                    [RngIdx,DopplerIdx] = find(E==max(max(E)));
                    surfX = linspace(-DOPP_FREQ/2,DOPP_FREQ/2,DOPPLER_FFT_SIZE)*(handles.lightspeed)/handles.CarrierFreq/2;
                    surfY = linspace(0,samp_rate/2,RANGE_FFT_SIZE/2)*handles.lightspeed*SweepTime/1000/(2*BandWidth);
                    RangeInfo = surfY(RngIdx(1));
                    VeloInfo = surfX(DopplerIdx(1));                              
                    set(handles.PeakValue,'String',num2str(RangeInfo),'Foregroundcolor','blue');
                    set(handles.VeValue,'String',num2str(VeloInfo),'Foregroundcolor','blue');

                    axes(handles.axes2);    
                    cla(handles.axes2,'reset');
                    surface(surfX, surfY, E, 'EdgeColor', 'none');
                    DopplerX = getappdata(handles.DopplerX,'DXlimit');
                    DopplerY = getappdata(handles.DopplerY,'DYlimit');
                    axis([-DopplerX DopplerX 0 DopplerY]);
                    xlabel('Velocity(m/s)');
                    ylabel('Range(m)');
            end
            
        elseif (MD == 1) % Triangle
            
            handles.CarrierFreq = handles.radarmodel;
            set(handles.RangeProfile,'String','Range History');
            set(handles.RangeDoppler,'String','Velocity History');
            set(handles.freqshow,'String',[num2str(handles.CarrierFreq/1e9-BandWidth/2e9)...
                '-' num2str(handles.CarrierFreq/1e9+BandWidth/2e9)]);
            samp_rate = 1/SweepTime * NTS * 1000;

%=======================  added below 02/23/2017 ==========================
            instruction = MD+SN*4+BW*16+ST*64+40960; 
            forwarddata = zeros(512,1)+instruction;
            outdata = uint16(forwarddata); 
            outlength = miniradarputdata(outdata, handles.endpoint2_no);
            if outlength == 0
                set(handles.message,'String','data transfer error','ForegroundColor','red');
                return
            end              
            set(handles.message,'String','Connected','ForegroundColor','Green');
%====================== added above 02/23/2017 ============================
            
            data_length = 4*(ceil(PN*NTS/512)*512+1024)+2048;
            %1024->2048 02/23/2017
            [data,inlength] = miniradargetdata(handles.endpoint6_no,data_length);
            if inlength == 0
                set(handles.message,'String','No data 1','ForegroundColor','red');
                return
            end
            
            datatrump = double(data(2049:end)); %1025->2049 02/23/2017
            index = find(datatrump>=32768);
            datatrump(index) = datatrump(index)-32768;
            
            N_avg = 5;
            datastream = datatrump(index(1):index(1)+N_avg*NTS*4-1);
            switch get(handles.CHSelection,'Value')
                case 1
                    IData = datastream(2:4:end); % I data of channel 1
                    QData = datastream(1:4:end); % Q data of channel 1
                case 2
                    IData = datastream(4:4:end); % I data of channel 2
                    QData = datastream(3:4:end); % Q data of channel 2
                otherwise
                    IData = datastream(2:4:end); % I data of channel 1
                    QData = datastream(1:4:end); % Q data of channel 1
            end
            IMatrix = reshape(IData,NTS,N_avg);
            QMatrix = reshape(QData,NTS,N_avg);
            I_rawdata = mean(IMatrix,2);
            Q_rawdata = mean(QMatrix,2);
            
            if handles.SettingChange == 0
                handles.MD = MD;
                handles.ST = ST;
                handles.SN = SN;
                handles.BW = BW;
                handles.SettingChange = 1;
                setappdata(handles.StreamX,'Xlimit',NTS);
                setappdata(handles.StreamY,'Ylimit',800);
                setappdata(handles.RangeX,'RXlimit',m-1);
                setappdata(handles.RangeY,'RYlimit',20);
                setappdata(handles.DopplerX,'DXlimit',m-1);
                setappdata(handles.DopplerY,'DYlimit',10);
            end

            if (handles.MD ~= MD) || (handles.ST ~= ST)...
                    || (handles.SN ~= SN) || (handles.BW ~= BW)
                handles.SettingChange = 0;
                handles.cali_sig = 0;
            end

            if handles.cali_sig == 0
                BKGD = I_rawdata;
                handles.cali_sig = 1;
            end
            
            noisecancellation = get(handles.noisecancel,'Value');            
            if noisecancellation == 1
                sgn = I_rawdata - BKGD;
            else
                handles.cali_sig = 0; 
                notchfreq = get(handles.NotchSlider,'Value')+1;
                if notchfreq >= samp_rate/2.5
                    notchfreq = samp_rate/2.5;
                end
                F1 = 2*notchfreq/samp_rate;
                F2 = 2*samp_rate/2.1/samp_rate;
                F12 = [F1,F2];
                N = 8;
                [BF,AF] = butter(N,F12);
                I_rawdata = I_rawdata - mean(I_rawdata);
                sgn = filter(BF,AF,I_rawdata);
            end  

            FFT_size = 10240;
            sgn_up = sgn(1:NTS/2).*hamming(NTS/2);
            sgn_down = sgn(NTS/2+1:end).*hamming(NTS/2);

            fsignal_up = fft(sgn_up,FFT_size);
            fsignal = fsignal_up(1:FFT_size/2+1);
            psdx_up = (1/FFT_size).*abs(fsignal).^2;
            psdx_up(2:end-1) = 2*psdx_up(2:end-1);
            psd_up = 10*log10(psdx_up+eps); % psd                        
            Freq = linspace(0,samp_rate/2,FFT_size/2+1);
            [~,index] = max(psd_up);
            f1 = Freq(index);
            
            fsignal_down = fft(sgn_down,FFT_size);
            fsignal = fsignal_down(1:FFT_size/2+1);
            psdx_down = (1/FFT_size) .* abs(fsignal).^2;
            psdx_down(2:end-1) = 2*psdx_down(2:end-1);
            psd_down = 10*log10(psdx_down+eps); % psd                       
            Freq = linspace(0,samp_rate/2,FFT_size/2+1);
            [~,index] = max(psd_down);
            f2 = Freq(index);
            
            Range_info = handles.lightspeed*SweepTime/1000/(4*BandWidth)*(f1+f2)/2;
            Velo_info = handles.lightspeed/handles.CarrierFreq/4*(f1-f2);
            set(handles.PeakValue,'String',num2str(Range_info),'Foregroundcolor','blue'); 
            set(handles.VeValue,'String',num2str(Velo_info),'Foregroundcolor','blue');
                    
            selection1 = get(handles.FirstDisplay,'SelectedObject');
            switch get(selection1,'tag')
                case 'stream'
                    set(handles.color,'Visible','off');
                    set(handles.waterfallaxes,'Visible','off');
                    drawnow;
                    set(handles.source,'Visible','on'); 
                    set(handles.streamaxes,'Visible','on');
                    
                    axes(handles.axes1);
                    cla;
                    set(handles.scopepanel,'Title',' Stream  ');
                    set(handles.axes1,'Color','Black');
                    if (get(handles.I_state,'Value') == get(handles.I_state,'Max'))
                        set(handles.I_state,'backgroundcolor','yellow');
                        plot(I_rawdata-mean(I_rawdata),'yellow');
                    else
                        set(handles.I_state,'backgroundcolor',[0.94 0.94 0.94]);
                    end
                    hold on;
                    if (get(handles.Q_state,'Value') == get(handles.Q_state,'Max'))
                        set(handles.Q_state,'backgroundcolor','green');
                        plot(Q_rawdata-mean(Q_rawdata),'g');
                    else
                        set(handles.Q_state,'backgroundcolor',[0.94 0.94 0.94]);
                    end

                    StreamX = getappdata(handles.StreamX,'Xlimit');
                    StreamY = getappdata(handles.StreamY,'Ylimit');
                    axis([0 StreamX -StreamY StreamY]);
                    xlabel('Sampling Number Per Sweep');
                    ylabel('Amplitude');

                    xtick=get(gca,'XTick'); 
                    ylim=get(gca,'Ylim'); 
                    X=repmat(xtick,2,1);
                    Y=repmat(ylim',1,size(xtick,2));
                    plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');              
                    ytick=get(gca,'YTick');
                    xlim=get(gca,'Xlim');
                    Y_=repmat(ytick,2,1);
                    X_=repmat(xlim',1,size(ytick,2));
                    plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');

                case 'waterfall'
                    set(handles.source,'Visible','off');
                    set(handles.streamaxes,'Visible','off');
                    drawnow;
                    set(handles.color,'Visible','on');
                    set(handles.waterfallaxes,'Visible','on');
                    
                    axes(handles.axes1);    
                    cla;
                    set(handles.axes1,'Color','Black');
                    set(handles.scopepanel,'Title','Waterfall');
                    hold on;
                    x = [1 2 3 4];
                    y = [4 3 2 1];
                    plot(1:4,x,'y',1:4,y,'y');
                    axis([1 4 1 4])
                    xlabel('N/A');
                    ylabel('N/A');
            end

            selection2 = get(handles.SecondDisplay,'SelectedObject');
            switch get(selection2,'tag')
                case 'RangeProfile'  
                    set(handles.Doppleraxes,'Visible','off');
                    drawnow;
                    set(handles.rangeaxes,'Visible','on');

                    axes(handles.axes2); 
                    cla;
                    set(handles.fftpanel,'Title','Range History');                
                    set(handles.axes2,'Color','Black');
                    hold on;
                    if TriRng_flag == 0
                        RngHx = zeros(1,m);
                        TriRng_flag = 1;
                    end
                    RngHx(2:m) = RngHx(1:m-1); 
                    RngHx(1) = Range_info;
                    plot((0:m-1),RngHx,'r');
                    RangeX = getappdata(handles.RangeX,'RXlimit');
                    RangeY = getappdata(handles.RangeY,'RYlimit');
                    axis([0 RangeX 0 RangeY]);
                    xlabel('Frame');
                    ylabel('Range(m)');
                    
                    xtick=get(gca,'XTick'); 
                    ylim=get(gca,'Ylim'); 
                    X=repmat(xtick,2,1);
                    Y=repmat(ylim',1,size(xtick,2));
                    plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');              
                    ytick=get(gca,'YTick');
                    xlim=get(gca,'Xlim');
                    Y_=repmat(ytick,2,1);
                    X_=repmat(xlim',1,size(ytick,2));
                    plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');

                case 'RangeDoppler'
                    set(handles.rangeaxes,'Visible','off');
                    drawnow;
                    set(handles.Doppleraxes,'Visible','on');
                    
                    axes(handles.axes2);    
                    cla;
                    set(handles.fftpanel,'Title','Velocity History');
                    set(handles.axes2,'Color','Black');
                    hold on;
                    if TriV_flag == 0
                        TriV = zeros(1,m);
                        TriV_flag = 1;
                    end
                    TriV(2:m) = TriV(1:m-1); 
                    TriV(1) = Velo_info;
                    plot((0:m-1),TriV,'r');
                    DopplerX = getappdata(handles.DopplerX,'DXlimit');
                    DopplerY = getappdata(handles.DopplerY,'DYlimit');
                    axis([0 DopplerX -DopplerY DopplerY]);
                    xlabel('Frame');
                    ylabel('Velocity(m/s)');
                    
                    xtick=get(gca,'XTick'); 
                    ylim=get(gca,'Ylim'); 
                    X=repmat(xtick,2,1);
                    Y=repmat(ylim',1,size(xtick,2));
                    plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');              
                    ytick=get(gca,'YTick');
                    xlim=get(gca,'Xlim');
                    Y_=repmat(ytick,2,1);
                    X_=repmat(xlim',1,size(ytick,2));
                    plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');
            end

        elseif (MD == 2) %% FSK

            handles.CarrierFreq = handles.radarmodel;            
            set(handles.RangeProfile,'String','Velocity History');
            set(handles.RangeDoppler,'String','Range History');
            FSK_BW = 6e6; % Frequency step 6MHz
            DOPP_FREQ = 1/SweepTime*1000;
            set(handles.freqshow,'String',[num2str(handles.CarrierFreq/1e9) '  ,  ' num2str(handles.CarrierFreq/1e9-FSK_BW/1e9)]);

%=======================  added below 02/23/2017 ==========================
            instruction = MD+SN*4+BW*16+ST*64+40960; 
            forwarddata = zeros(512,1)+instruction;
            outdata = uint16(forwarddata); 
            outlength = miniradarputdata(outdata, handles.endpoint2_no);
            if outlength == 0
                set(handles.message,'String','data transfer error','ForegroundColor','red');
                return
            end              
            set(handles.message,'String','Connected','ForegroundColor','Green');
%====================== added above 02/23/2017 ============================

            data_length = 4*(ceil(PN*NTS/512)*512+1024)+2048;
            %1024->2048 02/23/2017
            [data,inlength] = miniradargetdata(handles.endpoint6_no,data_length);
            if inlength == 0
                set(handles.message,'String','No data 1','ForegroundColor','red');
                return
            end

            datatrump = double(data(2049:end)); %1025->2049 02/23/2017
            index = find(datatrump>=32768);
            datatrump(index) = datatrump(index) - 32768;

            signal = datatrump(index(1):index(1)+4*NTS-1);
            rawdata = datatrump(index(1):index(1)+PN*NTS*4-1);
            switch get(handles.CHSelection,'Value')
                case 1
                    I_data = signal(2:4:end)-mean(signal(2:4:end)); % channel 1 I data
                    Q_data = signal(1:4:end)-mean(signal(1:4:end)); % channel 1 Q data
                    A = rawdata(2:4:end) + 1i*rawdata(1:4:end);
                case 2
                    I_data = signal(4:4:end)-mean(signal(4:4:end)); % channel 2 I data
                    Q_data = signal(3:4:end)-mean(signal(3:4:end)); % channel 2 Q data
                    A = rawdata(4:4:end) + 1i*rawdata(3:4:end);
                otherwise
                    I_data = signal(2:4:end)-mean(signal(2:4:end));
                    Q_data = signal(1:4:end)-mean(signal(1:4:end));
                    A = rawdata(2:4:end) + 1i*rawdata(1:4:end);
            end
            
            B = reshape(A,NTS,PN);
            signal_1 = B(NTS/4,:) - mean(B(NTS/4,:));
            signal_2 = B(3*NTS/4,:) - mean(B(3*NTS/4,:));
                    
            signal_1 = signal_1.*hamming(length(signal_1))';
            signal_2 = signal_2.*hamming(length(signal_2))'; 
            
            fft_1 = fft(signal_1);
            fft_2 = fft(signal_2);
            fft_3 = fft_1 .* fft_2;
            
            [~, fft3MaxIndex] = max(abs(fft_3));
            phase1 = angle(fft_1(fft3MaxIndex));
            phase2 = angle(fft_2(fft3MaxIndex));
            phase_diff = mod(phase1 - phase2, 2*pi);               
            Range_fsk = handles.lightspeed*phase_diff/(4*pi*FSK_BW);
              
            FskFreq = fftshift(linspace(-DOPP_FREQ/2,DOPP_FREQ/2,PN));
            FskVfreq = FskFreq(fft3MaxIndex);
            V_fsk = FskVfreq*handles.lightspeed/(2*handles.CarrierFreq);
            
            set(handles.PeakValue,'String',num2str(Range_fsk),'Foregroundcolor','blue');
            set(handles.VeValue,'String',num2str(V_fsk),'Foregroundcolor','blue');
                        
            if handles.SettingChange == 0
                handles.MD = MD;
                handles.ST = ST;
                handles.SN = SN;
                handles.BW = BW;
                handles.SettingChange = 1;
                setappdata(handles.StreamX,'Xlimit',NTS);
                setappdata(handles.StreamY,'Ylimit',800);
                setappdata(handles.RangeX,'RXlimit',m-1);
                setappdata(handles.RangeY,'RYlimit',DOPP_FREQ/2*handles.lightspeed/(2*handles.CarrierFreq));
                setappdata(handles.DopplerX,'DXlimit',m-1);
                setappdata(handles.DopplerY,'DYlimit',25);
            end

            if (handles.MD ~= MD) || (handles.ST ~= ST)...
                    || (handles.SN ~= SN) || (handles.BW ~= BW)
                handles.SettingChange = 0;
            end
            
            selection1 = get(handles.FirstDisplay,'SelectedObject');
            switch get(selection1,'tag')
                case 'stream'
                    set(handles.color,'Visible','off');
                    set(handles.waterfallaxes,'Visible','off');
                    drawnow;
                    set(handles.source,'Visible','on'); 
                    set(handles.streamaxes,'Visible','on');
                    
                    axes(handles.axes1);
                    cla;
                    set(handles.scopepanel,'Title',' Stream  ');
                    set(handles.axes1,'Color','Black');
                    if (get(handles.I_state,'Value') == get(handles.I_state,'Max'))
                        set(handles.I_state,'backgroundcolor','yellow');
                        plot(I_data,'yellow');
                    else
                        set(handles.I_state,'backgroundcolor',[0.94 0.94 0.94]);
                    end
                    hold on;
                    if (get(handles.Q_state,'Value') == get(handles.Q_state,'Max'))
                        set(handles.Q_state,'backgroundcolor','green');
                        plot(Q_data,'g');
                    else
                        set(handles.Q_state,'backgroundcolor',[0.94 0.94 0.94]);
                    end

                    StreamX = getappdata(handles.StreamX,'Xlimit');
                    StreamY = getappdata(handles.StreamY,'Ylimit');
                    axis([0 StreamX -StreamY StreamY]);
                    xlabel('Sampling Number Per Sweep');
                    ylabel('Amplitude');

                    xtick=get(gca,'XTick'); 
                    ylim=get(gca,'Ylim'); 
                    X=repmat(xtick,2,1);
                    Y=repmat(ylim',1,size(xtick,2));
                    plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');              
                    ytick=get(gca,'YTick');
                    xlim=get(gca,'Xlim');
                    Y_=repmat(ytick,2,1);
                    X_=repmat(xlim',1,size(ytick,2));
                    plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');

                case 'waterfall'
                    set(handles.source,'Visible','off');
                    set(handles.streamaxes,'Visible','off');
                    drawnow;
                    set(handles.color,'Visible','on');
                    set(handles.waterfallaxes,'Visible','on');
                    
                    x = [1 2 3 4];
                    y = [4 3 2 1];
                    axes(handles.axes1);    
                    cla;
                    set(handles.scopepanel,'Title','Waterfall');
                    set(handles.axes1,'Color','Black');
                    hold on;
                    plot(1:4,x,'y',1:4,y,'y');
                    axis([1 4 1 4])
                    xlabel('N/A');
                    ylabel('N/A');
            end

            selection2 = get(handles.SecondDisplay,'SelectedObject');
            switch get(selection2,'tag')
                case 'RangeProfile'  
                    set(handles.Doppleraxes,'Visible','off');
                    drawnow;
                    set(handles.rangeaxes,'Visible','on');

                    axes(handles.axes2); 
                    cla;
                    set(handles.fftpanel,'Title','Velocity History');                
                    set(handles.axes2,'Color','Black');  
                    
                    if FskV_flag == 0
                        FskVHist = zeros(1,m);
                        FskV_flag = 1;
                    end
                    FskVHist(2:m) = FskVHist(1:m-1); 
                    FskVHist(1) = V_fsk;
                    plot((0:m-1),FskVHist,'r');
                    
                    RangeX = getappdata(handles.RangeX,'RXlimit');
                    RangeY = getappdata(handles.RangeY,'RYlimit');
                    axis([0 RangeX -RangeY RangeY]);
                    xlabel('Frame');
                    ylabel('Velocity(m/s)');
                        
                    hold on;
                    xtick=get(gca,'XTick');
                    ylim=get(gca,'Ylim');
                    X=repmat(xtick,2,1);
                    Y=repmat(ylim',1,size(xtick,2));
                    plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');
                    ytick=get(gca,'YTick');
                    xlim=get(gca,'Xlim');
                    Y_=repmat(ytick,2,1);
                    X_=repmat(xlim',1,size(ytick,2));
                    plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');

                case 'RangeDoppler'
                    set(handles.rangeaxes,'Visible','off');
                    drawnow;
                    set(handles.Doppleraxes,'Visible','on');
                    
                    axes(handles.axes2);
                    cla;
                    set(handles.fftpanel,'Title','Range History');
                    set(handles.axes2,'Color','Black');
                    hold on;
                    if FskRng_flag == 0
                        RngHist = zeros(1,m);
                        FskRng_flag = 1;
                    end
                    RngHist(2:m) = RngHist(1:m-1); 
                    RngHist(1) = Range_fsk;
                    plot((0:m-1),RngHist,'r');
                    DopplerX = getappdata(handles.DopplerX,'DXlimit');
                    DopplerY = getappdata(handles.DopplerY,'DYlimit');
                    axis([0 DopplerX 0 DopplerY]);
                    xlabel('Frame');
                    ylabel('Range(m)');

                    xtick=get(gca,'XTick');
                    ylim=get(gca,'Ylim');
                    X=repmat(xtick,2,1);
                    Y=repmat(ylim',1,size(xtick,2));
                    plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');
                    ytick=get(gca,'YTick');
                    xlim=get(gca,'Xlim');
                    Y_=repmat(ytick,2,1);
                    X_=repmat(xlim',1,size(ytick,2));
                    plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');
            end

        else %% CW

            handles.CarrierFreq = handles.radarmodel;
            set(handles.RangeProfile,'String','Velocity Profile');
            set(handles.RangeDoppler,'String','Velocity History');
            set(handles.freqshow,'String',num2str(handles.CarrierFreq/1e9));
            samp_rate = 1/SweepTime*NTS*1000;

%=======================  added below 02/23/2017 ==========================
            instruction = MD+SN*4+BW*16+ST*64+40960; 
            forwarddata = zeros(512,1)+instruction;
            outdata = uint16(forwarddata); 
            outlength = miniradarputdata(outdata, handles.endpoint2_no);
            if outlength == 0
                set(handles.message,'String','data transfer error','ForegroundColor','red');
                return
            end              
            set(handles.message,'String','Connected','ForegroundColor','Green');
%====================== added above 02/23/2017 ============================

            data_length = 4*(floor(128/SweepTime*NTS/512)*512)+2048; ...
            % about 128 ms data
            %1024-2048 02/23/2017
            [data,inlength] = miniradargetdata(handles.endpoint6_no,data_length);
            if inlength == 0
                set(handles.message,'String','No data 1','ForegroundColor','red');
                return
            end                

            signaldouble = double(data(2049:data_length)); % 1025->2049 02/23/2017
            index = find(signaldouble>=32768);
            signaldouble(index) = signaldouble(index)-32768;
            signal = signaldouble(index(1):end);
            datalength = floor(length(signal)/4)*4;
            
            switch get(handles.CHSelection,'Value')
                case 1
                    I_rawdata = signal(2:4:datalength)-mean(signal(2:4:datalength)); % channel 1 I
                    Q_rawdata = signal(1:4:datalength)-mean(signal(1:4:datalength)); % channel 1 Q
                case 2
                    I_rawdata = signal(4:4:datalength)-mean(signal(4:4:datalength)); % channel 2 I
                    Q_rawdata = signal(3:4:datalength)-mean(signal(3:4:datalength)); % channel 2 Q
                otherwise
                    I_rawdata = signal(2:4:datalength)-mean(signal(2:4:datalength));
                    Q_rawdata = signal(1:4:datalength)-mean(signal(1:4:datalength));
            end
            miux = mean(I_rawdata);
            miuy = mean(Q_rawdata);
            I2_bar = mean((I_rawdata-miux).^2);
            Q2_bar = mean((Q_rawdata-miuy).^2);
            IQ_bar = mean((I_rawdata-miux).*(Q_rawdata-miuy));
            D_bar = IQ_bar/I2_bar;
            C_bar = sqrt(Q2_bar/I2_bar-D_bar^2);
            d_ampImb = sqrt(C_bar^2+D_bar^2)-1;
            phi = atan(D_bar/C_bar);
            I_rawdata = I_rawdata-miux;
            Q_rawdata = ((Q_rawdata-miuy)/(1+d_ampImb)-I_rawdata*sin(phi))/cos(phi);
            signalcomplex = I_rawdata+1i*Q_rawdata; % IQ imbalance correction
               
            dec = 64;
            samprate = samp_rate/dec;
            DeciData = decimate(signalcomplex, dec);                                  
            DeciData = DeciData.*hamming(length(DeciData))';
            fft_size = 1024;
            fsignal = 10*log10((abs(fftshift(fft(DeciData,fft_size))).^2/fft_size)+eps);

            if handles.SettingChange == 0
                handles.MD = MD;
                handles.ST = ST;
                handles.SN = SN;
                handles.BW = BW;
                handles.SettingChange = 1;
                setappdata(handles.StreamX,'Xlimit',length(DeciData)/samprate);
                setappdata(handles.StreamY,'Ylimit',200);
                setappdata(handles.WaterfallX,'WXlimit',samprate/2*handles.lightspeed/(2*handles.CarrierFreq));
                setappdata(handles.WaterfallY,'WYlimit',m-1);
                setappdata(handles.RangeX,'RXlimit',samprate/2*handles.lightspeed/(2*handles.CarrierFreq));
                setappdata(handles.RangeY,'RYlimit',60);
                setappdata(handles.DopplerX,'DXlimit',m-1);
                setappdata(handles.DopplerY,'DYlimit',samprate/2*handles.lightspeed/(2*handles.CarrierFreq));
            end

            if (handles.MD ~= MD) || (handles.ST ~= ST)...
                    || (handles.SN ~= SN) || (handles.BW ~= BW)
                handles.SettingChange=0;
            end

            Xtime = (1:length(DeciData))/samprate;
            Xspeed = linspace(-samprate/2,samprate/2,fft_size)*handles.lightspeed/(2*handles.CarrierFreq);
            [max_value,index] = max(fsignal);

            set(handles.PeakValue,'String','N/A','Foregroundcolor','blue');
            set(handles.VeValue,'String',num2str(Xspeed(index)),'Foregroundcolor','blue');

            selection1 = get(handles.FirstDisplay,'SelectedObject');
                switch get(selection1,'tag')
                    case 'stream'
                        set(handles.color,'Visible','off');
                        set(handles.waterfallaxes,'Visible','off');
                        drawnow;
                        set(handles.source,'Visible','on'); 
                        set(handles.streamaxes,'Visible','on');
                        
                        axes(handles.axes1);
                        cla;
                        set(handles.scopepanel,'Title',' Stream  ');
                        set(handles.axes1,'Color','Black');
                        if (get(handles.I_state,'Value') == get(handles.I_state,'Max'))
                            set(handles.I_state,'backgroundcolor','yellow');
                            plot(Xtime,real(DeciData),'yellow');
                        else
                            set(handles.I_state,'backgroundcolor',[0.94 0.94 0.94]);
                        end
                        hold on;
                        if (get(handles.Q_state,'Value') == get(handles.Q_state,'Max'))
                            set(handles.Q_state,'backgroundcolor','green');
                            plot(Xtime,imag(DeciData),'g');
                        else
                            set(handles.Q_state,'backgroundcolor',[0.94 0.94 0.94]);
                        end

                        StreamX = getappdata(handles.StreamX,'Xlimit');
                        StreamY = getappdata(handles.StreamY,'Ylimit');
                        axis([0 StreamX -StreamY StreamY]);
                        xlabel('Time(s)');
                        ylabel('Amplitude');

                        xtick=get(gca,'XTick'); 
                        ylim=get(gca,'Ylim'); 
                        X=repmat(xtick,2,1);
                        Y=repmat(ylim',1,size(xtick,2));
                        plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');              
                        ytick=get(gca,'YTick');
                        xlim=get(gca,'Xlim');
                        Y_=repmat(ytick,2,1);
                        X_=repmat(xlim',1,size(ytick,2));
                        plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');

                    case 'waterfall'
                        set(handles.source,'Visible','off');
                        set(handles.streamaxes,'Visible','off');
                        drawnow;
                        set(handles.color,'Visible','on');
                        set(handles.waterfallaxes,'Visible','on');
                        
                        axes(handles.axes1);    
                        cla;
                        set(handles.scopepanel,'Title','Waterfall');
                        if CWWF_flag == 0
                            waterfallcw_data = zeros(m,1024);
                            CWWF_flag = 1;
                        end
                        waterfallcw_data(2:m,:) = waterfallcw_data(1:m-1,:); 
                        waterfallcw_data(1,:) = fsignal; 
                        surf(Xspeed,(0:m-1),waterfallcw_data); 
                        xlabel('Velocity(m/s)');
                        ylabel('Frame');
                        if (get(handles.gray_state,'Value') == get(handles.gray_state,'Max'))
                            set(handles.gray_state,'backgroundcolor','green');
                            set(handles.rgb_state,'backgroundcolor',[0.94 0.94 0.94]);
                            colormap(gray);
                        end
                        if (get(handles.rgb_state,'Value') == get(handles.rgb_state,'Max'))
                            set(handles.rgb_state,'backgroundcolor','green');
                            set(handles.gray_state,'backgroundcolor',[0.94 0.94 0.94]);
                            colormap('default');
                        end
                        set(handles.axes1,'view',[0 90]);
                        WaterfallX = getappdata(handles.WaterfallX,'WXlimit');
                        WaterfallY = getappdata(handles.WaterfallY,'WYlimit');
                        axis([-WaterfallX WaterfallX 0 WaterfallY]);
                        shading(handles.axes1,'interp');
                end

                selection2 = get(handles.SecondDisplay,'SelectedObject');
                switch get(selection2,'tag')
                    case 'RangeProfile'
                        set(handles.Doppleraxes,'Visible','off');
                        drawnow;
                        set(handles.rangeaxes,'Visible','on');
                        
                        axes(handles.axes2); 
                        cla;
                        set(handles.fftpanel,'Title','Velocity Profile');                
                        set(handles.axes2,'Color','Black');
                        plot(Xspeed,fsignal,'-y');
                        axis xy;
                        xlabel('Velocity(m/s)');
                        ylabel('Power/Frequency(dB/Hz)');
                        RangeX = getappdata(handles.RangeX,'RXlimit');
                        RangeY = getappdata(handles.RangeY,'RYlimit');
                        axis([-RangeX RangeX -50 RangeY]);
                        hold on;
                        plot(Xspeed(index),max_value,'ro');

                        xtick=get(gca,'XTick');
                        ylim=get(gca,'Ylim');
                        X=repmat(xtick,2,1);
                        Y=repmat(ylim',1,size(xtick,2));
                        plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');
                        ytick=get(gca,'YTick');
                        xlim=get(gca,'Xlim');
                        Y_=repmat(ytick,2,1);
                        X_=repmat(xlim',1,size(ytick,2));
                        plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':'); 

                    case 'RangeDoppler'
                        set(handles.rangeaxes,'Visible','off');
                        drawnow;
                        set(handles.Doppleraxes,'Visible','on');

                        axes(handles.axes2);
                        cla;
                        set(handles.axes2,'Color','Black');
                        set(handles.fftpanel,'Title','Velocity History'); 
                        hold on;
                        if CWHx_flag == 0
                            v_hist = zeros(1,m);
                            CWHx_flag = 1;
                        end
                        v_hist(2:m) = v_hist(1:m-1); 
                        v_hist(1) = Xspeed(index);
                        plot((0:m-1),v_hist,'r');
                        DopplerX = getappdata(handles.DopplerX,'DXlimit');
                        DopplerY = getappdata(handles.DopplerY,'DYlimit');
                        axis([0 DopplerX -DopplerY DopplerY]);
                        xlabel('Frame');
                        ylabel('Velocity(m/s)');
                        
                        xtick=get(gca,'XTick');
                        ylim=get(gca,'Ylim');
                        X=repmat(xtick,2,1);
                        Y=repmat(ylim',1,size(xtick,2));
                        plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');
                        ytick=get(gca,'YTick');
                        xlim=get(gca,'Xlim');
                        Y_=repmat(ytick,2,1);
                        X_=repmat(xlim',1,size(ytick,2));
                        plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':');
                end
        end
    end
    
% catch
%    SDR_CloseRequestFcn(hObject, eventdata, handles);
% end
      

% --- Executes on button press in record.
function record_Callback(hObject, eventdata, handles)
% hObject    handle to record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.message,'String','Data Recording...','ForegroundColor','green');
set(handles.start,'Enable','Off');
set(handles.record,'Enable','Off');
set(handles.save,'Enable','Off');
set(handles.record_time,'Enable','off');
set(handles.replay,'Enable','off');
drawnow;

handles.date=datestr(now);
handles.radarmodel = 5.8e9;

select = get(handles.waveform,'SelectedObject');
switch get(select,'tag')
    case 'fmcw_sawtooth'
        MD = 0; handles.wave = 'FMCW_SAWTOOTH';
    case 'fmcw_triangle'
        MD = 1; handles.wave = 'FMCW_TRIANGLE';
    case 'fsk'
        MD = 2; handles.wave = 'FSK';
    case 'cw'
        MD = 3; handles.wave = 'CW';
    otherwise
        MD = 0; handles.wave = 'FMCW_SAWTOOTH';
end

contents1 = get(handles.DurationSelection,'Value');
switch contents1
    case 1
        ST = 0; SweepTime = 1; handles.SweepTime = 1;
    case 2
        ST = 1; SweepTime = 2; handles.SweepTime = 2;
    case 3
        ST = 2; SweepTime = 4; handles.SweepTime = 4;
    case 4
        ST = 3; SweepTime = 10; handles.SweepTime = 10;
    otherwise
        ST = 0; SweepTime = 1; handles.SweepTime = 1;
end

contents2 = get(handles.SNSelection,'Value');
switch contents2
    case 1
        SN = 0; NTS = 128; handles.SweepNumber = 128;
    case 2
        SN = 1; NTS = 256; handles.SweepNumber = 256;
    case 3
        SN = 2; NTS = 512; handles.SweepNumber = 512;
    case 4
        SN = 3; NTS = 1024; handles.SweepNumber = 1024;        
    otherwise
        SN = 0; NTS = 128; handles.SweepNumber = 128;
end

contents3 = get(handles.BWSelection,'Value');
switch contents3
    case 1
        BW = 0; 
        BandWidth = 400e6; handles.BandWidth = 400e6;
    case 2
        BW = 1; 
        BandWidth = 100e6; handles.BandWidth = 100e6;
    case 3
        BW = 2;
        BandWidth = 150e6; handles.BandWidth = 150e6;
    case 4
        BW = 3;
        BandWidth = 300e6; handles.BandWidth = 300e6;    
    otherwise
        BW = 0;
        BandWidth = 400e6; handles.BandWidth = 400e6;
end
        
instruction = MD+SN*4+BW*16+ST*64+40960; 
forwarddata = zeros(256,1)+instruction;%HA100-A102
outdata = uint16(forwarddata); 
outlength = miniradarputdata(outdata, handles.endpoint2_no);  

if outlength == 0
set(handles.message,'String','data transfer error','ForegroundColor','red');
draw now;
return
end              

contents = get(handles.record_time,'Value');
switch contents
    case 1
        datalength = 4*(ceil(10000/SweepTime*NTS/512)*512)+2048;
        %1024->2048 02/23/2017
    case 2
        datalength = 4*(ceil(20000/SweepTime*NTS/512)*512)+2048;
        %1024->2048 02/23/2017
    case 3
        datalength = 4*(ceil(30000/SweepTime*NTS/512)*512)+2048;
        %1024->2048 02/23/2017
    case 4
        datalength = 4*(ceil(60000/SweepTime*NTS/512)*512)+2048;
        %1024->2048 02/23/2017
    otherwise
end

%=======================  added below 02/23/2017 ==========================
            instruction = MD+SN*4+BW*16+ST*64+40960; 
            forwarddata = zeros(512,1)+instruction;
            outdata = uint16(forwarddata); 
            outlength = miniradarputdata(outdata, handles.endpoint2_no);
            if outlength == 0
                set(handles.message,'String','data transfer error','ForegroundColor','red');
                return
            end              
            set(handles.message,'String','Connected','ForegroundColor','Green');
%====================== added above 02/23/2017 ============================

[data,inlength] = miniradargetdata(handles.endpoint6_no,datalength);

if inlength == 0
   set(handles.message,'String','No data 2','ForegroundColor','red');
   return
end

rawdata = double(data(2049:end)); %1025 -> 2049 02/23/2017
index = find(rawdata>=32768);
rawdata(index) = rawdata(index)-32768;

if (MD == 0) || (MD == 1) || (MD == 2)% FMCW/FSK
    
    doubledata = rawdata(index(1):end);   
    Col = floor(length(doubledata)/NTS/4);
    double_data = doubledata(1:Col*NTS*4);
    j = sqrt(-1);
    Data1 = double_data(2:4:end)+j*double_data(1:4:end); % First Channel data
    Data2 = double_data(4:4:end)+j*double_data(3:4:end); % Second Channel data    
    
    if MD == 2 % FSK
        FSK_BW = 6e6;
        handles.CarrierFreq = handles.radarmodel;
        set(handles.freqshow,'String',[num2str(handles.CarrierFreq/1e9) '  ,  ' num2str(handles.CarrierFreq/1e9-FSK_BW/1e9)]);
        handles.BandWidth = FSK_BW;
        handles.complexdata1 = Data1;
        handles.complexdata2 = Data2;
        guidata(hObject,handles);
    else
        handles.CarrierFreq = handles.radarmodel + BandWidth/2;
        set(handles.freqshow,'String',[num2str(handles.CarrierFreq/1e9-BandWidth/2e9) '-' num2str(handles.CarrierFreq/1e9+BandWidth/2e9)]);
        handles.complexdata1 = Data1;
        handles.complexdata2 = Data2;
        guidata(hObject,handles);
    end
    
    Rawdata = Data1 - mean(Data1);
    Raw_Data = reshape(Rawdata,NTS,Col);
    
    axes(handles.axes1);
    set(handles.scopepanel,'Title',' RawData of First Channel');
    cla;
    hold off;
    colormap(jet)
    imagesc(20*log10(abs(Raw_Data)));
    clim = get(gca,'CLim');
    set(gca, 'CLim', clim(2)+[-20,0]);
    axis xy;
    xlabel('Number of Sweeps');
    ylabel('Sampling Number');

else % CW mode
    
    handles.CarrierFreq = handles.radarmodel;
    set(handles.freqshow,'String',num2str(handles.CarrierFreq/1e9));    
    double_rawdata = rawdata(index(1):end);
    datalength = floor(length(double_rawdata)/4)*4;
    I_rawdata1 = double_rawdata(2:4:datalength);
    Q_rawdata1 = double_rawdata(1:4:datalength);
    I_rawdata2 = double_rawdata(4:4:datalength);
    Q_rawdata2 = double_rawdata(3:4:datalength);
    j = sqrt(-1);
    Raw_Data1 = I_rawdata1+j*Q_rawdata1;
    Raw_Data2 = I_rawdata2+j*Q_rawdata2;   
    
    handles.complexdata1 = Raw_Data1;
    handles.complexdata2 = Raw_Data2;    
    handles.BandWidth = 0;
    guidata(hObject,handles);
    
    Rawdata = Raw_Data1-mean(Raw_Data1);
    I_rawdata = real(Rawdata);
    Q_rawdata = imag(Rawdata);
    miux = mean(I_rawdata);
    miuy = mean(Q_rawdata);
    I2_bar = mean((I_rawdata-miux).^2);
    Q2_bar = mean((Q_rawdata-miuy).^2);
    IQ_bar = mean((I_rawdata-miux).*(Q_rawdata-miuy));
    D_bar = IQ_bar/I2_bar;
    C_bar = sqrt(Q2_bar/I2_bar-D_bar^2);
    d_ampImb = sqrt(C_bar^2+D_bar^2)-1;
    phi = atan(D_bar/C_bar);
    I_rawdata = I_rawdata - miux;
    Q_rawdata = ((Q_rawdata - miuy)/(1+d_ampImb) - I_rawdata*sin(phi))/cos(phi);
    Rawdata = I_rawdata + 1i*Q_rawdata;
    
    samp_rate = 1/SweepTime*NTS*1000;
    dec = 16;
    fs = samp_rate/dec;
    f = decimate(Rawdata,dec);
    npp = length(f);

    axes(handles.axes1);
    cla;
    set(handles.axes1,'Color','Black');
    set(handles.scopepanel,'Title',' RawData of First Channel');
    plot((1:npp)/fs,abs(f),'y');
    axis([0 npp/fs 0 2500]);
    xlabel('Time(s)');
    ylabel('Amplitude');
    
    hold on;
    xtick=get(gca,'XTick');
    ylim=get(gca,'Ylim');
    X=repmat(xtick,2,1);
    Y=repmat(ylim',1,size(xtick,2));
    plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');
    ytick=get(gca,'YTick');
    xlim=get(gca,'Xlim');
    Y_=repmat(ytick,2,1);
    X_=repmat(xlim',1,size(ytick,2));
    plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':'); 
    
end

handles.recorded = 1;
set(handles.start,'Enable','On');
set(handles.record,'Enable','On');
set(handles.save,'Enable','On');
set(handles.record_time,'Enable','on');
set(handles.replay,'Enable','on');
set(handles.message,'String','Press Save Button Now');
guidata(hObject,handles);


% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.recorded == 1
    [file,path] = uiputfile('*.mat','Save file name');
    if file == 0
        return
    end
    filename = [path,file];
    DATE = handles.date;
    WAVEFORM = handles.wave;
    CENTERFREQUENCY = handles.CarrierFreq;
    BANDWIDTH = handles.BandWidth;
    SWEEPTIME = handles.SweepTime;
    samplenumberpersweep = handles.SweepNumber;
    DATA1 = handles.complexdata1;
    DATA2 = handles.complexdata2;
    
    save(filename,'DATE','WAVEFORM','CENTERFREQUENCY','BANDWIDTH','SWEEPTIME','samplenumberpersweep','DATA1','DATA2');
    message = ['Data Saved Successfully'];
    set(handles.message,'String',message,'ForegroundColor','Green');
else
    message = [' Record before saving '];    
    set(handles.message,'String',  message, 'ForegroundColor','red'); 
end


function record_time_Callback(hObject, eventdata, handles)
% hObject    handle to record_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of record_time as text
%        str2double(get(hObject,'String')) returns contents of record_time as a double
        

% --- Executes during object creation, after setting all properties.
function record_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to record_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in replay.
function replay_Callback(hObject, eventdata, handles)
% hObject    handle to replay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename,pathname] = uigetfile('*.mat');
filename = [pathname,filename];
Rawdata = load(filename);

Data = Rawdata.DATA1;
SweepTime = Rawdata.SWEEPTIME;
NTS = Rawdata.samplenumberpersweep;
Waveform = Rawdata.WAVEFORM;

if strcmp('FMCW_SAWTOOTH',Waveform) || strcmp('FMCW_TRIANGLE',Waveform) || ...
        strcmp('FSK',Waveform)
    
    Raw_Data = Data - mean(Data);
    Col = length(Raw_Data)/NTS;
    G0 = reshape(Raw_Data,NTS,Col);
    
    axes(handles.axes1);
    set(handles.scopepanel,'Title',' RawData  ');
    cla;
    hold off;
    colormap(jet)
    imagesc(20*log10(abs(G0)));
    clim = get(gca,'CLim');
    set(gca, 'CLim', clim(2)+[-20,0]);
    axis xy;
    xlabel('Number of Sweeps');
    ylabel('Sampling Number');
  
elseif strcmp('CW',Waveform)
    
        G0 = Data - mean(Data);
        I_rawdata = real(G0);
        Q_rawdata = imag(G0);
        miux = mean(I_rawdata);
        miuy = mean(Q_rawdata);
        I2_bar = mean((I_rawdata-miux).^2);
        Q2_bar = mean((Q_rawdata-miuy).^2);
        IQ_bar = mean((I_rawdata-miux).*(Q_rawdata-miuy));
        D_bar = IQ_bar/I2_bar;
        C_bar = sqrt(Q2_bar/I2_bar-D_bar^2);
        d_ampImb = sqrt(C_bar^2+D_bar^2)-1;
        phi = atan(D_bar/C_bar);
        I_rawdata = I_rawdata - miux;
        Q_rawdata = ((Q_rawdata - miuy)/(1+d_ampImb) - I_rawdata*sin(phi))/cos(phi);
        Rawdata = I_rawdata + 1i*Q_rawdata;

        samp_rate = 1/SweepTime * NTS * 1000;
        dec = 16; 
        fs = samp_rate/dec;
        f = decimate(Rawdata,dec);
        npp = length(f);

        axes(handles.axes1);
        cla;
        set(handles.axes1,'Color','Black');    
        plot((1:npp)/fs,abs(f),'y');
        axis([0 npp/fs 0 2500]);
        xlabel('Time(s)');
        ylabel('Amplitude');

        hold on;
        xtick=get(gca,'XTick');
        ylim=get(gca,'Ylim');
        X=repmat(xtick,2,1);
        Y=repmat(ylim',1,size(xtick,2));
        plot(X,Y,'Color',[0.23 0.44 0.34],'LineStyle',':');
        ytick=get(gca,'YTick');
        xlim=get(gca,'Xlim');
        Y_=repmat(ytick,2,1);
        X_=repmat(xlim',1,size(ytick,2));
        plot(X_,Y_,'Color',[0.23 0.44 0.34],'LineStyle',':'); 
        
end


% --- Executes on button press in info.
function info_Callback(hObject, eventdata, handles)
% hObject    handle to info (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.info, 'UserData', 1);
handleInfoEvent();


function handleInfoEvent()

hObject = findall(0, 'Tag', 'SDR');
handles = guidata(hObject);
wasOn = get(handles.start, 'UserData');
if ~wasOn
    % Otherwise the thread calls this method
    displayInfoScreen();
end

% --- Loads information screen
function displayInfoScreen()

hObject = findall(0, 'Tag', 'SDR');
handles = guidata(hObject);
infoFig = findall(0, 'Name', 'SDRInfo');

if isempty(infoFig)
    % size
    bgColor = get(hObject, 'Color');
    fgColor = get(handles.control, 'ForegroundColor');
    s = get(0, 'ScreenSize');
    w = 670;
    h = 300;
    ox = (s(3)-w)/2;
    oy = 2*(s(4)-h)/3;
    
    % new figure
    infoFig = figure('Position',[ox oy w h], 'Color',...
        bgColor, 'Name', 'SDRInfo',...
        'NumberTitle', 'off', 'Toolbar', 'none', 'MenuBar', 'none', ...
        'Units', 'normalized', 'Visible', 'off');
    
    % controls
    uicontrol('Style', 'Text', 'String', 'Information & Acknowledgments',...
        'units', 'normalized', 'position', [.2 .80 .6 .1], 'FontWeight', ...
        'bold', 'fontsize', 12, 'Backgroundcolor', bgColor, 'ForegroundColor', ...
        fgColor);
    
    infoStr = ['This graphical user interface (GUI) written in MATLAB provides a simple interface for users to control',...
        ' the radar configuration via a USB cable and to view the real-time results of signal processing.',...
        ' The Ancortek radar currently supports four operation modes: FMCW_sawtooth, FMCW_triangle, FMCW_square(FSK) and CW.',...
        ' The operation modes, signal bandwidth, sampling rate, chirp period and signal processing algorithms',...
        ' are all user controllable. Raw data could be recorded and saved into .mat file for post-processing.',...
        ' Many thanks go out to the MATLAB team that has dedicated much time and effort in the development of GUIDE, making GUI',...
        ' design much easier. This program is distributed in the hope that it will be useful, but'...
        ' WITHOUT ANY WARRANTY, without even the implied warranty of MERCHANTABILITY or FITNESS FOR A'...
        ' PARTICULAR PURPOSE.'];
    
    uicontrol('Style', 'Text', 'String', infoStr,...
        'units', 'normalized', 'position', [.05 .20 .9 .6], ...
        'Backgroundcolor', bgColor, 'ForegroundColor', ...
        fgColor, 'HorizontalAlignment', 'left','fontsize', 10);
    
    figure(infoFig);
else
    figure(infoFig);
end
set(handles.info, 'UserData', 0);


% --- Executes when user attempts to close SDR.
function SDR_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to SDR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

infoFig= findall(0, 'Name', 'SDRInfo');
if ~isempty(infoFig)
    delete(infoFig)
end
pause(.2);

hObject = findall(0,'tag','SDR');
delete(hObject);


% --- Executes on button press in I_state.
function I_state_Callback(hObject, eventdata, handles)
% hObject    handle to I_state (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of I_state


% --- Executes on button press in Q_state.
function Q_state_Callback(hObject, eventdata, handles)
% hObject    handle to Q_state (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Q_state


% --- Executes on button press in rgb_state.
function rgb_state_Callback(hObject, eventdata, handles)
% hObject    handle to rgb_state (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rgb_state
if (get(handles.rgb_state,'Value') == get(handles.rgb_state,'Max'))
%     set(handles.rgb_state,'backgroundcolor','green');
%     set(handles.gray_state,'backgroundcolor',[0.94 0.94 0.94]);
    set(handles.gray_state,'Value',0);
else
    set(handles.gray_state,'Value',1);
end

% --- Executes on button press in gray_state.
function gray_state_Callback(hObject, eventdata, handles)
% hObject    handle to gray_state (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of gray_state
if (get(handles.gray_state,'Value') == get(handles.gray_state,'Max'))
%     set(handles.gray_state,'backgroundcolor','green');
%     set(handles.rgb_state,'backgroundcolor',[0.94 0.94 0.94]);
    set(handles.rgb_state,'Value',0);
else
    set(handles.rgb_state,'Value',1);
end


% --- Executes on selection change in BWSelection.
function BWSelection_Callback(hObject, eventdata, handles)
% hObject    handle to BWSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BWSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BWSelection


% --- Executes during object creation, after setting all properties.
function BWSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BWSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in DurationSelection.
function DurationSelection_Callback(hObject, eventdata, handles)
% hObject    handle to DurationSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns DurationSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DurationSelection


% --- Executes during object creation, after setting all properties.
function DurationSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DurationSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SNSelection.
function SNSelection_Callback(hObject, eventdata, handles)
% hObject    handle to SNSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SNSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SNSelection


% --- Executes during object creation, after setting all properties.
function SNSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SNSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function NotchSlider_Callback(hObject, eventdata, handles)
% hObject    handle to NotchSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
d = get(hObject,'Value');
d = num2str(d);
set(handles.NotchDisplay,'String',d);


% --- Executes during object creation, after setting all properties.
function NotchSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NotchSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function NotchVrSlider_Callback(hObject, eventdata, handles)
% hObject    handle to NotchVrSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
d = get(hObject,'Value');
d = num2str(d);
set(handles.NotchVrDisplay,'String',d);

% --- Executes during object creation, after setting all properties.
function NotchVrSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NotchVrSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in VrNotchFilter.
function VrNotchFilter_Callback(hObject, eventdata, handles)
% hObject    handle to VrNotchFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VrNotchFilter



% --- Executes on button press in noisecancel.
function noisecancel_Callback(hObject, eventdata, handles)
% hObject    handle to noisecancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of noisecancel
noisecheck = get(hObject,'Value');
if noisecheck == 1
    set(handles.butterfilter,'Value',0);
else
    set(handles.butterfilter,'Value',1);
end

% --- Executes on button press in butterfilter.
function butterfilter_Callback(hObject, eventdata, handles)
% hObject    handle to butterfilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of butterfilter
filtercheck = get(hObject,'Value');
if filtercheck == 1
    set(handles.noisecancel,'Value',0);
else
    set(handles.noisecancel,'Value',1);
end


% --- Executes on button press in StreamZoomIn.
function StreamZoomIn_Callback(hObject, eventdata, handles)
% hObject    handle to StreamZoomIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.StreamX,'Xlimit');
setappdata(handles.StreamX,'Xlimit',ZoomValue*2);
guidata(hObject, handles);


% --- Executes on button press in StreamZoomOut.
function StreamZoomOut_Callback(hObject, eventdata, handles)
% hObject    handle to StreamZoomOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.StreamX,'Xlimit');
setappdata(handles.StreamX,'Xlimit',ZoomValue/2);
guidata(hObject, handles);


% --- Executes on button press in StreamZoomIn2.
function StreamZoomIn2_Callback(hObject, eventdata, handles)
% hObject    handle to StreamZoomIn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.StreamY,'Ylimit');
setappdata(handles.StreamY,'Ylimit',ZoomValue*2);
guidata(hObject, handles);

% --- Executes on button press in StreamZoomOut2.
function StreamZoomOut2_Callback(hObject, eventdata, handles)
% hObject    handle to StreamZoomOut2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.StreamY,'Ylimit');
setappdata(handles.StreamY,'Ylimit',ZoomValue/2);
guidata(hObject, handles);


% --- Executes on button press in waterfallZoomIn.
function waterfallZoomIn_Callback(hObject, eventdata, handles)
% hObject    handle to waterfallZoomIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.WaterfallX,'WXlimit');
setappdata(handles.WaterfallX,'WXlimit',ZoomValue*2);
guidata(hObject, handles);


% --- Executes on button press in waterfallZoomOut.
function waterfallZoomOut_Callback(hObject, eventdata, handles)
% hObject    handle to waterfallZoomOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.WaterfallX,'WXlimit');
setappdata(handles.WaterfallX,'WXlimit',ZoomValue/2);
guidata(hObject, handles);


% --- Executes on button press in waterfallZoomIn2.
function waterfallZoomIn2_Callback(hObject, eventdata, handles)
% hObject    handle to waterfallZoomIn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.WaterfallY,'WYlimit');
setappdata(handles.WaterfallY,'WYlimit',ZoomValue*2);
guidata(hObject, handles);


% --- Executes on button press in waterfallZoomOut2.
function waterfallZoomOut2_Callback(hObject, eventdata, handles)
% hObject    handle to waterfallZoomOut2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.WaterfallY,'WYlimit');
setappdata(handles.WaterfallY,'WYlimit',ZoomValue/2);
guidata(hObject, handles);


% --- Executes on button press in rangeZoomIn.
function rangeZoomIn_Callback(hObject, eventdata, handles)
% hObject    handle to rangeZoomIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.RangeX,'RXlimit');
setappdata(handles.RangeX,'RXlimit',ZoomValue*2);
guidata(hObject, handles);


% --- Executes on button press in rangeZoomOut.
function rangeZoomOut_Callback(hObject, eventdata, handles)
% hObject    handle to rangeZoomOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.RangeX,'RXlimit');
setappdata(handles.RangeX,'RXlimit',ZoomValue/2);
guidata(hObject, handles);


% --- Executes on button press in rangeZoomIn2.
function rangeZoomIn2_Callback(hObject, eventdata, handles)
% hObject    handle to rangeZoomIn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.RangeY,'RYlimit');
setappdata(handles.RangeY,'RYlimit',ZoomValue*2);
guidata(hObject, handles);


% --- Executes on button press in rangeZoomOut2.
function rangeZoomOut2_Callback(hObject, eventdata, handles)
% hObject    handle to rangeZoomOut2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.RangeY,'RYlimit');
setappdata(handles.RangeY,'RYlimit',ZoomValue/2);
guidata(hObject, handles);


% --- Executes on button press in DopplerZoomIn.
function DopplerZoomIn_Callback(hObject, eventdata, handles)
% hObject    handle to DopplerZoomIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.DopplerX,'DXlimit');
setappdata(handles.DopplerX,'DXlimit',ZoomValue*2);
guidata(hObject, handles);


% --- Executes on button press in DopplerZoomOut.
function DopplerZoomOut_Callback(hObject, eventdata, handles)
% hObject    handle to DopplerZoomOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.DopplerX,'DXlimit');
setappdata(handles.DopplerX,'DXlimit',ZoomValue/2);
guidata(hObject, handles);


% --- Executes on button press in DopplerZoomIn2.
function DopplerZoomIn2_Callback(hObject, eventdata, handles)
% hObject    handle to DopplerZoomIn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.DopplerY,'DYlimit');
setappdata(handles.DopplerY,'DYlimit',ZoomValue*2);
guidata(hObject, handles);


% --- Executes on button press in DopplerZoomOut2.
function DopplerZoomOut2_Callback(hObject, eventdata, handles)
% hObject    handle to DopplerZoomOut2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomValue = getappdata(handles.DopplerY,'DYlimit');
setappdata(handles.DopplerY,'DYlimit',ZoomValue/2);
guidata(hObject, handles);


% --- Executes on selection change in CHSelection.
function CHSelection_Callback(hObject, eventdata, handles)
% hObject    handle to CHSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns CHSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from CHSelection


% --- Executes during object creation, after setting all properties.
function CHSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CHSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
