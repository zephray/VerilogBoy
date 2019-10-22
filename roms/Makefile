BIN2MIF:= ../tools/bin2mif
RGBASM:= rgbasm
RGBLINK:= rgblink

all: bootrom.mif tests

bootrom.mif: bootrom.gb
	$(BIN2MIF) bootrom.gb bootrom.mif 256 8

bootrom.gb: bootrom.obj
	$(RGBLINK) -mbootrom.map -nbootrom.sym -obootrom.gb bootrom.obj

bootrom.obj: bootrom.s
	$(RGBASM) -obootrom.obj bootrom.s

.PHONY: tests
	cd tests; $(MAKE) --no-print-directory

.PHONY: clean
clean:
	rm -f *.obj *.map *.sym *.gb *.mif
