################################################################################
## Filename: Makefile
## Engineer: Wenting Zhang
##
## Project: VerilogBoy
## Description:
##   The makefile build the verilator simulation of the VerilogBoy.
################################################################################

CXX	:= g++
OBJDIR  := obj_pc
RTLD	:= ../rtl
ifeq ($(VERILATOR_ROOT),)
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
endif
VROOT   := $(VERILATOR_ROOT)
GFXFLAGS:= `pkg-config sdl2 --cflags`
GFXLIBS := `pkg-config sdl2 --cflags --libs`
FLAGS	:= -Wall -Og -g -faligned-new
VINCD   := $(VROOT)/include
INCS	:= -I$(RTLD)/obj_dir/ -I$(RTLD) -I$(VINCD) -I$(VINCD)/vltstd
OBJS    := memsim.o cpusim.o cpubus.o cpucore.o
VOBJDR	:= $(RTLD)/obj_dir
VOBJS   := $(OBJDIR)/verilated.o $(OBJDIR)/verilated_vcd_c.o
PROGRAMS := vb_sim
all:	$(PROGRAMS)

%.o: $(OBJDIR)/%.o
$(OBJDIR)/%.o: %.cpp
	$(mk-objdir)
	$(CXX) $(FLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/%.o: $(VINCD)/%.cpp
	$(mk-objdir)
	$(CXX) $(FLAGS) $(INCS) -c $< -o $@

vb_sim: $(OBJDIR)/busmaster_tb.o $(OBJS)
vb_sim: $(VOBJS) $(VOBJDR)/Vbusmaster__ALL.a
	$(CXX) $(GFXLIBS) $(INCS) $^ $(VOBJDR)/Vbusmaster__ALL.a $(GFXLIBS) -lelf -o $@

define	mk-objdir
	@bash -c "if [ ! -e $(OBJDIR) ]; then mkdir -p $(OBJDIR); fi"
endef

.PHONY: clean
clean:
	rm -f *.vcd
	rm -rf $(OBJDIR)/
	rm -f $(PROGRAMS)

