GameBoy
=======

Coding for fun - the hard way. Trying to implement a Game Boy® compatible machine with Verilog. This is my course final project for CMPEN275 (Digital Design Laboratory) at PSU. I am trying to keep it well commented and documented. 

## Goals of the project

This project aims to recreate the whole Game Boy gaming system on an FPGA development board, with the ability to play commercial game like The Legend of Zelda with no major glitches.

To be specific, it should be able to run the unmodified Game Boy machine code, produce gray-scale graphics and output to an external monitor, produce the sound and output to the 3.5mm jack on the FPGA board, and accept user input to control the game. Other functionalities like serial communication and IR communication are currently not part of this project.

## System Architecture

The main system architecture is designed as follows:

![Architecture](https://cdn.hackaday.io/images/6958041523363605244.jpg)

There are three major parts needs to be implemented: the Game Boy CPU (8-bit CISC Processor, Intel 8080 like), the PPU (or GPU), the Sound unit. Several interfacing modules are needed to support the IO capability provided by the FPGA development board. Game ROM would be stored in on-board NOR flash, and RAM would be implemented with on-chip Block RAM.

## Hardware

Currently targeting on Xilinx ML505/XUPV5 and Terasic DE10-Lite.

## Progress

Refactoring in progress. Previous version could run *The Legend of Zelda: Link's Awakening* and *Pokemon Yellow* with no noticable glitch. See 'master' branch for previous version, at least for now.

GameBoy Related:
 - [ ] CPU <- Refactor in progress
 - [x] PPU
 - [ ] Sound
 - [x] Timer
 - [x] Link
 - [x] Keypad

Board Related:
 - [x] DVI Interface
 - [x] AC'97 Interface
 - [x] Cartridge (Emulated with FlashROM)
 - [x] Controller Interface

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

## Legalese

I'm not affiliated with Nintendo in any way. Game Boy® is a registered trademark by Nintendo. Nintendo® is a registered trademark. All other trademarks are property of their respective owner.

## License

The Game Boy® boot ROM code is copyrighted material and intellectual properity of Nintendo®. It is provided solely for educational purpose only.

The GB-Z80 cpu code (cpu.v, cpu.vh, alu.v, and regfile.v) is originally written by Joseph Carlos, and according to his requirement, this files should only be used for non-commercial purpose.

All other software codes are licensed under MPL 2.0.

All other HDL codes are licensed under OHDL 1.0.

All other text documents are licensed under CC BY-SA 4.0
