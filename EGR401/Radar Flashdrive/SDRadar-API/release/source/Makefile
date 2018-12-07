# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Title:    SDR_API for C++
#
# Author:   Ancortek Inc.
# Contact:  Info@Ancortek.com
#
# Description:
#   The SDR_API class provide a simple and intuitive way to pull data from any
#   of Ancortek's software defined radios over USB. Check out demo.cpp for a
#   simple demonstration.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, version 3 of the License.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Specify Desired Compilers
CXX := g++
	
# Flags
CXXFLAGS := -O3 -pipe -std=c++11
LIBS := -L/usr/local/lib -lusb-1.0 -lfftw3 -lm

# Build Default
all: release
	
# Setup Release
release: sdradar.o
release: examples_

# Setup Debug
debug: CXXFLAGS += -DDEBUG -g
debug: CCFLAGS += -DDEBUG -g
Debug: release
	
# Build API
sdradar.o: sdradar.cpp sdradar.h
	$(CXX) $(CXXFLAGS) -c sdradar.cpp -o sdradar.o

# Setup Examples
examples_: examples/demo_ad_radar2file
examples_: examples/demo_ad_radar2udp
examples_: examples/demo_ad_fmcw_ranging
examples_: examples/demo_ad2_radar2file
examples_: examples/demo_ad2_radar2udp
examples_: examples/demo_ad2_fmcw_ranging

# Build Example - Radar to File
examples/demo_ad_radar2file: examples/demo_ad_radar2file.o sdradar.o
	$(CXX) $(CXXFLAGS) -o examples/demo_ad_radar2file examples/demo_ad_radar2file.o sdradar.o $(LIBS)
examples/demo_ad_radar2file.o: examples/demo_ad_radar2file.cpp sdradar.o
	$(CXX) $(CXXFLAGS) -c examples/demo_ad_radar2file.cpp -o examples/demo_ad_radar2file.o $(LIBS)

# Build Example - Radar to UDP
examples/demo_ad_radar2udp: examples/demo_ad_radar2udp.o sdradar.o
	$(CXX) $(CXXFLAGS) -o examples/demo_ad_radar2udp examples/demo_ad_radar2udp.o sdradar.o $(LIBS)
examples/demo_ad_radar2udp.o: examples/demo_ad_radar2udp.cpp sdradar.o
	$(CXX) $(CXXFLAGS) -c examples/demo_ad_radar2udp.cpp -o examples/demo_ad_radar2udp.o $(LIBS)

# Build Example - Range Printing
examples/demo_ad_fmcw_ranging: examples/demo_ad_fmcw_ranging.o sdradar.o
	$(CXX) $(CXXFLAGS) -o examples/demo_ad_fmcw_ranging examples/demo_ad_fmcw_ranging.o sdradar.o $(LIBS)
examples/demo_ad_fmcw_ranging.o: examples/demo_ad_fmcw_ranging.cpp sdradar.o
	$(CXX) $(CXXFLAGS) -c examples/demo_ad_fmcw_ranging.cpp -o examples/demo_ad_fmcw_ranging.o $(LIBS)

# Build Example - Radar to File (AD2)
examples/demo_ad2_radar2file: examples/demo_ad2_radar2file.o sdradar.o
	$(CXX) $(CXXFLAGS) -o examples/demo_ad2_radar2file examples/demo_ad2_radar2file.o sdradar.o $(LIBS)
examples/demo_ad2_radar2file.o: examples/demo_ad2_radar2file.cpp sdradar.o
	$(CXX) $(CXXFLAGS) -c examples/demo_ad2_radar2file.cpp -o examples/demo_ad2_radar2file.o $(LIBS)

# Build Example - Radar to UDP (AD2)
examples/demo_ad2_radar2udp: examples/demo_ad2_radar2udp.o sdradar.o
	$(CXX) $(CXXFLAGS) -o examples/demo_ad2_radar2udp examples/demo_ad2_radar2udp.o sdradar.o $(LIBS)
examples/demo_ad2_radar2udp.o: examples/demo_ad2_radar2udp.cpp sdradar.o
	$(CXX) $(CXXFLAGS) -c examples/demo_ad2_radar2udp.cpp -o examples/demo_ad2_radar2udp.o $(LIBS)

# Build Example - Range Printing (AD2)
examples/demo_ad2_fmcw_ranging: examples/demo_ad2_fmcw_ranging.o sdradar.o
	$(CXX) $(CXXFLAGS) -o examples/demo_ad2_fmcw_ranging examples/demo_ad2_fmcw_ranging.o sdradar.o $(LIBS)
examples/demo_ad2_fmcw_ranging.o: examples/demo_ad2_fmcw_ranging.cpp sdradar.o
	$(CXX) $(CXXFLAGS) -c examples/demo_ad2_fmcw_ranging.cpp -o examples/demo_ad2_fmcw_ranging.o $(LIBS)
	
# Clean Up!
clean:
	rm -rf *.o
	rm -rf examples/*.o
	rm -rf examples/demo_ad_radar2file
	rm -rf examples/demo_ad_radar2udp
	rm -rf examples/demo_ad_fmcw_ranging
	rm -rf examples/demo_ad2_radar2file
	rm -rf examples/demo_ad2_radar2udp
	rm -rf examples/demo_ad2_fmcw_ranging
