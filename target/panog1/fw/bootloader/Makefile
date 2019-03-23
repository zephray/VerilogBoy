BIN2MIF:= ../../../../tools/bin2mif/bin2mif

all: picorv_bl.mif

picorv_bl.elf: sections_bl.lds start_bl.s bootloader.c
	riscv32-unknown-elf-gcc -march=rv32i -O1 -Wl,-Bstatic,-T,sections_bl.lds,-Map=picorv_bl.map,--strip-debug -ffreestanding -nostdlib -Wl,--no-relax -o picorv_bl.elf start_bl.s bootloader.c
	size picorv_bl.elf

picorv_bl.bin: picorv_bl.elf
	riscv32-unknown-elf-objcopy -O binary picorv_bl.elf picorv_bl.bin

picorv_bl.mif: picorv_bl.bin
	$(BIN2MIF) picorv_bl.bin picorv_bl.mif 4096 32
	$(BIN2MIF) picorv_bl.bin picorv_bl_0.mif 1024 8 0 3
	$(BIN2MIF) picorv_bl.bin picorv_bl_1.mif 1024 8 1 3
	$(BIN2MIF) picorv_bl.bin picorv_bl_2.mif 1024 8 2 3
	$(BIN2MIF) picorv_bl.bin picorv_bl_3.mif 1024 8 3 3

.PHONY: clean
clean:
	rm -f *.elf *.bin *.mif *.map
