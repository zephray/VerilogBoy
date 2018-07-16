INSTALL
=======

# Build the test or simulator to be run on a PC

## Environment

If you would like to run the Verilator test and/or simulation, a Unix-like
environment is required. I am using Ubuntu 16.04 LTS.

## Dependencies

You need these things installed prior to the building process:

* gcc, make, etc.
* verilator
* rgbds

## Build

run '''make'''

# Build the bitstream to be run on an FPGA

## Environment

If you would like to run it on the FPGA board, depeding on the specific board,
Xilinx ISE or Intel Quartus would be required to synthesis and generate the
bitstream.

## Dependencies 

Since there are several init files for BlockRAM need to be generated for the
build, you do need a working C compiling and GBASM assembling environment.
Specifically, you need to have gcc, make, and rgbds installed.

## Build

To be added.

