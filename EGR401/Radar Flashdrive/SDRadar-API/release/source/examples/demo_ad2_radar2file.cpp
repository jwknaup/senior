// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
// Title:    SDR_API Demo - Radar Samples to File (AD2)
//
// Author:   Ancortek Inc.
// Contact:  info@ancortek.com
//
// Description:
//   Demo. Receives a defined number of sweeps from the radar and writes them
//   to a binary file. The channel can be analyzed in MATLAB using the following
//   commands:
//
//   % Open binary radar collection
//   fileID = fopen('sdr_data.bin');
//   data = fread(fileID, inf, 'ushort');
//   fclose(fileID);
//   aQ = data(1:4:end) - (32768 .* (data(1:4:end) > 32767));
//   aI = data(2:4:end);
//   bQ = data(3:4:end) - (32768 .* (data(3:4:end) > 32767));
//   bI = data(4:4:end);
//   channelA = aI + (1i).*aI;
//   channelB = bI + (1i).*bI;
//
//   This program is distributed in the hope that it will be useful,
//   but WITHOUT ANY WARRANTY; without even the implied warranty of
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//   GNU General Public License for more details.
//
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

// Standard Includes
#include <iostream>
#include <chrono>
#include <fstream>
#include <cmath>

// Include Ancortek's SDR API
#include "../sdradar.h"

// Specify desired number of sweeps
size_t desired_sweeps = 200;

// Main Test Routine
int main (int argc, char* argv[])
{
    // Determine if the user specified the number of sweeps
    if ((argc == 2) and (atoi (argv[1]) > 0))
        desired_sweeps = atoi (argv[1]);

    // Instantiate a new SDRadar
    SDRadar2 *sdr = new SDRadar2 ();

    // Set the desired radar parameters
    sdr->Parameters.options.bandwidth = SDRadar2::BW_1500_MHz;
    sdr->Parameters.options.operating_mode = SDRadar2::OM_Sawtooth;
    sdr->Parameters.options.sampling_number = SDRadar2::SN_128;
    sdr->Parameters.options.sweep_time = SDRadar2::ST_1_ms;
    sdr->update_radar_parameters ();

    // Calculate the number of samples per sweep
    size_t samples_per_sweep = (1 << (7 + sdr->Parameters.options.sampling_number));

    // Calculate the receive buffer size
    // MUL2 - 2 chars (1-byte) per short (2-bytes)
    // MUL2 - 2 shorts per complex
    // MUL2 - 2 for two channels
    size_t buffer_size = 8 * samples_per_sweep * desired_sweeps + SDR_SKIP_HEAD + SDR_PEAK_SEARCH_HEAD;

    // Create a buffer to hold our received samples
    unsigned char *buffer_char = new unsigned char[buffer_size];

    // Request data from the device
    size_t received_samples = sdr->request_data_synchronous (buffer_size, buffer_char, SDR_TIMEOUT_READ_INFINITE);

    // Instantiate a pointer (as SHORT) to hold start of first peak
    uint16_t *buffer_uint16 = reinterpret_cast<uint16_t*> (buffer_char);

    // Hunt for first peak
    size_t skip_count;
    for (skip_count = SDR_SKIP_HEAD / 2; skip_count < received_samples / sizeof (*buffer_uint16); skip_count++)
        if (buffer_uint16[skip_count] > 32767) break;

    // Determine the total number of sweeps collected past the skip point
    size_t total_sweeps_collected = std::floor (((received_samples / 2.0) - skip_count) / samples_per_sweep / 4.0);
    std::cout << "Collected a total of " << total_sweeps_collected << " sweeps." << std::endl;

    // Determine the number of uint16 values to write to the output file
    size_t write_count = std::min (desired_sweeps, total_sweeps_collected) * samples_per_sweep * 4;

    // Start an output file
    FILE *file = std::fopen ("sdr2_data.bin", "wb");

    // Write the buffer to a file
    std::fwrite (buffer_uint16 + skip_count, sizeof (*buffer_uint16), write_count, file);

    // Close our file handle
    std::fclose (file);

    // Print out the number of bytes received and the time
    std::cout << "Wrote " << write_count << " uint16 samples to a file." << std::endl;

    // Destroy our SDRadar object
    delete sdr;

    // See you space cowboy...
    return 0;
}
