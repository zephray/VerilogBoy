################################################################################
## Filename: Makefile
## Engineer: Wenting Zhang
##
## Project: VerilogBoy
## Description:
##   Makefile for building the VerilogBoy with Verilator. 
##   Use Xilinx ISE or Quartus for FPGA build.
################################################################################
.PHONY: all
all: gameboy
SRC := gameboy.v cpu.v 
VOBJ := obj_dir

$(VOBJ)/Vgameboy.cpp: $(SRC)
	verilator -trace -cc gameboy.v

$(VOBJ)/Vgameboy.h: $(VOBJ)/Vgameboy.cpp

$(VOBJ)/Vgameboy__ALL.a: $(VOBJ)/Vgameboy.cpp $(VOBJ)/Vgameboy.h
	cd $(VOBJ); make --no-print-directory -f Vgameboy.mk

.PHONY: gameboy
gameboy: $(VOBJ)/Vgameboy__ALL.a

.PHONY: clean
	rm -rf $(VOBJ)
