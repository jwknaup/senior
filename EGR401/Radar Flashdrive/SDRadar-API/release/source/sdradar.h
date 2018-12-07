// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
// Title:    SDR_API for C++
//
// Author:   Ancortek Inc.
// Contact:  info@Ancortek.com
//
// Description:
//   The SDRadar class provide a simple and intuitive way to pull data from any
//   of Ancortek's SDR kits using LibUSB.
//
//   This program is distributed in the hope that it will be useful,
//   but WITHOUT ANY WARRANTY; without even the implied warranty of
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

// Standard Includes
#include <chrono>
#include <thread>
#include <iostream>
#include <exception>
#include <stdexcept>
#include <cstring>

// Include LibUSB
#include <libusb-1.0/libusb.h>

// Setup Cypress VID/PID
#define SDR_USB_VID 0x04b4
#define SDR_USB_PID 0x8613

// Setup LibUSB Endpoints
#define SDR_ENDPOINT_RX 0x86                    // Endpoint - Device to PC
#define SDR_ENDPOINT_TX 0x02                    // Endpoint - PC to Device

// Define Timeouts
#define SDR_TIMEOUT_FIRMWARE_WRITE_MS 1000      // Firmware write timeout
#define SDR_TIMEOUT_DEVICE_RESET_MS 1000        // Device reset timeout
#define SDR_TIMEOUT_READ_DATA_MS 1000           // Read data from device timeout
#define SDR_TIMEOUT_READ_INFINITE 0             // Read data infinetely

// Define Sample Skip Counts
#define SDR_SKIP_HEAD 4096
#define SDR_PEAK_SEARCH_HEAD 4096

// LibUSB Transfer Lengths
#define SDR_INSTRUCTION_COPIES 2048

// Ancortek SDR Interface Class
class SDRadar
{
public:

    // Public Class Constructor
    SDRadar ( );

    // Public Class Destructor
    ~SDRadar ( );

    // Public Method - Send radar parameters to device
    void update_radar_parameters ( );

    // Public Method - Synchronous (blocking) request for data
    // (Returns the number of bytes received)
    int request_data_synchronous (
                                   unsigned int requested_bytes,
                                   unsigned char *buffer,
                                   unsigned int timrout_ms = SDR_TIMEOUT_READ_DATA_MS
                                   );

    // Public Method - Clear FIFO Buffers
    void clear_fifo_buffers ( );

    // Public Enumeration - Operation Modes
    enum Parameter_Options : uint16_t
    {
        OM_Sawtooth = 0, // Operate in FMCW sawtooth mode
        OM_Triangle = 1, // Operate in FMCW triangle mode
        OM_Sine = 2, // Operate in FMCW sine mode
        OM_FSK = 3, // Operate in FSK mode
        OM_CW = 4, // Operate in continuous wave (CW) mode
        BW_400_MHz = 0, // Bandwidth = 400 MHz
        BW_150_MHz = 1, // Bandwidth = 150 MHz
        BW_200_MHz = 2, // Bandwidth = 200 MHz
        BW_300_MHz = 3, // Bandwidth = 300 MHz
        ST_0_983_ms = 0, // Sweep Time = 0.983 milliseconds
        ST_2_048_ms = 1, // Sweep Time = 2.048 milliseconds
        ST_4_014_ms = 2, // Sweep Time = 4.014 milliseconds
        ST_6_062_ms = 3, // Sweep Time = 6.062 milliseconds
        SN_128 = 0, // Collect 128 samples per sweep
        SN_256 = 1, // Collect 256 samples per sweep
        SN_512 = 2, // Collect 512 samples per sweep
        SN_1024 = 3 // Collect 1024 samples per sweep
    };

    // Radar Operating Parameters - Firmware Values
    union SDR_Parameters
    {
        // Individual Option Access
        struct
        {
            uint16_t operating_mode : 2;
            uint16_t sampling_number : 2;
            uint16_t bandwidth : 2;
            uint16_t sweep_time : 2;
            uint16_t header : 8;
        } options;

        // High/Low Byte Access
        struct
        {
            uint16_t low : 8;
            uint16_t high : 8;
        } bytes;

        // Full 16-bit Access
        uint16_t value;
    } Parameters = { .options =
        { 0x00, 0x00, 0x00, 0x00, 0xa0 } };

private:
    // LibUSB Context
    libusb_context *sdr_context;

    // LibUSB Device Handle
    libusb_device_handle *sdr_handle;

    // Private Method - Initialize LibUSB Device
    void initialize ( );
};

// Ancortek SDR 2-Channel Interface Class
class SDRadar2 : public SDRadar
{
public:

    // Public Enumeration - Operation Modes
    enum Parameter_Options : uint16_t
    {
        OM_Sawtooth = 0, // Operate in FMCW sawtooth mode
        OM_Triangle = 1, // Operate in FMCW triangle mode
        OM_Sine = 2, // Operate in FMCW sine mode
        OM_FSK = 3, // Operate in FSK mode
        OM_CW = 4, // Operate in continuous wave (CW) mode
        BW_2000_MHz = 0, // Bandwidth = 2000 MHz
        BW_0500_MHz = 1, // Bandwidth =  500 MHz
        BW_0750_MHz = 2, // Bandwidth =  750 MHz
        BW_1500_MHz = 3, // Bandwidth = 1500 MHz
        ST_1_ms = 0, // Sweep Time = 1.0 milliseconds
        ST_2_ms = 1, // Sweep Time = 2.0 milliseconds
        ST_4_ms = 2, // Sweep Time = 4.0 milliseconds
        ST_10_ms = 3, // Sweep Time = 10.0 milliseconds
        SN_128 = 0, // Collect 128 samples per sweep
        SN_256 = 1, // Collect 256 samples per sweep
        SN_512 = 2, // Collect 512 samples per sweep
        SN_1024 = 3 // Collect 1024 samples per sweep
    };
};

