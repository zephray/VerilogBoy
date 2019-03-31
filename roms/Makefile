BIN2MIF:= ../tools/bin2mif/bin2mif
RGBASM:= rgbasm
RGBLINK:= rgblink

all: bootrom.mif

bootrom.mif: bootrom.gb
	$(BIN2MIF) bootrom.gb bootrom.mif 256 8

bootrom.gb: bootrom.obj
	$(RGBLINK) -mbootrom.map -nbootrom.sym -obootrom.gb bootrom.obj

bootrom.obj: bootrom.s
	$(RGBASM) -obootrom.obj bootrom.s

.PHONY: clean
clean:
	rm -f *.obj *.map *.sym *.gb *.mif
