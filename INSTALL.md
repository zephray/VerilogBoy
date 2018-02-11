INSTALL
=======

# Environment

I developed the FPGA part solely under Windows 7 64bit using Xilinx ISE v14.7. But it should also work with other operating system and ISE combination.

The bin2mif tool is used to convert general bin file to mif file which can be loaded with $loadmenh by XST. I developed it using Visual Studio 2015 but again it should work with other C++ compilers like g++. For convenience I have provided the Windows binary, which should work with a recent version of Windows as well as wine.

The bootstrap in the tool folder is the BROM used in this project. RGBDS is used to assemble and link the assembly file. But it may be modified to work with other assemblers.

# Building the BROM

Use Scripts/build_bootstrap.bat . It should build the BROM and convert it to mif format then copy it to the FPGA firmware folder.

# Building the FPGA firmware

Open GameBoy.xise with ISE, double click Generate Programming File.
