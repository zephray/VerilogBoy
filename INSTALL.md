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
* Xilinx ISE 14.7 (to build ml505 target or vbh target)

# Build the test or simulator to be run on a PC

## Build

run '''make'''

# Build binaries for VerilogBoy Handheld

## FPGA

To build the firmware, open fpga.xise under target/vbh/fpga folder with Xilinx ISE 14.7, and double click generate programming file.

## MCU

To build the firmware, run '''make vbh_mcu'''
