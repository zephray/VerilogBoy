OBJS = start.o firmware.o stdlib.o term.o i2c.o misc.o axp.o dsi.o
CFLAGS = -MD -O1 -march=rv32ic -ffreestanding -nostdlib -Wl,--no-relax
TOOLCHAIN_PREFIX = riscv32-unknown-elf-
BIN2MIF:= ../../../../tools/bin2mif/bin2mif

all: firmware.bin firmware.asm firmware.mif

firmware.bin: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@

firmware.asm: firmware.elf
	$(TOOLCHAIN_PREFIX)objdump -d $< > $@

firmware.mif: firmware.bin
	dd if=/dev/zero of=flash.bin bs=1k count=768
	cat firmware.bin >> flash.bin
	$(BIN2MIF) flash.bin firmware.mif 1048576 8
	cp firmware.mif ../../fpga

firmware.elf: $(OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,sections.lds,-Map,firmware.map,--strip-debug -o $@ $(OBJS) -lgcc
	size $@

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

%.o: %.s
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

clean:
	rm -rf *.o *.d *.elf *.bin *.map

.PHONY: clean

-include *.d

