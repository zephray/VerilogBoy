################################################################################
## Filename: Makefile
## Engineer: Wenting Zhang
##
## Project: VerilogBoy
## Description:
##   Makefile for building the VerilogBoy with Verilator. 
##   Use Xilinx ISE or Quartus for FPGA build.
################################################################################

all: boy

VOBJ := obj_dir
CXX   := g++
FBDIR := .

.PHONY: all
boy: $(VOBJ)/Vboy__ALL.a

SUBMAKE := $(MAKE) --no-print-directory --directory=$(VOBJ) -f
ifeq ($(VERILATOR_ROOT),)
VERILATOR := verilator
else
VERILATOR := $(VERILATOR_ROOT)/bin/verilator
endif
VFLAGS := -Wall -Wno-fatal -MMD --trace -cc 

SRC := alu.v boy.v brom.v clk_div.v cpu.v control.v dma.v ppu.v regfile.v serial.v \
	singlereg.v singleport_ram.v sound.v sound_channel_mix.v sound_length_ctr.v\
	sound_noise.v sound_square.v sound_vol_env.v sound_wave.v timer.v

$(VOBJ)/Vboy__ALL.a: $(VOBJ)/Vboy.cpp $(VOBJ)/Vboy.h
$(VOBJ)/Vboy__ALL.a: $(VOBJ)/Vboy.mk
$(VOBJ)/Vboy.h $(VOBJ)/Vboy.cpp $(VOBJ)/Vboy.mk: $(SRC)

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
