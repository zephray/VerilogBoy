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

# Port it to another board

I used two wizard generated Xlinix IP cores in this project, one is the main PLL (module name: pll), another is the 8KB RAM for WRAM and VRAM (module name: blockram8192). I think the PLL only works with Virtex-5 or earilier devices, if you are using a Spartan-6 board, use clock wizard instead. There are also some IP cores instantiated using Xilinx primitives, be sure to change them if you are porting it to an Altera or other vendor's boards. Some memories are implied using reg array, they should work fine with other boards. Boot ROM is also implied using reg array, but I used loadmemh to preload the ROM image file, if it is not supported by your synthesizer, you need to modify that.

The next thing would be porting the actual design. I have made the GameBoy module hardware unspecific, meaning that you can simply write your own top-level file and instantiate the GameBoy module in it without changing its inner logic. Some IO's are debug ports which can be ignored, see my top-level file for reference.

(To be finished)
