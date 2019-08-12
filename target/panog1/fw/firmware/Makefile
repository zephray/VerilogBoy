OBJS = start.o firmware.o stdlib.o term.o isp1760.o i2c.o misc.o ff.o ffsystem.o diskio.o wm8750.o usb.o usb_gamepad.o usb_storage.o
CFLAGS = -MD -O1 -march=rv32ic -ffreestanding -nostdlib -Wl,--no-relax
TOOLCHAIN_PREFIX = riscv32-unknown-elf-
BIN2MIF:= ../../../../tools/bin2mif/bin2mif
XC3SPROG := xc3sprog
XC3SPROG_OPTS := -c jtaghs2 -v

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

prog: firmware.bin
	$(XC3SPROG) $(XC3SPROG_OPTS) -I../../fpga/xc3sprog/pano_g1.bit firmware.bin:W:786432:BIN
	$(XC3SPROG) $(XC3SPROG_OPTS) ../../fpga/pano_top.bit


clean:
	rm -rf *.o *.d *.elf *.bin *.map

.PHONY: clean

-include *.d

