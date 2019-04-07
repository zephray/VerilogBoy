VerilogBoy for Pano Logic G1
============================

## Overview

From https://tomverbeure.github.io/rtl/2018/11/26/Racing-the-Beam-Ray-Tracer.html#the-hw-platform:

> Pano Logic was a Bay Area startup that wanted to get rid of PCs in large organizations by replacing them with tiny CPU-less thin clients that were connected to a central server. Think of them as VNC replacements. No CPU? No software upgrades! No virusses!
> 
> The thin clients had a wired Ethernet interface, a couple of USB ports, an audio port and a video port.
> All this was glued together with an FPGA.
> 
> The company has been defunct since 2013 and the clients are not supported by anything. But they are amazing for hobby purposes and can be bought dirt cheap on eBay.
> 
> There are 2 versions: the first one has a VGA video interface, later versions have a DVI port.
> 
> The VGA version uses the Xilinx Spartan-3E 1600. The DVI version a very powerful Spartan-6 LX150.

This port focus on the VGA version (3E-1600).

## Status

Working in Progress

## Components

### LPDDR controller

Based on Xilinx MIG, LPDDR-200 @ 16-bits.

Details available at hackaday: [A detour to the Pano Logic G1 (1) - LPDDR](https://hackaday.io/project/57660/log/159790-a-detour-to-the-pano-logic-g1-1-lpddr)

Used to be a memory cache between PicoRV32 and LPDDR, now as code is XIP from Flash, cache is move to flash. All access to LPDDR is non cached.

### PicoRV32 soft-processor

PicoRV32 is a RISC-V compatible soft-processor written by Clifford Wolf: https://github.com/cliffordwolf/picorv32.

Configured as RV32IC, running at 25MHz.

Currently, code is XIP from SPI Flash. SPI Flash also runs at 25MHz (Maximum frequency of M25P80 is 75MHz), 1 bit mode. A 4KB 2-way set associative cache is added between the PicoRV32 and SPI IF. Expect very poor performance.

The PicoRV32 uses in total 8 BRAM18K for memories, 4 as scratchpad memory (8KB), 2 as I-cache (4KB), 2 as video RAM (4KB).
