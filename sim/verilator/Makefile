################################################################################
## Filename: Makefile
## Engineer: Wenting Zhang
##
## Project: VerilogBoy
## Description:
##   The makefile build the verilator simulation of the VerilogBoy.
################################################################################

all: vb_sim

CXX      := g++
CFLAGS   := -Wall -Og -g
OBJDIR   := obj_dir
TOOLS    := ../../tools
RTLD     := ../../rtl
RTLOBJD  := $(RTLD)/obj_dir
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
VROOT    := $(VERILATOR_ROOT)
VINCS    := -I$(VROOT)/include -I$(VROOT)/include/vltstd
INCS     := -I$(RTLOBJD) -I$(RTLD) -I$(VROOT)/include -I$(TOOLS) $(VINCS)
SOURCES  := vb_sim.cpp
VLSRCS   := verilated.cpp verilated_vcd_c.cpp
VLOBJS   := $(OBJDIR)/verilated.o $(OBJDIR)/verilated_vcd_c.o
VLIB     := $(addprefix $(VROOT)/include/,$(VLSRCS))
RAWLIB   := $(RTLOBJD)/Vgameboy__ALL.a
OBJECTS  := $(addprefix $(OBJDIR)/,$(subst .cpp,.o,$(SOURCES) $(VLSRCS)))
LIBS     := $(RAWLIB)


$(OBJDIR)/%.o: %.cpp $(OBJDIR)/
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/%.o: $(VROOT)/include/%.cpp $(OBJDIR)/
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

vb_sim: $(OBJECTS)
	$(CXX) $(CFLAGS) $(INCS) $(OBJECTS) $(LIBS) -o $@

$(OBJDIR)/:
	@bash -c "if [ ! -e $(OBJDIR) ]; then mkdir -p $(OBJDIR)/; fi"

.PHONY: clean
clean:
	rm -rf $(OBJDIR)/
	rm -f ./vb_sim
	
