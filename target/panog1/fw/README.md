Firmware for Pano Logic G1
==========================

# How to use

Type '''make''' to build the firmware. Depending on the type, it may either generate a .bin file (to be flashed into SPI Flash) or some .mif file (to be loaded into Block RAM). For the .bin file, generate and flash the .mcs image use iMPACT. For the .mif file, copy over to ../fpga and rebuild the FPGA project.

# What's here

 - bootloader: Initialize the LPDDR, do a simple memory check, and copy the content from SPI Flash into LPDDR then jump to the LPDDR.
 - dhrystone: Dhrystone test, to be executed inside LPDDR. (Or withsome modification, inside BlockRAM). Typical performance inside LPDDR: 0.25 DMIPS/MHz.
 - firmware: Main firmware to be used in the project.

Generally you want to use the bootloader and the firmware.
