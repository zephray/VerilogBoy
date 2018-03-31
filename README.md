GameBoy
=======

Coding for fun - the hard way. Trying to implement a Game Boy with Verilog. Currently not working yet, and please do not expect it will. I am working on it in my spare time and this is not a school project, there will be no deadline nor formal reports. But I am trying to keep it well commented and documented.

# Hardware

Currently targeting on Xilinx ML505/XUPV5. A custom board is designing in progress with the specifications below:

* FPGA: Anlogic EG4D20 (23.5K 4-input LUTs equivalent)
* MCU: STmicro STM32F207ZET6 (120MHz CortexM3/ 512KB Flash/ 128KB RAM)
* RAM: 1M x 16Bits DDR400 SDRAM
* LCD: Truly 2.2" 220x176 LCD
* Sound: Wolfson WM8960 (16 bits ENOB, support GB AIN function)
* Expansion: microSD card (3.3V HS mode up to 25MB/s)
* Connectivity: USB 2.0 Full Speed
* Catridge: GameBoy compatible cartridge slot
* Power: Xpowers AXP192 PMU

# Progress

Very early stage, BootROM runs and shows Nintendo logo correctly.

GameBoy Related:
 - [x] CPU
 - [x] PPU
 - [ ] Sound
 - [ ] Timer
 - [ ] Link
 - [ ] Keypad?

Board Related:
 - [x] DVI Interface
 - [ ] AC'97 Interface
 - [ ] Cartridge Interface

# Why I am building this

For fun, also trying to learn Verilog.

# How to use

See INSTALL.md

# Acknowledge

This project reused codes from several other projects. A great thanks to their efforts!

 - https://github.com/freecores/genesys_ddr2
 - https://github.com/nightslide7/Gameboy
 - https://github.com/MParygin/v.vga.font8x16

 # License

 GNU GPLv3