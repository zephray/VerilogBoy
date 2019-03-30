################################################################################
##
## Filename:  Makefile
##
## Project:	  VerilogBoy
##
################################################################################
##
## Copyright (C) 2019, Wenting Zhang
## Copyright (C) 2015-2017, Gisselquist Technology, LLC
##
## This program is free software (firmware): you can redistribute it and/or
## modify it under the terms of  the GNU General Public License as published
## by the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program.  If not, see <http://www.gnu.org/licenses/> for a copy.
##
################################################################################

CXX	:= g++
OBJDIR  := obj_pc
RTLD	:= ../../rtl
ifeq ($(VERILATOR_ROOT),)
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
endif
VROOT   := $(VERILATOR_ROOT)
GFXFLAGS:= `pkg-config sdl2 --cflags`
GFXLIBS := `pkg-config sdl2 --cflags --libs`
FLAGS	:= -Wall -Og -g -faligned-new
VINCD   := $(VROOT)/include
INCS	:= -I$(RTLD)/obj_dir/ -I$(RTLD) -I$(VINCD) -I$(VINCD)/vltstd
OBJS    := $(OBJDIR)/memsim.o $(OBJDIR)/dispsim.o $(OBJDIR)/mmrprobe.o
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

vb_sim: $(OBJDIR)/vb_sim.o $(OBJS)
vb_sim: $(VOBJS) $(VOBJDR)/Vboy__ALL.a
	$(CXX) $(GFXLIBS) $(INCS) $^ $(VOBJDR)/Vboy__ALL.a $(GFXLIBS) -lelf -o $@

define	mk-objdir
	@bash -c "if [ ! -e $(OBJDIR) ]; then mkdir -p $(OBJDIR); fi"
endef

.PHONY: clean
clean:
	rm -f *.vcd
	rm -rf $(OBJDIR)/
	rm -f $(PROGRAMS)
	rm -f *.o

