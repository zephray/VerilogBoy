OBJS = firmware.o syscalls.o term.o isp1760.o misc.o usb.o usb_kbd.o usb_gamepad.o
CFLAGS = -MD -O1 -march=rv32i -Wl,--no-relax -fdata-sections -ffunction-sections
TOOLCHAIN_PREFIX = riscv32-unknown-elf-

all: firmware.bin firmware.asm

firmware.bin: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@

firmware.asm: firmware.elf
	$(TOOLCHAIN_PREFIX)objdump -d $< > $@

firmware.elf: $(OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,--gc-sections -Wl,-Bstatic,-T,sections.lds,-Map,firmware.map -o $@ $(OBJS) -lgcc -lc
	size $@

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

clean:
	rm -rf *.o *.d *.elf *.bin *.map

.PHONY: clean

-include *.d

