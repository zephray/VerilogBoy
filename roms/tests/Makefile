RGBASM:= rgbasm
RGBLINK:= rgblink
RGBFIX:= rgbfix
WINE:= wine
DMGEMU:= dmg_emu.exe
VBSIM:= ../../sim/verilator/vb_sim
SRCS = $(wildcard *.s)
ROMS = $(SRCS:.s=.gb)
EXPECTS = $(SRCS:.s=.expected)
ACTUALS = $(SRCS:.s=.actual)

all: $(ROMS) $(EXPECTS) $(ACTUALS)

%.actual: %.gb
	$(VBSIM) $< --testmode

%.expected: %.gb
	$(WINE) $(DMGEMU)  $@ $<

%.gb: %.obj
	$(RGBLINK) -o$@ $<
	$(RGBFIX) -v -p 00 $@

%.obj: %.s
	$(RGBASM) -o$@ $<


.PHONY: clean
clean:
	rm -f *.obj *.gb *.expected *.actual
