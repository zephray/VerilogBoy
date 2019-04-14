VerilogBoy
==========

Coding for fun - the hard way. Trying to implement a Game Boy® compatible machine with Verilog.

This project consists of two parts:

 - An open source Game Boy® compatible console Verilog RTL implementation (the *VerilogBoy Core*)
 - An open source FPGA-based handheld game console hardware (the *VerilogBoy Handheld*, or *vbh* for short.)

Both are hosted in this repository.

# VerilogBoy Core

## System Architecture

The main system architecture is designed as follows (outdated):

![Architecture](https://cdn.hackaday.io/images/6958041523363605244.jpg)

There are three major parts needs to be implemented: the Game Boy CPU (8-bit CISC Processor called SM83, Intel 8080 like), the PPU (Pixel Processing Unit), and the sound unit (sometimes referred as a PSG, Programmable Sound Generator). Several interfacing modules are needed to support the IO capability provided by the specific hardware (FPGA development board or "VerilogBoy Handheld").

## Targets (Ports)

Current Pano Logic G1 is the only supported platform. ML505 and VBH support are planned. 

## Progress

Refactoring in progress. Current version could run several commerical games with no noticable glitch on the Pano Logic G1 device. 'Master' branch contains the previous version that runs on the ML505.

 - [x] SM83 CPU (Refactoring stage 1 done, passes all Blargg's tests)
 - [x] PPU (Pixel Processing Unit, Pixel-FIFO architecture)
 - [x] OAMDMA (Object Attribute Memory DMA)
 - [x] PSG (Programmable Sound Generator)
 - [x] Timer
 - [x] Link (Dummy link module, allows some games to run in single player mode)

Next step would be improving the accuracy.

Photo of VerilogBoy on Pano G1 running open source GameBoy game [Tobu Tobu Girl](http://tangramgames.dk/tobutobugirl/):

![Running-on-PanoG1](https://github.com/zephray/VerilogBoy/raw/refactor/doc/.png)

For progress regarding different ports, view README.md under the specific target folder.

## Accuracy

This project is not built to be entirely accurate, but built with accuracy in mind. Most of the CPU timing should follow the original DMG-CPU, and implement a rudimentary 2-stage pipelining just as the original one does.

## Directory Structure

Note: things that will be removed in the near future may not shown here. Not all source files are shown here.

```
.
├── doc                          -- Documents
│   ├── control_unit.ods           -- CPU control unit LUT
│   ├── cpu_internal.md            -- CPU internal signal encoding
│   └── cpu.md                     -- CPU design note
├── hardware                     -- Hardware source files for VBH
│   └── 3d_models                  -- 3D Model in SolidWorks
├── LICENSE                        -- OHDL for VerilogBoy Core
├── Makefile                     -- Toplevel Makefile
├── README.md                    -- This document
├── roms                         -- Place for platform independent ROMs
│   ├── bootrom.s                  -- VBC Boot ROM
│   ├── Makefile                   -- Makefile for building the Boot ROM
│   └── tests                      -- Unit tests
│       ├── compare.sh               -- Script for comparing results between VBC and emulator
│       ├── dmg_emu.exe              -- Reference emulator
│       └── Makefile                 -- Makefile for running tests
├── rtl                          -- VBC RTL files
│   ├── alu.v                      -- ALU
│   ├── boy.v                      -- VerilogBoy portable top level file
│   ├── brom.v                     -- Boot ROM
│   ├── common.v                   -- Common definitions
│   ├── control.v                  -- Control Unit
│   ├── cpu.v                      -- CPU top level
│   ├── dma.v                      -- OAM DMA
│   ├── Makefile                   -- Makefile for building the VBC using Verilator
│   ├── mbc5.v                     -- Cartridge paging, optional
│   ├── ppu.v                      -- Pixel Processing Unit
│   ├── regfile.v                  -- CPU Register file
│   ├── singleport_ram.v           -- Singleport RAM template
│   ├── singlereg.v                -- Singlebit register template
│   └── timer.v                    -- Timer
├── sim                          -- Simualtion
│   └── verilator                  -- Verilator-based simulator 
│       ├── dispsim.cpp              -- LCD simulator based on SDL 2.0
│       ├── Makefile                 -- Makefile for building the simulator
│       ├── memsim.cpp               -- Boot ROM or Game ROM simulator
│       ├── mmrprobe.cpp             -- Unit for dumping memory or MMR accesses
│       └── vb_sim.cpp               -- Simulator main file
├── target                       -- Targets (ports) of VBC
│   ├── panog1                     -- Pano Logic G1 devices
│   │   ├── fpga                     -- FPGA RTL
│   │   │   ├── dualport_ram.v         -- Template of dual port RAM
│   │   │   ├── idt_clkgen.v           -- Code for interfacing with clock generator
│   │   │   ├── mig                    -- LPDDR memory controller
│   │   │   ├── mig_picorv_bridge.v    -- Bridge for connecting PicoRV32 and LPDDR controller
│   │   │   ├── mig.ucf                -- Timing constraint for memory controller
│   │   │   ├── mobile_ddr.v           -- Simulation model for LPDDR
│   │   │   ├── panog1.xise            -- ISE project file
│   │   │   ├── pano_top.v             -- Top level HDL
│   │   │   ├── pano.ucf               -- Main pin location constraint
│   │   │   ├── picorv32.v             -- PicoRV32 RISC-V softcore
│   │   │   ├── picosoc_mem.v          -- PicoRV32 scratchpad memory
│   │   │   ├── simple_uart.v          -- Simple UART transmitter 
│   │   │   ├── testbench.v            -- Testbench with LPDDR model
│   │   │   ├── usb_picorv_bridge.v    -- Bridge for connecting PicoRV32 and USB controller
│   │   │   ├── vga_font.v             -- VGA font ROM
│   │   │   ├── vga_mixer.v            -- Mixing PicoRV32 and VerilogBoy image
│   │   │   └── vga_timing.v           -- VGA timing generator
│   │   ├── fw                       -- Firmware for RV softcore
│   │   │   ├── bootloader             -- Bootloader for loading firmware from SPI Flash
│   │   │   │   ├── bootloader.c         -- Main source code
│   │   │   │   ├── Makefile             -- Makefile for building the bootloader
│   │   │   │   ├── sections_bl.lds      -- Link script
│   │   │   │   └── start_bl.s           -- Startup code
│   │   │   ├── dhrystone              -- Dhrystone test for RV softcore
│   │   │   ├── firmware               -- Firmware for softcore
│   │   │   │   ├── COPYING              -- GPLv2 License for firmware
│   │   │   │   ├── firmware.c           -- Main source code 
│   │   │   │   ├── isp1760.c            -- ISP1760 HCD
│   │   │   │   ├── isp_roothub.h        -- RootHub emulation for HCD (optional)
│   │   │   │   ├── Makefile             -- Makefile for building the firmware
│   │   │   │   ├── misc.c               -- Delay and other common routines
│   │   │   │   ├── sections.lds         -- Link script
│   │   │   │   ├── syscalls.c           -- Syscalls for the newlib
│   │   │   │   ├── term.c               -- Simple virtual terminal
│   │   │   │   ├── usb.c                -- Host USB stack
│   │   │   │   ├── usb_gamepad.c        -- Generic USB HIB gamepad driver
│   │   │   │   └── usb_storage.c        -- USB mass storage driver
│   │   │   └── README.md              -- README about firmware
│   │   └── README.md                -- README about Pano Logic G1 port
│   └── vbh                        -- VerilogBoy Handheld
│       ├── fpga                     -- FPGA RTL
│       └── fw                       -- Firmware for on-board MCU
└── tools                        -- Tools for building things
    ├── bin2mif                    -- Convert binary blob to mif
    └── vga_timing.xlsx            -- Tool for calculating VGA timing
```

## How to use

### Verilator-based simulator

Tested environment: Ubuntu 18.04.2 LTS. 

Dependencies: build-essential, verilator, libsdl2-dev, libelf-dev, wine(for unit test only, for now), rgbds(not available from apt, need build manually)

#### Build

At project directory:
```
make rtl
make sim
```

#### Running unit-tests

At project directory:
```
cd roms/tests
make
./compare.sh
```

#### Running ROMs

At project directory:
```
./sim/verilator/vb_sim <path_to_your_rom.gb> --nostop
```

Few parameters:
```
--nostop: Don't stop execution at halt/stop (but stop at illegal instructions)
--trace: Generate vcd waveform trace
--testmode: Disable internal Boot ROM, headless mode, limit cycles to 32K.
--noboot: Disable internal Boot ROM, code execution starts at 0x0000 rather than 0x0100.
--verbose: Enable debug output
```

### FPGA targets

See README inside target directory.

# VerilogBoy Handheld

VerilogBoy Handheld is an open source FPGA-based handheld game console. All design sources of the VerilogBoy Handheld are hosted in this repository.

![Hardware-Architecture](https://github.com/zephray/VerilogBoy/raw/refactor/doc/hardware_arch.png)

Note: the architecture is subject to change.

 - FPGA: Xilinx® Spartan®-6 XC6SLX16
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
