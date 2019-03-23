VerilogBoy
==========

Coding for fun - the hard way. Trying to implement a Game Boy® compatible machine with Verilog.

This project consists of two parts:

 - An open source Game Boy® compatible console Verilog RTL implementation (the *VerilogBoy*)
 - An open source FPGA-based handheld game console hardware (the *VerilogBoy Handheld*, or *vbh* for short.)

Both are hosted in this repository.

# VerilogBoy

## System Architecture

The main system architecture is designed as follows (outdated):

![Architecture](https://cdn.hackaday.io/images/6958041523363605244.jpg)

There are three major parts needs to be implemented: the Game Boy CPU (8-bit CISC Processor called SM83, Intel 8080 like), the PPU (Pixel Processing Unit), and the sound unit. Several interfacing modules are needed to support the IO capability provided by the specific hardware (FPGA development board or "VerilogBoy Handheld").

## Targets

Several targets are supported by this project. See target folder for details.

## Progress

![Running-on-ML505](https://cdn.hackaday.io/images/8583531548721704232.jpg)

Refactoring in progress. Previous version could run *The Legend of Zelda: Link's Awakening* and *Pokemon Yellow* with no noticable glitch on the Xilinx ML505 board (as shown in the photo). See 'master' branch for previous version, at least for now.

VerilogBoy core:
 - [ ] SM83 CPU <- Refactor in progress

For progress regarding different ports, view README.md under the specific target folder.

## Accuracy

This project is not built to be entirely accurate, but built with accuracy in mind. Most of the CPU timing should follow the original DMG-CPU, and implement a rudimentary 2-stage pipelining just as the original one does.

## How to use

See INSTALL.md

# VerilogBoy Handheld

VerilogBoy Handheld is an open source FPGA-based handheld game console. All design sources of the VerilogBoy Handheld are hosted in this repository.

![Hardware-Architecture](https://github.com/zephray/VerilogBoy/raw/refactor/doc/hardware_arch.png)

 - FPGA: Xilinx Spartan-6 XC6SLX16
 - RAM: Using on-board PSRAM for VRAM/WRAM
 - ROM: Using on-board PSRAM for game cartridge emulation
 - Video output: 1.54" MIPI-DSI 320x320 IPS TFT-LCD
 - Audio output: On-board I2S codec (WM8960)

# Acknowledge

This project reused codes from several other projects. A great thanks to their efforts!

 - https://github.com/nightslide7/Gameboy
 - https://github.com/cliffordwolf/picorv32
 - https://github.com/u-boot/u-boot
 - https://github.com/twlostow/dsi-shield
 - https://github.com/MParygin/v.vga.font8x16

These projects are used as references. Again, thanks for sharing.

 - https://github.com/freecores/genesys_ddr2
 - https://github.com/ZipCPU/s6soc

These are extremely helpful resources about the Game Boy® itself:

 - https://github.com/Gekkio/mooneye-gb
 - https://github.com/Gekkio/gb-ctr

# Legalese

I'm not affiliated with Nintendo in any way. Game Boy® is a registered trademark by Nintendo. Nintendo® is a registered trademark. All other trademarks are property of their respective owner.

# License

The dsicore is made by twlostow, released under LGPL 3.0.

The PicoRV32 is free and open hardware licensed under the [ISC license](http://en.wikipedia.org/wiki/ISC_license)
(a license that is similar in terms to the MIT license or the 2-clause BSD license).

Some firmware code of pano-g1 target are released to public domain.

All other software codes are licensed under GNU GPL 2.0.

All other HDL codes are licensed under OHDL 1.0.

All other text documents are licensed under CC BY-SA 4.0
