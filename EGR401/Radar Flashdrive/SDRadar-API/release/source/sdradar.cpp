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

// Include Ancortek's SDR API
#include "sdradar.h"

// Public Class Constructor
SDRadar::SDRadar ()
{
    // Initialize LibUSB pointers to NULL
    sdr_context = NULL;
    sdr_handle = NULL;

    // Initialize the SDRadar
    initialize ();

    // Update the radar's operating parameters to default
    Parameters.options.bandwidth = SDRadar::BW_150_MHz;
    Parameters.options.operating_mode = SDRadar::OM_FSK;
    Parameters.options.sampling_number = SDRadar::SN_1024;
    Parameters.options.sweep_time = SDRadar::ST_0_983_ms;
    update_radar_parameters ();
}

// Public Class Destructor
SDRadar::~SDRadar ()
{
    // Release the LibUSB interface claimed for the handle
    if (sdr_handle) libusb_release_interface (sdr_handle, 0);

    // Close the SDR LibUSB device handle
    if (sdr_handle) libusb_close (sdr_handle);

    // Destroy the LibUSB context
    if (sdr_context) libusb_exit (sdr_context);
}

// Public Method - Send radar parameters to device
void SDRadar::update_radar_parameters ()
{
    // Instantiate instruction buffer
    unsigned char *instruction_buffer = new unsigned char[SDR_INSTRUCTION_COPIES];

    // Fill the instruction buffer
    for (int i = 0; i < SDR_INSTRUCTION_COPIES; i += 2)
        std::memcpy (instruction_buffer + i, &(Parameters.value), 2);

    // Keep track of the number of bytes transfered to the device
    int bytes_sent = 0;

    // Attempt a bulk data transfer from the device to the PC
    int libusb_status = libusb_bulk_transfer (sdr_handle, SDR_ENDPOINT_TX, instruction_buffer, SDR_INSTRUCTION_COPIES, &bytes_sent, SDR_TIMEOUT_READ_DATA_MS);

    // Check for any errors from LibUSB
    if (libusb_status != LIBUSB_SUCCESS)
        std::cerr << "Error: libusb_bulk_transfer out returned code " << libusb_status << ": " << libusb_error_name (libusb_status) << std::endl;
}

// Public Method - Synchronous (blocking) request for data
// (Returns the number of bytes received)
int SDRadar::request_data_synchronous (
                                       unsigned int requested_bytes,
                                       unsigned char *buffer,
                                       unsigned int timrout_ms
                                       )
{
    // Keep track of the number of bytes attained from the device
    int bytes_attained = -1;

    // Attempt a bulk data transfer from the device to the PC
    int libusb_status = libusb_bulk_transfer (sdr_handle, SDR_ENDPOINT_RX, buffer, requested_bytes, &bytes_attained, timrout_ms);

    // Check for any errors from LibUSB
    if (libusb_status != LIBUSB_SUCCESS)
        std::cerr << "Error: libusb_bulk_transfer in returned code " << libusb_status << ": " << libusb_error_name (libusb_status) << std::endl;

    // Return the number of bytes received
    return bytes_attained;
}

// Public Method - Clear FIFO Buffers
void SDRadar::clear_fifo_buffers ()
{
    // Bring the device out of the reset state
    unsigned char data_char = 0x80;
    if (libusb_control_transfer (sdr_handle, 0x40, 0xa0, 0xe604, 0, &data_char, 1, SDR_TIMEOUT_DEVICE_RESET_MS) != 1)
        throw std::runtime_error ("Error: Could not bring the device out of reset mode.");

    // Sleep for 100ms
    std::this_thread::sleep_for (std::chrono::milliseconds (100));

    // Bring the device out of the reset state
    data_char = 0x06;
    if (libusb_control_transfer (sdr_handle, 0x40, 0xa0, 0xe604, 0, &data_char, 1, SDR_TIMEOUT_DEVICE_RESET_MS) != 1)
        throw std::runtime_error ("Error: Could not bring the device out of reset mode.");

    // Sleep for 100ms
    std::this_thread::sleep_for (std::chrono::milliseconds (100));

    // Bring the device out of the reset state
    data_char = 0x00;
    if (libusb_control_transfer (sdr_handle, 0x40, 0xa0, 0xe604, 0, &data_char, 1, SDR_TIMEOUT_DEVICE_RESET_MS) != 1)
        throw std::runtime_error ("Error: Could not bring the device out of reset mode.");

    // Sleep for 100ms
    //std::this_thread::sleep_for ( std::chrono::milliseconds ( 100 ) );
}


// Private Method - Initialize LibUSB Device
void SDRadar::initialize ()
{
    // Throw an error if we encounter any problems
    try
    {
        // Initialize LibUSB
        if (libusb_init (&sdr_context) != LIBUSB_SUCCESS)
            throw std::runtime_error ("Error: Could not initialize LibUSB.");

        // Open the device matching our SDR's VID and PID
        sdr_handle = libusb_open_device_with_vid_pid (sdr_context, SDR_USB_VID, SDR_USB_PID);
        if (!sdr_handle)
            throw std::runtime_error ("Error: LibUSB could not find a matching VID/PID or an error was encountered.");

        // Read the current value of the CPUCS register
        unsigned char reset_char;
        if (libusb_control_transfer (sdr_handle, 0xc0, 0xa0, 0xe600, 0, &reset_char, 1, SDR_TIMEOUT_DEVICE_RESET_MS) != 1)
            throw std::runtime_error ("Error: Could not read the CPUCS register.");

        // Place the device into reset
        reset_char = reset_char | 0x01;
        if (libusb_control_transfer (sdr_handle, 0x40, 0xa0, 0xe600, 0, &reset_char, 1, SDR_TIMEOUT_DEVICE_RESET_MS) != 1)
            throw std::runtime_error ("Error: Could not bring the device into reset mode.");

        // Sleep for 100ms (wait for device to enter reset)
        std::this_thread::sleep_for (std::chrono::milliseconds (100));

        // Cypress FX2LP USB Firmware
        // [0] Length of data to write
        // [2] Address start of write
        // [4] Start of data to write
        unsigned char firmware[15][21] = {
            {0x03, 0x00, 0x00, 0x00, 0x02, 0x00, 0xB8, 0x43, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
            {0x0C, 0x00, 0xB8, 0x00, 0x78, 0x7F, 0xE4, 0xF6, 0xD8, 0xFD, 0x75, 0x81, 0x07, 0x02, 0x00, 0x03, 0x94, 0x00, 0x00, 0x00, 0x00},
            {0x10, 0x00, 0x03, 0x00, 0x90, 0xE6, 0x00, 0x74, 0x12, 0xF0, 0x00, 0x00, 0x00, 0xA3, 0x74, 0xCB, 0xF0, 0x00, 0x00, 0x00, 0x2F},
            {0x10, 0x00, 0x13, 0x00, 0x90, 0xE6, 0x0B, 0x74, 0x01, 0xF0, 0x00, 0x00, 0x00, 0x90, 0xE6, 0x12, 0x74, 0xA2, 0xF0, 0x00, 0x69},
            {0x10, 0x00, 0x23, 0x00, 0x00, 0x00, 0x90, 0xE6, 0x14, 0x74, 0xE0, 0xF0, 0x00, 0x00, 0x00, 0xE4, 0x90, 0xE6, 0x13, 0xF0, 0xA2},
            {0x10, 0x00, 0x33, 0x00, 0x00, 0x00, 0x00, 0x90, 0xE6, 0x15, 0xF0, 0x00, 0x00, 0x00, 0x90, 0xE6, 0x04, 0x74, 0x80, 0xF0, 0xE4},
            {0x10, 0x00, 0x43, 0x00, 0x00, 0x00, 0x00, 0x74, 0x82, 0xF0, 0x00, 0x00, 0x00, 0x74, 0x84, 0xF0, 0x00, 0x00, 0x00, 0x74, 0x6B},
            {0x10, 0x00, 0x53, 0x00, 0x86, 0xF0, 0x00, 0x00, 0x00, 0x74, 0x88, 0xF0, 0x00, 0x00, 0x00, 0xE4, 0xF0, 0x00, 0x00, 0x00, 0x67},
            {0x10, 0x00, 0x63, 0x00, 0x90, 0xE6, 0x1A, 0x74, 0x0D, 0xF0, 0x00, 0x00, 0x00, 0x90, 0xE6, 0x18, 0x74, 0x01, 0xF0, 0x00, 0x99},
            {0x10, 0x00, 0x73, 0x00, 0x00, 0x00, 0x74, 0x11, 0xF0, 0x00, 0x00, 0x00, 0xE4, 0x90, 0xE6, 0x09, 0xF0, 0x00, 0x00, 0x00, 0xB5},
            {0x10, 0x00, 0x83, 0x00, 0x90, 0xE6, 0x02, 0x74, 0xE0, 0xF0, 0x00, 0x00, 0x00, 0xA3, 0x74, 0x08, 0xF0, 0x00, 0x00, 0x00, 0xA2},
            {0x10, 0x00, 0x93, 0x00, 0x90, 0xE6, 0x24, 0x74, 0x02, 0xF0, 0x00, 0x00, 0x00, 0xE4, 0xA3, 0xF0, 0x00, 0x00, 0x00, 0x90, 0x56},
            {0x10, 0x00, 0xA3, 0x00, 0xE6, 0x34, 0x74, 0x80, 0xF0, 0x00, 0x00, 0x00, 0xE4, 0xA3, 0xF0, 0x90, 0xE6, 0x70, 0x74, 0x40, 0x3E},
            {0x05, 0x00, 0xB3, 0x00, 0xF0, 0x00, 0x00, 0x00, 0x22, 0x36, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
            {0x00, 0x00, 0x00, 0x01, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
        };

        // Declare the number firmware rows
        const int firmware_rows = 15;

        // Iterate through each row of our firmware
        for (int row = 0; row < firmware_rows; row++)
        {
            // Determine the length (in bytes) to write
            unsigned int write_length = firmware[row][0];

            // Ensure the write_length is greater than zero
            if (write_length > 0)
            {
                // Determine the address to start writing
                unsigned int write_address = firmware[row][2];

                // Transfer firmware to the device
                if (libusb_control_transfer (sdr_handle, 0x40, 0xa0, write_address, 0, firmware[row] + 4, write_length, SDR_TIMEOUT_FIRMWARE_WRITE_MS) != write_length)
                    throw std::runtime_error ("ERROR: Firmware did not write the desired number of bytes.");
            }
        }

        // Bring the device out of the reset state
        reset_char = reset_char & 0xFE;
        if (libusb_control_transfer (sdr_handle, 0x40, 0xa0, 0xe600, 0, &reset_char, 1, SDR_TIMEOUT_DEVICE_RESET_MS) != 1)
            throw std::runtime_error ("Error: Could not bring the device out of reset mode.");

        // Sleep for 100ms (wait for device to come out of reset and re-enumerate)
        std::this_thread::sleep_for (std::chrono::milliseconds (500));

        // Release the LibUSB interface claimed for the handle
        if (sdr_handle) libusb_release_interface (sdr_handle, 0);

        // Close the SDR LibUSB device handle
        if (sdr_handle) libusb_close (sdr_handle);

        // Open the device matching the updated VID and PID
        sdr_handle = libusb_open_device_with_vid_pid (sdr_context, SDR_USB_VID, SDR_USB_PID);
        if (!sdr_handle)
            throw std::runtime_error ("Error: LibUSB could not find a matching VID/PID or an error was encountered.");

        // Claim the USB Interface
        if (libusb_claim_interface (sdr_handle, 0) != LIBUSB_SUCCESS)
            throw std::runtime_error ("Error: Could not claim interface 0.");

        // Set alternate interface
        if (libusb_set_interface_alt_setting (sdr_handle, 0, 1) != LIBUSB_SUCCESS)
            throw std::runtime_error ("Error: Could not set interface 0 to alternate setting (1).");
    }

    // Catch and report any error encountered
    catch (const std::runtime_error &e)
    {
        // Release the LibUSB interface claimed for the handle
        if (sdr_handle) libusb_release_interface (sdr_handle, 0);

        // Close the SDR LibUSB device handle
        if (sdr_handle) libusb_close (sdr_handle);

        // Destroy the LibUSB context
        if (sdr_context) libusb_exit (sdr_context);

        // Print out the error message
        std::cerr << e.what () << std::endl;

        // Exit
        exit (-1);
    }
}
