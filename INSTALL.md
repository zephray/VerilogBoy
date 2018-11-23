INSTALL
=======

# Environment

All targets can be built in Linux. I am using Arch Linux. It is possible to build some or all targets in Windows, but not tested.

# Dependencies

You need these things installed prior to the building process:

* gcc, make, etc.
* arm-none-eabi-gcc arm-none-eabi-newlib
* verilator
* rgbds
* openocd (If you would like to flash MCU image over JTAG)

# Build the test or simulator to be run on a PC

## Build

run '''make'''

# Build binaries for VerilogBoy hardware

## FPGA

## MCU

To build the firmware, run '''make vb_mcu'''
