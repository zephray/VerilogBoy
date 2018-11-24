################################################################################
## Filename: Makefile
## Engineer: Wenting Zhang
##
## Project: VerilogBoy
## Description:
##   Top level Makefile.
################################################################################

all: rtl sim

.PHONY: doc
doc:
	cd doc; $(MAKE) --no-print-directory
	
.PHONY: rtl
rtl:
	cd rtl; $(MAKE) --no-print-directory
	
.PHONY: sim
sim: rtl
	cd sim/verilator; $(MAKE) --no-print-directory
	
.PHONY: vbh_mcu
vbh_mcu:
	cd target/vbh/mcu/src; $(MAKE) --no-print-directory

.PHONY: clean
clean:
	cd doc; $(MAKE) --no-print-directory clean
	cd rtl; $(MAKE) --no-print-directory clean
	cd sim/verilator; $(MAKE) --no-print-directory clean
