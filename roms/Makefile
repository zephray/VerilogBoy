objs := dsi.o main.o
roms := bootrom.gb

.PHONY: all clean

all: $(roms)

clean:
	rm -f $(roms) $(objs)

%.asm: ;

%.o:
	rgbasm -o $@ $*.asm

%.gb: $(objs)
	rgblink -o $@ $(objs)