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

all: bootrom.mif $(ROMS) $(EXPECTS) $(ACTUALS) result

%.actual: %.gb
	$(VBSIM) $< --testmode

%.expected: %.gb
	$(WINE) $(DMGEMU)  $@ $<

%.gb: %.obj
	$(RGBLINK) -o$@ $<
	$(RGBFIX) -v -p 00 $@

%.obj: %.s
	$(RGBASM) -o$@ $<

bootrom.mif:
	cp ../bootrom.mif .

result:
	./compare.sh

.PHONY: clean
clean:
	rm -f *.obj *.gb *.expected *.actual *.mif
