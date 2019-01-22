obj := dsi.o main.o
rom := bootrom.gb
mif := bootrom.mif

bin2mif := ../tools/bin2mif

.PHONY: all clean

all: $(rom)

mif: $(mif)

clean:
	rm -f $(rom) $(obj)

%.asm: ;

%.o:
	rgbasm -o $@ $*.asm

%.gb: $(obj)
	rgblink -o $@ $(objs)

%.mif: $(rom)
	$(bin2mif) $*.gb $@ 16384
	
