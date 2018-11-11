################################################################################
## Filename: Makefile
## Engineer: Wenting Zhang
##
## Project: VerilogBoy
## Description:
##   Makefile for building the VerilogBoy with Verilator. 
##   Use Xilinx ISE or Quartus for FPGA build.
################################################################################

all: gameboy

VOBJ := obj_dir
CXX   := g++
FBDIR := .

.PHONY: all
gameboy: $(VOBJ)/Vgameboy__ALL.a

SUBMAKE := $(MAKE) --no-print-directory --directory=$(VOBJ) -f
ifeq ($(VERILATOR_ROOT),)
VERILATOR := verilator
else
VERILATOR := $(VERILATOR_ROOT)/bin/verilator
endif
VFLAGS := -Wall -MMD --trace -cc 

SRC := gameboy.v cpu.v 

$(VOBJ)/Vgameboy__ALL.a: $(VOBJ)/Vgameboy.cpp $(VOBJ)/Vgameboy.h
$(VOBJ)/Vgameboy__ALL.a: $(VOBJ)/Vgameboy.mk
$(VOBJ)/Vgameboy.h $(VOBJ)/Vgameboy.cpp $(VOBJ)/Vgameboy.mk: $(SRC)

$(VOBJ)/V%.cpp $(VOBJ)/V%.h $(VOBJ)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v

$(VOBJ)/V%.cpp: $(VOBJ)/V%.h
$(VOBJ)/V%.mk:  $(VOBJ)/V%.h
$(VOBJ)/V%.h: $(FBDIR)/%.v

$(VOBJ)/V%__ALL.a: $(VOBJ)/V%.mk
	$(SUBMAKE) V$*.mk

.PHONY: clean
clean:
	rm -rf $(VOBJ)/*.mk
	rm -rf $(VOBJ)/*.cpp
	rm -rf $(VOBJ)/*.h
	rm -rf $(VOBJ)/
