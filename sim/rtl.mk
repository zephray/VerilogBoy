TARGET ?= boy
all: $(TARGET)

VOBJ := obj_dir
CXX   := g++
FBDIR := ../rtl
CPUS ?= $(shell bash -c 'nproc --all')
VERBOSE ?= 0

.PHONY: all
$(TARGET): $(VOBJ)/V$(TARGET)__ALL.a

SUBMAKE := $(MAKE) --no-print-directory --directory=$(VOBJ) -f
ifeq ($(VERILATOR_ROOT),)
VERILATOR := verilator
else
VERILATOR := $(VERILATOR_ROOT)/bin/verilator
endif
VFLAGS := -Wall -Wno-fatal -MMD --trace -cc -I../rtl
ifeq ($(VERBOSE), 1)
VFLAGS += +define+VERBOSE=1
endif

$(VOBJ)/V$(TARGET)__ALL.a: $(VOBJ)/V$(TARGET).cpp $(VOBJ)/V$(TARGET).h
$(VOBJ)/V$(TARGET)__ALL.a: $(VOBJ)/V$(TARGET).mk

$(VOBJ)/V%.cpp $(VOBJ)/V%.h $(VOBJ)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v

$(VOBJ)/V%.cpp: $(VOBJ)/V%.h
$(VOBJ)/V%.mk:  $(VOBJ)/V%.h
$(VOBJ)/V%.h: $(FBDIR)/%.v

$(VOBJ)/V%__ALL.a: $(VOBJ)/V%.mk
	$(SUBMAKE) V$*.mk -j$(CPUS)

.PHONY: clean
clean:
	rm -rf $(VOBJ)/*.mk
	rm -rf $(VOBJ)/*.cpp
	rm -rf $(VOBJ)/*.h
	rm -rf $(VOBJ)/
