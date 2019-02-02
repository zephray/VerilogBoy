VerilogBoy
==========

Coding for fun - the hard way. Trying to implement a Game Boy® compatible machine with Verilog. It was my course final project for CMPEN275 (Digital Design Laboratory) at PSU. Now I am refining it and trying to build a physical handheld game console around it. I am trying to keep it well commented and documented.

## System Architecture

The main system architecture is designed as follows (outdated):

![Architecture](https://cdn.hackaday.io/images/6958041523363605244.jpg)

There are three major parts needs to be implemented: the Game Boy CPU (8-bit CISC Processor called SM83, Intel 8080 like), the PPU (Pixel Processing Unit), and the sound unit. Several interfacing modules are needed to support the IO capability provided by the specific hardware (FPGA development board or "VerilogBoy Handheld").

## Hardware

The hardware I am building for this is called the "VerilogBoy Handheld". All design sources of the VerilogBoy Handheld is hosted in this repository. Xilinx ML505/XUPV5 and Terasic DE10-Lite port of the VerilogBoy core are also planned. 

### VerilogBoy Handheld (vbh)

![Hardware-Architecture](https://github.com/zephray/VerilogBoy/raw/refactor/doc/hardware_arch.svg)

 - FPGA: Xilinx Spartan-6 XC6SLX16
 - RAM: Using on-board PSRAM for VRAM/WRAM
 - ROM: Using on-board PSRAM for game cartridge emulation
 - Video output: 1.54" MIPI-DSI 320x320 IPS TFT-LCD
 - Audio output: On-board I2S codec (WM8960)

### Xilinx ML505 (ml505)

 - FPGA: Xilinx Virtex-5 XC5VLX50
 - RAM: Using on-chip BlockRAM for VRAM/WRAM
 - ROM: Using on-board FlashROM for game cartridge emulation
 - Video output: On-board VGA or DVI encoder (CH7301C)
 - Audio output: On-board AC'97 codec (AD1981B)

### Terasic DE10-Lite (de10lite)

 - FPGA: Intel MAX10
 - RAM: ?
 - ROM: Using Arduino GameBoy cartridge shield
 - Video output: On-board VGA R2R DAC
 - Audio output: None

## Progress

![Running-on-ML505](https://cdn.hackaday.io/images/8583531548721704232.jpg)

Refactoring in progress. Previous version could run *The Legend of Zelda: Link's Awakening* and *Pokemon Yellow* with no noticable glitch on the Xilinx ML505 board (as shown in the photo). See 'master' branch for previous version, at least for now.

GameBoy Related:
 - [ ] SM83 CPU <- Refactor in progress

VerilogBoy Handheld Target:
 - [ ] MIPI-DSI LCD
 - [ ] SDIO Interface
 - [ ] WM8960 Codec
 - [ ] Joystick

## Accuracy

This project is not built to be entirely accurate, but built with accuracy in mind. Most of the CPU timing should follow the original DMG-CPU, and implement a rudimentary 2-stage pipelining just as the original one does.

## How to use

See INSTALL.md

## Acknowledge

This project reused codes from several other projects. A great thanks to their efforts!

 - https://github.com/nightslide7/Gameboy
 - https://github.com/twlostow/dsi-shield
 - https://github.com/MParygin/v.vga.font8x16

These projects are used as references. Again, thanks for sharing.

 - https://github.com/freecores/genesys_ddr2
 - https://github.com/ZipCPU/s6soc

These are extremely helpful resources about the Game Boy® itself:

 - https://github.com/Gekkio/mooneye-gb
 - https://github.com/Gekkio/gb-ctr

## Legalese

I'm not affiliated with Nintendo in any way. Game Boy® is a registered trademark by Nintendo. Nintendo® is a registered trademark. All other trademarks are property of their respective owner.

## License

The dsicore was made by twlostow, released under LGPL 3.0.

All other software codes are licensed under GNU GPL 3.0.

All other HDL codes are licensed under OHDL 1.0.

All other text documents are licensed under CC BY-SA 4.0
