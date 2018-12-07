# Ancortek SDR API for C++  
*A C++ class to control Ancortek's software defined radars using the LibUSB framework.*  
Copyright (C) 2017 Ancortek Incorporated  
  
This program is distributed in the hope that it will be useful,  
but WITHOUT ANY WARRANTY; without even the implied warranty of  
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.  

## Notes  
1. Make sure you have LibUSB installed using,  
  - `sudo apt-get install libusb-1.0-0-dev libi2c-dev i2c-tools`
2. Add a udev rule to allow non-root users access to USB and I2c
  - `sudo nano /etc/udev/rules.d/99-ancortek.rules`
  - Insert the following:
```
# Allow non-root users access to Ancortek's SDR Kit
SUBSYSTEM=="usb", ATTR{idVendor}=="04b4", ATTR{idProduct}=="8613", GROUP="sudo"
# Allow non-root users access to the I2C bus
ACTION=="add", KERNEL=="i2c-[0-1]*", MODE="0666" GROUP="sudo"
```
3. Restart the udev service  
 - `sudo udevadm control --reload-rules`  
 - `sudo udevadm trigger`  
4. Blacklist usbtest module (claims the interface)
 - `sudo sh -c "echo 'blacklist usbtest' >> /etc/modprobe.d/blacklist.conf"`