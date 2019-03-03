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

Based on Xilinx MIG, LPDDR-200 @ 32-bits.

Details available at hackaday: [A detour to the Pano Logic G1 (1) - LPDDR](https://hackaday.io/project/57660/log/159790-a-detour-to-the-pano-logic-g1-1-lpddr)

### Memory cache

Connected between PicoRV32 and LPDDR controller, 8 KB 2-way set-associative. All transactions are cached, write-back. R/W time is 2 cycles when hit, 4/5 cycles + memory latency when miss. 3 cycle implementation is optional to allow better timing.

Details available at hackaday: [A detour to the Pano Logic G1 (2) - Cache](https://hackaday.io/project/57660/log/160053-a-detour-to-the-pano-logic-g1-2-cache)

### PicoRV32 soft-processor

PicoRV32 is a RISC-V compatible soft-processor written by Clifford Wolf: https://github.com/cliffordwolf/picorv32.

Configured as RV32I, running at 100MHz.

When code is being executed inside LPDDR, the performance is around 0.247 DMIPS/MHz using 2 cycle cache, and 0.208 DMIPS/MHz using 3 cycle cache. 

Currently, a bootloader would copy last 256 KB of the SPI Flash into LPDDR and jump to the LPDDR.
