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

I have made the GameBoy module hardware unspecific, meaning that you can simply write your own top-level file and instantiate the GameBoy module in it without changing its inner logic. Some IO's are debug ports which can be ignored, see my top-level file for reference.

I used two wizard generated Xlinix IP cores in this project, one is the main PLL (module name: pll), another is the 8KB RAM for WRAM and VRAM (module name: blockram8192). The first one is in the top-level file, and it not required by the GameBoy itself.

I think the PLL only works with Virtex-5 and some earilier devices, if you are using a 6-series board, use clock wizard instead. If your board does not have PLL... Please try to provide a 4194304 Hz clock for the Game Boy to work. Video Generation and Sound Generation are all based on this single 4MHz clock, but you probably also need additional clocks for audio codecs and VGA/DVI/HDMI transmitters to work. 

Some memories are implemented using reg array, they should work fine with other boards, and they can probably be synthesized into BlockRAMs. Boot ROM is also implemented using reg array, but I used loadmemh to preload the ROM image file, if it is not supported by your synthesizer, you need to modify that.

The audio output is a 20bit number, and the MSB is unused purposely to avoid the problem of the sign. (Audio DACs may use signed number while general purpose DACs usually use unsigned number). The output of the audio should be decoupled with a capacitor as the original GameBoy does.

(To be finished)
