VerilogBoy
==========

Coding for fun - the hard way. Trying to implement a Game Boy® compatible machine with Verilog. It was my course final project for CMPEN275 (Digital Design Laboratory) at PSU. Now I am refining it and trying to build a physical game console around it. I am trying to keep it well commented and documented. 

## Goals of the project

This project aims to recreate the whole Game Boy gaming system on an FPGA development board, with the ability to play commercial game like The Legend of Zelda with no major glitches.

To be specific, it should be able to run the unmodified Game Boy machine code, produce gray-scale graphics and output to an external monitor, produce the sound and output to the 3.5mm jack on the FPGA board, and accept user input to control the game. Other functionalities like serial communication and IR communication are currently not part of this project.

## System Architecture

The main system architecture is designed as follows (outdated):

![Architecture](https://cdn.hackaday.io/images/6958041523363605244.jpg)

There are three major parts needs to be implemented: the Game Boy CPU (8-bit CISC Processor, Intel 8080 like), the PPU (Pixel Processing Unit), and the sound unit. Several interfacing modules are needed to support the IO capability provided by the specific hardware (FPGA development board or "VerilogBoy Handheld")

## Hardware

Currently targeting on Xilinx ML505/XUPV5 and Terasic DE10-Lite. I am also building an FPGA-based handheld gaming console, called "VerilogBoy Handheld". All design sources of VerilogBoy Handheld is also hosted in this repository.

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

### VerilogBoy Handheld (vbh)

 - FPGA: Xilinx Spartan-6 XC6SLX16
 - RAM: Using on-board PSRAM for VRAM/WRAM
 - ROM: Using on-board PSRAM for game cartridge emulation
 - Video output: 1.54" MIPI-DSI 320x320 IPS TFT-LCD
 - Audio output: On-board I2S codec (WM8960)

## Progress

Refactoring in progress. Previous version could run *The Legend of Zelda: Link's Awakening* and *Pokemon Yellow* with no noticable glitch. See 'master' branch for previous version, at least for now.

GameBoy Related:
 - [ ] CPU <- Refactor in progress

VerilogBoy Handheld Target:
 - [ ] MIPI-DSI LCD
 - [ ] SDIO Interface
 - [ ] WM8960 Codec
 - [ ] Joystick

## Accuracy

This project is NOT built to be cycle exact accurate. I did run some test on previous version, see the old readme.

## How to use

See INSTALL.md

## Acknowledge

This project reused codes from several other projects. A great thanks to their efforts!

 - https://github.com/nightslide7/Gameboy
 - https://github.com/MParygin/v.vga.font8x16

These projects are used as references. Again, thanks for sharing.

 - https://github.com/freecores/genesys_ddr2
 - https://github.com/Gekkio/mooneye-gb
 - https://github.com/ZipCPU/s6soc

## Legalese

I'm not affiliated with Nintendo in any way. Game Boy® is a registered trademark by Nintendo. Nintendo® is a registered trademark. All other trademarks are property of their respective owner.

## License

The Game Boy® boot ROM code is copyrighted material and intellectual properity of Nintendo®. It is provided solely for educational purpose only.

All other software codes are licensed under GNU GPL 3.0.

All other HDL codes are licensed under OHDL 1.0.

All other text documents are licensed under CC BY-SA 4.0
