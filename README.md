VerilogBoy
==========

Coding for fun - the hard way. Trying to implement a Game Boy® compatible machine with Verilog.

This project is an open source Game Boy® compatible console Verilog RTL implementation.

# System Architecture

The main system architecture is designed as follows (outdated):

![Architecture](https://cdn.hackaday.io/images/6958041523363605244.jpg)

There are three major parts needs to be implemented: the Game Boy CPU (8-bit CISC Processor called SM83, Intel 8080 like), the PPU (Pixel Processing Unit), and the sound unit (sometimes referred as a PSG, Programmable Sound Generator). Several interfacing modules are needed to support the IO capability provided by the hardware (such as an FPGA development board).

# Targets (Ports)

Current Pano Logic G1 is the only supported platform.

# Progress

Refactoring in progress. Current version could run several commerical games with no noticable glitch on the Pano Logic G1 device. 'Master' branch contains the previous version that runs on the ML505.

 - [x] SM83 CPU (Refactoring stage 1 done, passes all Blargg's tests)
 - [x] PPU (Pixel Processing Unit, Pixel-FIFO architecture)
 - [x] OAMDMA (Object Attribute Memory DMA)
 - [x] PSG (Programmable Sound Generator)
 - [x] Timer
 - [x] Link (Dummy link module, allows some games to run in single player mode)

Next step would be improving the accuracy.

Photo of VerilogBoy on Pano G1 running open source GameBoy game [Tobu Tobu Girl](http://tangramgames.dk/tobutobugirl/):

![Running-on-PanoG1](https://github.com/zephray/VerilogBoy/raw/refactor/doc/demo_tobu.jpg)

For progress regarding different ports, view README.md under the specific target folder.

# Accuracy

This project is not built to be entirely accurate, but built with accuracy in mind. Most of the CPU timing should follow the original DMG-CPU, and implement a rudimentary 2-stage pipelining just as the original one does. 

Here are the results of several tests I have tried to run on it.

PPU implementation is ... wrong: There are two pipelines in the GameBoy PPU, one for BG and one for sprite. I only implemented one for both. There is only one fetcher, though.

Note: Tests which depends on the revision / model of GameBoy are omitted. VerilogBoy only focus on behaviors that are common among all monochrome GameBoys (GS).

## Blargg's tests

| Test              | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy |
| ----------------- | ---------- | ---- | -------- | ----- | ---- |------------|
| cpu instrs        | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       |

Notes: other tests hasn't been tried.

## Mooneye GB acceptance tests

| Test                    | mooneye-gb | BGB  | Gambatte | Higan  | MESS | VerilogBoy |
| ----------------------- | ---------- | ---- | -------- | ------ | ---- |------------|
| add sp e timing         | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| call timing             | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| call timing2            | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| call cc_timing          | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| call cc_timing2         | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| di timing GS            | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| div timing              | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| ei sequence             | :+1:       | :+1: | :+1:     | :+1:   | :x:  | :+1:       |
| ei timing               | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| halt ime0 ei            | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| halt ime0 nointr_timing | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| halt ime1 timing        | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| halt ime1 timing2 GS    | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| if ie registers         | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| intr timing             | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| jp timing               | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| jp cc timing            | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| ld hl sp e timing       | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| oam dma_restart         | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| oam dma start           | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| oam dma timing          | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| pop timing              | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| push timing             | :+1:       | :x:  | :x:      | :+1:   | :+1: | :+1:       |
| rapid di ei             | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| ret timing              | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| ret cc timing           | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| reti timing             | :+1:       | :x:  | :+1:     | :+1:   | :+1: | :+1:       |
| reti intr timing        | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| rst timing              | :+1:       | :x:  | :x:      | :+1:   | :+1: | :+1:       |

### Instructions

| Test                        | mooneye-gb | BGB  | Gambatte | Higan  | MESS | VerilogBoy |
| --------------------------- | ---------- | ---- | -------- | ------ | ---- |------------|
| daa                         | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |

### Interrupt handling

| Test                        | mooneye-gb | BGB  | Gambatte | Higan  | MESS | VerilogBoy |
| --------------------------- | ---------- | ---- | -------- | ------ | ---- |------------|
| ie push                     | :+1:       | :x:  | :x:      | :x:    | :x:  | :+1:       |

### OAM DMA

| Test                        | mooneye-gb | BGB  | Gambatte | Higan  | MESS | VerilogBoy |
| --------------------------- | ---------- | ---- | -------- | ------ | ---- |------------|
| basic                       | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| reg_read                    | :+1:       | :+1: | :+1:     | :x:    | :x:  | :+1:       |
| sources dmgABCmgbS          | :+1:       | :+1: | :x:      | :x:    | :x:  | :x:        |

### Serial

| Test                        | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy |
| --------------------------- | ---------- | ---- | -------- | ------| ---- |------------|
| boot sclk align dmgABCmgb   | :x:        | :+1: | :+1:     | :x:   | :x:  | :x:        |

Note: this test only seems to test the time to finish the first transfer. What about the second? (Delta time required to do a transfer and get notified by the interrupt)

### PPU

| Test                        | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy |
| --------------------------- | ---------- | ---- | -------- | ------| ---- |------------|
| hblank ly scx timing GS     | :+1:       | :+1: | :x:      | :x:   | :+1: | :x:        |
| intr 1 2 timing GS          | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :x:        |
| intr 2 0 timing             | :+1:       | :+1: | :x:      | :+1:  | :+1: | :x:        |
| intr 2 mode0 timing         | :+1:       | :+1: | :x:      | :x:   | :+1: | :x:        |
| intr 2 mode3 timing         | :+1:       | :+1: | :x:      | :x:   | :+1: | :x:        |
| intr 2 oam ok timing        | :+1:       | :+1: | :x:      | :x:   | :+1: | :x:        |
| intr 2 mode0 timing sprites | :x:        | :+1: | :x:      | :x:   | :+1: | :x:        |
| lcdon timing dmgABCmgbS     | :x:        | :+1: | :x:      | :x:   | :x:  | :x:        |
| lcdon write timing GS       | :x:        | :+1: | :x:      | :x:   | :x:  | :x:        |
| stat irq blocking           | :x:        | :+1: | :+1:     | :x:   | :+1: | :x:        |
| stat lyc onoff              | :x:        | :+1: | :x:      | :x:   | :x:  | :x:        |
| vblank stat intr GS         | :+1:       | :+1: | :x:      | :+1:  | :+1: | :x:        |

### Timer

| Test                 | mooneye-gb | BGB  | Gambatte | Higan  | MESS | VerilogBoy |
| -------------------- | ---------- | ---- | -------- | ------ | ---- |------------|
| div write            | :+1:       | :+1: | :x:      | :+1:   | :+1: | :+1:       |
| rapid toggle         | :+1:       | :+1: | :x:      | :x:    | :+1: | :+1:       |
| tim00 div trigger    | :+1:       | :+1: | :+1:     | :x:    | :+1: | :+1:       |
| tim00                | :+1:       | :+1: | :x:      | :+1:   | :+1: | :+1:       |
| tim01 div trigger    | :+1:       | :+1: | :x:      | :x:    | :+1: | :+1:       |
| tim01                | :+1:       | :+1: | :+1:     | :+1:   | :+1: | :+1:       |
| tim10 div trigger    | :+1:       | :+1: | :x:      | :x:    | :+1: | :+1:       |
| tim10                | :+1:       | :+1: | :x:      | :+1:   | :+1: | :+1:       |
| tim11 div trigger    | :+1:       | :+1: | :x:      | :x:    | :+1: | :+1:       |
| tim11                | :+1:       | :+1: | :x:      | :+1:   | :+1: | :+1:       |
| tima reload          | :+1:       | :+1: | :x:      | :x:    | :+1: | :+1:       |
| tima write reloading | :+1:       | :+1: | :x:      | :x:    | :+1: | :+1:       |
| tma write reloading  | :+1:       | :+1: | :x:      | :x:    | :+1: | :+1:       |

# Directory Structure

Note: things that will be removed in the near future may not shown here. Not all source files are shown here.

```
.
├── doc                          -- Documents
│   ├── control_unit.ods           -- CPU control unit LUT
│   ├── cpu_internal.md            -- CPU internal signal encoding
│   └── cpu.md                     -- CPU design note
├── LICENSE                      -- OHDL
├── Makefile                     -- Toplevel Makefile
├── README.md                    -- This document
├── roms                         -- Place for platform independent ROMs
│   ├── bootrom.s                  -- Boot ROM
│   ├── Makefile                   -- Makefile for building the Boot ROM
│   └── tests                      -- Unit tests
│       ├── compare.sh               -- Script for comparing results between VBC and emulator
│       ├── dmg_emu.exe              -- Reference emulator
│       └── Makefile                 -- Makefile for running tests
├── rtl                          -- RTL files
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
│       ├── mbcsim.cpp               -- MBC cartridge controller simulator
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

# How to use

## Verilator-based simulator

Tested environment: Ubuntu 20.04 LTS, mac OS Big Sur. 

Dependencies: build-essential, verilator, libsdl2-dev, wine(optional, for unit test only, for now), rgbds(not available from apt, need build manually).

On Debian/ Ubuntu, do the following:

```
sudo apt install build-essential verilator libsdl2-dev wine byacc flex pkg-config libpng-dev
```

On macOS, do the following:

```
brew install verilator sdl2 pkg-config libpng
```

To install rgbds:

```
git clone https://github.com/rednex/rgbds
cd rgbds
make
make install
```

### Build

At project directory:
```
make
```

Copy the bootrom.mif to where it is required. (For example, target/panog1)

### Running unit-tests

At project directory:
```
cd roms/tests
make
./compare.sh
```

### Running ROMs

At project directory:
```
./sim/verilator/vb_sim <path_to_your_rom.gb> --mbc --nostop
```

Few parameters:
```
--nostop: Don't stop execution at halt/stop (but stop at illegal instructions)
--trace: Generate vcd waveform trace
--testmode: Disable internal Boot ROM, headless mode, limit cycles to 32K.
--noboot: Disable internal Boot ROM, code execution starts at 0x0000 rather than 0x0100.
--verbose: Enable debug output
--mbc: Enable MBC1/3/5 emulation for ROMs larger than 32KB
```

## FPGA targets

See README inside target directory.

# Acknowledge

This project reused codes from several other projects. A great thanks to their efforts!

 - [https://github.com/nightslide7/Gameboy](https://github.com/nightslide7/Gameboy)
 - [https://github.com/cliffordwolf/picorv32](https://github.com/cliffordwolf/picorv32)
 - [https://github.com/u-boot/u-boot](https://github.com/u-boot/u-boot)
 - [https://github.com/twlostow/dsi-shield](https://github.com/twlostow/dsi-shield)
 - [https://github.com/MParygin/v.vga.font8x16](https://github.com/MParygin/v.vga.font8x16)

These projects are used as references. Again, thanks for sharing.

 - [https://github.com/freecores/genesys_ddr2](https://github.com/freecores/genesys_ddr2)
 - [https://github.com/ZipCPU/s6soc](https://github.com/ZipCPU/s6soc)

These are extremely helpful resources about the Game Boy® itself:

 - [https://github.com/Gekkio/mooneye-gb](https://github.com/Gekkio/gb-ctr)
 - [https://github.com/Gekkio/gb-ctr](https://github.com/Gekkio/gb-ctr)

Game used for demonstration, thanks for the great game:

 - [https://github.com/SimonLarsen/tobutobugirl](https://github.com/SimonLarsen/tobutobugirl)

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
