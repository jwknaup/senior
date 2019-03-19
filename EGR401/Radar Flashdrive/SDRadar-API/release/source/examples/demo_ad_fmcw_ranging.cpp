// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
// Title:    SDR_API Demo - Display Real-Time Range Information
//
// Author:   Ancortek Inc.
// Contact:  info@ancortek.com
//
// Description:
//   Demo. This demonstration instantiates an SDRadar class and configures
//   it for FMCW operation. The range information is printed to the screen.
//
//   !! REQUIRES FFTW3 !!
//   Ubuntu Install: sudo apt-get install libfftw3-dev
//
//   This program is free software: you can redistribute it and/or modify
//   it under the terms of the GNU General Public License as published by
//   the Free Software Foundation, version 3 of the License.
//
//   This program is distributed in the hope that it will be useful,
//   but WITHOUT ANY WARRANTY; without even the implied warranty of
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//   GNU General Public License for more details.
//
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

// Standard Includes
#include <algorithm>
#include <iostream>
#include <chrono>
#include <thread>
#include <fstream>
#include <complex>
#include <string>
#include <vector>

// Use FFTW
#include <fftw3.h>

// Include Ancortek's SDR API
#include "../sdradar.h"

// Main Test Routine
int main (int argc, char* argv[])
{
    // Instantiate a new SDRadar
    SDRadar * sdr = new SDRadar ();

    // Set the desired radar parameters
    sdr->Parameters.options.bandwidth = SDRadar::BW_400_MHz;
    sdr->Parameters.options.operating_mode = SDRadar::OM_Sawtooth;
    sdr->Parameters.options.sampling_number = SDRadar::SN_128;
    sdr->Parameters.options.sweep_time = SDRadar::ST_0_983_ms;
    sdr->update_radar_parameters ();

    // Calculate the number of samples per sweep
    size_t samples_per_sweep = (1 << (7 + sdr->Parameters.options.sampling_number));

    // Calculate the receive buffer size
    // MUL2 - 2 chars (1-byte) per short (2-bytes)
    // MUL2 - 2 shorts per complex
    size_t char_buffer_size = samples_per_sweep * 2 * 2 + SDR_PEAK_SEARCH_HEAD + SDR_SKIP_HEAD;

    // Create a buffer to hold our received samples
    unsigned char *buffer = new unsigned char[char_buffer_size];

    // Reinterpret buffer as 16-bit short values
    uint16_t *buffer_uint16;

    // Construct complex variable to hold average of sweeps
    std::complex<double> *sweep_raw = new std::complex<double>[samples_per_sweep];

    // Construct double variable to hold result magnitude
    double *sweep_magnitude = new double[samples_per_sweep];

    // Setup FFTW Pointers and Plan
    fftw_complex *fft_data = (fftw_complex*) sweep_raw;
    fftw_plan fft_plan = fftw_plan_dft_1d ((int) samples_per_sweep, fft_data, fft_data, FFTW_FORWARD, FFTW_ESTIMATE);

    // Compute FMCW Range Factor (ADJUST DEPENDING ON BANDWIDTH ABOVE)
    double range_factor = 3.0e8 / 2.0 / 400.0e6;

    // Set Minimum Range Detection (ignore all results before 1.0m)
    size_t min_range_index = (int) std::ceil (1.5 / range_factor);

    // Set Output Precision
    std::cout.precision (4);

    // Loop until program terminates
    while (true)
    {
        // Request data from the device
        size_t received_samples = sdr->request_data_synchronous (char_buffer_size, buffer, SDR_TIMEOUT_READ_INFINITE);

        // Hunt for first peak
        for (buffer_uint16 = reinterpret_cast<uint16_t*> (buffer + SDR_SKIP_HEAD); buffer_uint16 < (buffer_uint16 + received_samples - SDR_SKIP_HEAD); buffer_uint16++)
            if (*buffer_uint16 > 32767) break;

        // Place the samples in a std::complex<double> array for processing
        memset (sweep_raw, 0, sizeof (std::complex<double>) * samples_per_sweep);
        for (int i = 0; i < samples_per_sweep; i++)
            sweep_raw[i] = std::complex<double>(buffer_uint16[2 * i + 1], buffer_uint16[2 * i] & (unsigned short) 0x7FFF);

        // Perform DC Subtraction
        std::complex<double> meanValue = std::complex<double>(0.0, 0.0);
        for (std::complex<double> *currentItem = sweep_raw; currentItem < sweep_raw + samples_per_sweep; currentItem++)
            meanValue += *currentItem;
        meanValue /= samples_per_sweep;
        for (std::complex<double> *currentItem = sweep_raw; currentItem < sweep_raw + samples_per_sweep; currentItem++)
            *currentItem -= meanValue;

        // Execute in-place FFT on sweep average
        fftw_execute (fft_plan);

        // Compute Magnitude in dB
        for (int i = 0; i < samples_per_sweep; i++)
            sweep_magnitude[i] = 10.0 * std::log10 (std::norm (sweep_raw[i]));

        // Determine Maximum
        double *max_element_ptr = std::max_element (sweep_magnitude + min_range_index, sweep_magnitude + (samples_per_sweep / 2));
        size_t max_range_index = std::distance (sweep_magnitude, max_element_ptr);

        // Print Report
        std::cout << std::fixed << "\rRange: " << (range_factor * max_range_index) << "m ([" << max_range_index << "] " << *max_element_ptr << "dB)" << std::flush;

        // Sleep for a little bit
        std::this_thread::sleep_for (std::chrono::milliseconds (100));
    }

    // Destroy our SDRadar object
    delete sdr;

    // See you space cowboy...
    return 0;
}
