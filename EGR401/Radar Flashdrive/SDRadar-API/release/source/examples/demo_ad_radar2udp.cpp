// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
// Title:    SDR_API Demo - Radar Samples to UDP Server
//
// Author:   Ancortek Inc.
// Contact:  info@ancortek.com
//
// Description:
//   Demo. Received a defined number of samples from the radar and writes them
//   to a udp port.
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
#include <thread>
#include <fstream>
#include <complex>
#include <string>

// Network Includes
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <stdlib.h>

// Include Ancortek's SDR API
#include "../sdradar.h"

// Specify the number of samples to receive
#define UDP_BLOCK_SIZE 128 * 16

// Main Test Routine
int main (int argc, char* argv[])
{
    // Specify the receiving IP address and port
    std::string udp_ip_address;
    int udp_port;

    // Determine if the user specified the ip address and port
    if ((argc == 3) and (atoi (argv[2]) > 0))
    {
        udp_ip_address.assign (argv[1]);
        udp_port = atoi (argv[2]);
    }
    else
    {
        std::cerr << "You must specify the destination IP address. "
                << "Example: ./demo_ad_radar2udp 127.0.0.1 9331" << std::endl;
        return (1);
    }

    // Instantiate a new SDRadar
    SDRadar * sdr = new SDRadar ();

    // Set the desired radar parameters
    sdr->Parameters.options.bandwidth = SDRadar::BW_400_MHz;
    sdr->Parameters.options.operating_mode = SDRadar::OM_Sawtooth;
    sdr->Parameters.options.sampling_number = SDRadar::SN_128;
    sdr->Parameters.options.sweep_time = SDRadar::ST_0_983_ms;
    sdr->update_radar_parameters ();

    // Calculate the receive buffer size
    // MUL2 - 2 chars (1-byte) per short (2-bytes)
    // MUL2 - 2 shorts per complex
    size_t char_buffer_size = UDP_BLOCK_SIZE * 2 * 2 + SDR_PEAK_SEARCH_HEAD + SDR_SKIP_HEAD;

    // Create a buffer to hold our received samples
    unsigned char *buffer = new unsigned char[char_buffer_size];

    // Reinterpret buffer as 16-bit short values
    uint16_t *buffer_uint16;

    // Setup socket structures
    struct sockaddr_in serv_addr;
    int sockfd, i, slen = sizeof (serv_addr);
    if ((sockfd = socket (AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
    {
        std::cerr << "Couldn't setup the socket" << std::endl;
        exit (1);
    }
    bzero (&serv_addr, sizeof (serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons (udp_port);
    if (inet_aton (udp_ip_address.c_str (), &serv_addr.sin_addr) == 0)
    {
        fprintf (stderr, "inet_aton() failed\n");
        exit (1);
    }

    // Loop until program terminates
    while (true)
    {
        // Request data from the device
        size_t received_samples = sdr->request_data_synchronous (char_buffer_size, buffer, SDR_TIMEOUT_READ_INFINITE);

        // Hunt for first peak
        for (buffer_uint16 = reinterpret_cast<uint16_t*> (buffer + SDR_SKIP_HEAD); buffer_uint16 < (buffer_uint16 + received_samples - SDR_SKIP_HEAD); buffer_uint16++)
            if (*buffer_uint16 > 32767) break;

        // Transmit the samples over UDP
        int udp_send_size = sendto (sockfd, buffer_uint16, UDP_BLOCK_SIZE * 4, 0, (struct sockaddr*) &serv_addr, slen);

        // Check to see if it was successful
        if (udp_send_size == -1)
            std::cout << "Error sending the data." << std::endl;

        // Sleep for a little bit
        std::this_thread::sleep_for (std::chrono::milliseconds (200));
    }

    // Close the UDP socket
    close (sockfd);

    // Destroy our SDRadar object
    delete sdr;

    // See you space cowboy...
    return 0;
}
